import base64
import io
import json
import os
import re
from typing import Any, Dict, Tuple

from flask import Blueprint, jsonify, request
from flask_jwt_extended import get_jwt_identity, jwt_required
from google import genai
from google.genai import errors as genai_errors
from PIL import Image, UnidentifiedImageError

from extensions import db
from models import SkinAnalysisSession, SkinProfile, User, UserImage
from recommendation_engine.recommendation_engine import RecommendationEngine

skin_analysis_bp = Blueprint("skin_analysis", __name__, url_prefix="/api/skin")

# Phone camera photos are commonly 5-15MB, which is unnecessarily heavy for
# both the Gemini request payload and long-term DB storage, and risks hitting
# upstream payload-size limits. Every uploaded image is downscaled/recompressed
# server-side before it's sent to Gemini or stored, regardless of what the
# client sent.
_MAX_IMAGE_DIMENSION = 1600
_IMAGE_JPEG_QUALITY = 85


def _optimize_image(image_bytes: bytes, mimetype: str) -> Tuple[bytes, str]:
    try:
        img = Image.open(io.BytesIO(image_bytes))
        img.load()
    except (UnidentifiedImageError, OSError):
        # Not a format Pillow can decode; pass through untouched and let
        # Gemini/validation downstream reject it with a clear error instead.
        return image_bytes, mimetype

    if img.mode not in ("RGB", "L"):
        img = img.convert("RGB")

    width, height = img.size
    longest_side = max(width, height)
    if longest_side > _MAX_IMAGE_DIMENSION:
        scale = _MAX_IMAGE_DIMENSION / float(longest_side)
        new_size = (max(1, round(width * scale)), max(1, round(height * scale)))
        img = img.resize(new_size, Image.LANCZOS)

    buffer = io.BytesIO()
    img.save(buffer, format="JPEG", quality=_IMAGE_JPEG_QUALITY, optimize=True)
    optimized_bytes = buffer.getvalue()

    # Only use the re-encoded version if it's actually smaller; a tiny image
    # that's already efficiently encoded shouldn't be made bigger by this step.
    if len(optimized_bytes) < len(image_bytes):
        return optimized_bytes, "image/jpeg"
    return image_bytes, mimetype

# Google retired the old models.generate_content models (e.g. gemini-2.0-flash,
# gemini-2.5-flash) in favor of the Interactions API. "gemini-flash-latest" is
# an alias Google keeps pointed at its current flash model, so keeping it in
# the fallback list protects against the *next* retirement too.
_GEMINI_MODEL_CANDIDATES = (
    "gemini-3.6-flash",
    "gemini-flash-latest",
)


def _generate_with_fallback(client, image_bytes, mime_type, prompt):
    image_b64 = base64.b64encode(image_bytes).decode("utf-8")
    last_error = None
    for model_name in _GEMINI_MODEL_CANDIDATES:
        try:
            return client.interactions.create(
                model=model_name,
                input=[
                    {"type": "text", "text": prompt},
                    {"type": "image", "data": image_b64, "mime_type": mime_type},
                ],
            )
        except genai_errors.ClientError as exc:
            last_error = exc
            if getattr(exc, "code", None) == 404:
                continue
            raise
    raise last_error


def _coerce_list(value: Any):
    if value is None:
        return []
    if isinstance(value, list):
        items = value
    elif isinstance(value, tuple):
        items = list(value)
    elif isinstance(value, str):
        items = [part.strip() for part in value.split(',') if part.strip()]
    else:
        items = [value]

    cleaned = []
    for item in items:
        text = str(item).strip()
        if text:
            cleaned.append(text)
    return cleaned


def _pick_value(primary: Any, fallback: Any):
    if primary is None or primary == "" or primary == [] or primary == {}:
        return fallback
    return primary


def _merge_questionnaire_data(analysis: Dict[str, Any], questionnaire: Dict[str, Any]) -> Dict[str, Any]:
    analysis = analysis or {}
    questionnaire = questionnaire or {}
    merged = dict(questionnaire)

    for key in ["skin_type", "sensitivity_level", "image_quality"]:
        merged[key] = _pick_value(analysis.get(key), questionnaire.get(key))

    merged["concerns"] = _pick_value(analysis.get("concerns"), questionnaire.get("concerns"))
    for key, value in analysis.items():
        if key not in merged or merged[key] in (None, "", [], {}):
            merged[key] = value
    return merged


