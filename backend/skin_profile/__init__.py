from flask import Blueprint, jsonify, request
from flask_jwt_extended import get_jwt_identity, jwt_required
from werkzeug.exceptions import BadRequest

from extensions import db
from models import SkinProfile, User
from skin_profile.recommendations import generate_recommendations

skin_profile_bp = Blueprint("skin_profile", __name__, url_prefix="/api/skin-profile")


def _get_current_user():
    identity = get_jwt_identity()
    if identity is None:
        return None

    try:
        user_id = int(identity)
    except (TypeError, ValueError):
        return None

    return User.query.get(user_id)


@skin_profile_bp.route("", methods=["POST"])
@jwt_required()
def submit_skin_profile():
    payload = request.get_json(silent=True)
    if not payload:
        raise BadRequest("Request body must be JSON")

    skin_type = payload.get("skin_type")
    skin_concerns = payload.get("skin_concerns")
    allergies = payload.get("allergies")
    environment = payload.get("environment")
    goals = payload.get("goals")

    if not skin_type or not environment:
        return jsonify(message="MISSING_FIELDS"), 422

    if skin_concerns is None:
        skin_concerns = []
    if not isinstance(skin_concerns, list):
        return jsonify(message="INVALID_SKIN_CONCERNS"), 422

    if goals is not None and not isinstance(goals, list):
        return jsonify(message="INVALID_GOALS"), 422

    user = _get_current_user()
    if not user:
        return jsonify(message="USER_NOT_FOUND"), 404

    profile = SkinProfile(
        user_id=user.id,
        skin_type=skin_type,
        skin_concerns=skin_concerns,
        allergies=allergies,
        environment=environment,
        goals=goals,
    )

    user.skin_type = skin_type
    user.skin_concerns = skin_concerns
    user.allergies = allergies
    user.environment = environment
    user.goals = goals

    db.session.add(profile)
    db.session.add(user)
    db.session.commit()

    recommendations = generate_recommendations(profile)
    return jsonify(skin_profile=profile.to_dict(), recommendations=recommendations), 201


@skin_profile_bp.route("", methods=["GET"])
@jwt_required()
def get_latest_skin_profile():
    user = _get_current_user()
    if not user:
        return jsonify(message="USER_NOT_FOUND"), 404

    profile = (
        SkinProfile.query
        .filter_by(user_id=user.id)
        .order_by(SkinProfile.created_at.desc())
        .first()
    )

    if not profile:
        return jsonify(message="NO_PROFILE"), 404

    recommendations = generate_recommendations(profile)
    return jsonify(skin_profile=profile.to_dict(), recommendations=recommendations), 200


@skin_profile_bp.route("/history", methods=["GET"])
@jwt_required()
def get_skin_profile_history():
    user = _get_current_user()
    if not user:
        return jsonify(message="USER_NOT_FOUND"), 404

    profiles = (
        SkinProfile.query
        .filter_by(user_id=user.id)
        .order_by(SkinProfile.created_at.desc())
        .all()
    )

    return jsonify(profiles=[profile.to_dict() for profile in profiles]), 200