def _extract_json_from_text(raw_text):
    text = (raw_text or "").strip()
    if not text:
        return None

    match = re.search(r"```(?:json)?\s*(\{.*?\}|\[.*?\])\s*```", text, re.DOTALL | re.IGNORECASE)
    if match:
        text = match.group(1)
    elif text.startswith("{") and text.endswith("}"):
        text = text
    elif text.startswith("[") and text.endswith("]"):
        text = text
    else:
        start = text.find("{")
        end = text.rfind("}")
        if start != -1 and end != -1 and end > start:
            text = text[start : end + 1]
        else:
            return None

    try:
        return json.loads(text)
    except (TypeError, ValueError):
        return None


def _default_recommendations():
    return {
        "products": [
            {
                "name": "Gentle Hydrating Cleanser",
                "brand": "SkinIntel",
                "description": "A mild cleanser that supports balanced skin without stripping moisture.",
                "price": "$18.00",
                "benefits": ["Soothing", "Non-stripping", "Daily use"],
            },
            {
                "name": "Niacinamide Serum",
                "brand": "SkinIntel",
                "description": "Helps support an even-looking tone and a healthy skin barrier.",
                "price": "$24.00",
                "benefits": ["Brightening", "Barrier support", "Oil balance"],
            },
        ],
        "ingredients": [
            {
                "name": "Niacinamide",
                "benefits": ["Supports tone balance", "Helps visible pores"],
            },
            {
                "name": "Hyaluronic Acid",
                "benefits": ["Hydration", "Plumps skin"],
            },
        ],
    }


def _normalise_analysis(payload):
    analysis = payload if isinstance(payload, dict) else {}
    concerns = analysis.get("concerns")
    if not isinstance(concerns, list):
        concerns = []

    detected_features = analysis.get("detected_features")
    if not isinstance(detected_features, dict):
        detected_features = {}

    confidence = analysis.get("confidence", 75)
    try:
        confidence = int(confidence)
    except (TypeError, ValueError):
        confidence = 75

    return {
        "skin_type": analysis.get("skin_type") or "Normal",
        "sensitivity_level": analysis.get("sensitivity_level") or "Low",
        "confidence": max(0, min(confidence, 100)),
        "concerns": [str(item) for item in concerns],
        "detected_features": detected_features,
        "analysis_notes": analysis.get("analysis_notes") or "Skin analysis completed successfully.",
        "image_quality": analysis.get("image_quality") or "acceptable",
    }


@skin_analysis_bp.route("/analyze-and-recommend", methods=["POST"])
@jwt_required()
def analyze_and_recommend_image():
    if "image" not in request.files:
        return jsonify(error="No image uploaded."), 400

    uploaded = request.files["image"]
    if uploaded.filename == "":
        return jsonify(error="No image selected."), 400

    image_bytes = uploaded.read()
    if not image_bytes:
        return jsonify(error="Uploaded image is empty."), 400

    image_bytes, image_mimetype = _optimize_image(image_bytes, uploaded.mimetype or "image/jpeg")

    top_n = None
    try:
        top_n_raw = request.form.get("top_n")
        if top_n_raw:
            top_n = max(1, int(top_n_raw))
    except (TypeError, ValueError):
        top_n = None

    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        return jsonify(error="GEMINI_API_KEY is not configured."), 500

    payload = request.get_json(silent=True) or {}
    questionnaire = payload.get("questionnaire") if isinstance(payload.get("questionnaire"), dict) else {}
    identity = get_jwt_identity()
    user = None
    if identity is not None:
        try:
            user = User.query.get(int(identity))
        except (TypeError, ValueError):
            user = None

    try:
        client = genai.Client(api_key=api_key)

        prompt = (
            "You are a skincare analysis assistant. Analyze the provided face selfie and return only valid JSON. "
            "The JSON object must have these exact keys: "
            "skin_type, sensitivity_level, confidence, concerns, detected_features, analysis_notes, image_quality. "
            "Use only values appropriate for a skincare app. "
            "concerns should be a list of strings. "
            "detected_features should be an object with booleans such as acne, dryness, redness, pigmentation, uneven_tone, fine_lines, oiliness, texture, sensitivity, hydration. "
            "image_quality should be 'poor', 'acceptable', or 'good'. "
            "Do not include markdown fences or extra explanation."
        )

        response = _generate_with_fallback(
            client,
            image_bytes,
            image_mimetype,
            prompt,
        )

        raw_text = response.output_text or ""
        parsed = _extract_json_from_text(raw_text)
        if not isinstance(parsed, dict):
            raise ValueError("Gemini returned a non-JSON response.")

        analysis = _normalise_analysis(parsed)
        baseline_profile = {}
        if user is not None:
            latest_profile = (
                SkinProfile.query.filter_by(user_id=user.id)
                .order_by(SkinProfile.created_at.desc(), SkinProfile.id.desc())
                .first()
            )
            if latest_profile is not None:
                baseline_profile = {
                    "skin_type": latest_profile.skin_type,
                    "sensitivity_level": getattr(latest_profile, "sensitivity_level", None),
                    "concerns": latest_profile.skin_concerns or [],
                    "image_quality": latest_profile.source or "acceptable",
                }

        merged = _merge_questionnaire_data(analysis, {**baseline_profile, **questionnaire})
        profile_id = None

        if user is not None:
            latest_profile = (
                SkinProfile.query.filter_by(user_id=user.id)
                .order_by(SkinProfile.created_at.desc(), SkinProfile.id.desc())
                .first()
            )
            if latest_profile is None:
                latest_profile = SkinProfile(
                    user_id=user.id,
                    skin_type=merged.get("skin_type"),
                    skin_concerns=_coerce_list(merged.get("concerns")),
                    allergies=user.allergies,
                    environment=user.environment,
                    goals=user.goals,
                    source="image",
                )
                db.session.add(latest_profile)
                db.session.flush()
            else:
                latest_profile.skin_type = merged.get("skin_type") or latest_profile.skin_type
                latest_profile.skin_concerns = _coerce_list(merged.get("concerns")) or latest_profile.skin_concerns
                latest_profile.environment = user.environment or latest_profile.environment
                latest_profile.goals = user.goals or latest_profile.goals
                latest_profile.source = "image"

            user.skin_type = merged.get("skin_type") or user.skin_type
            user.skin_concerns = _coerce_list(merged.get("concerns")) or user.skin_concerns
            user.environment = user.environment or (latest_profile.environment or "normal")
            user.goals = user.goals or latest_profile.goals

            session = SkinAnalysisSession(
                user_id=user.id,
                profile_id=latest_profile.id,
                source="image",
                skin_type=merged.get("skin_type"),
                sensitivity_level=merged.get("sensitivity_level"),
                confidence=analysis.get("confidence"),
                concerns=_coerce_list(merged.get("concerns")),
                detected_features=analysis.get("detected_features") or {},
                analysis_notes=analysis.get("analysis_notes"),
                image_quality=merged.get("image_quality") or analysis.get("image_quality"),
                raw_response=parsed,
            )
            db.session.add(session)
            db.session.flush()

            image_record = UserImage(
                user_id=user.id,
                session_id=session.id,
                profile_id=latest_profile.id,
                filename=uploaded.filename or "uploaded-image",
                content_type=image_mimetype,
                source="upload",
                image_bytes=image_bytes,
                image_size=len(image_bytes),
            )
            db.session.add(image_record)

            latest_profile.last_analysis_session_id = session.id
            profile_id = latest_profile.id

            db.session.commit()

        recommendations = _default_recommendations()
        if user is not None:
            try:
                engine_result = RecommendationEngine().generate(user.id, top_n=top_n or 5)
                engine_products = engine_result.get("products") or []
                engine_ingredients = engine_result.get("ingredients") or []
                if engine_products or engine_ingredients:
                    recommendations = {
                        "products": engine_products,
                        "ingredients": engine_ingredients,
                    }
            except Exception:
                recommendations = _default_recommendations()

        payload = {
            "profile_id": profile_id,
            "image_quality": merged.get("image_quality") or analysis["image_quality"],
            "skin_analysis": {**analysis, **merged},
            "recommendations": recommendations,
        }
        return jsonify(payload), 200

    except Exception as exc:
        return jsonify(
            error=f"Gemini Vision analysis failed: {exc}",
            profile_id=None,
            image_quality="acceptable",
            skin_analysis={
                "skin_type": "Normal",
                "sensitivity_level": "Low",
                "confidence": 70,
                "concerns": [],
                "detected_features": {},
                "analysis_notes": "Unable to analyze the image automatically right now.",
                "image_quality": "acceptable",
            },
            recommendations=_default_recommendations(),
        ), 500
