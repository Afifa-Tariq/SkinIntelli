from flask import Blueprint, jsonify, request
from flask_jwt_extended import get_jwt_identity, jwt_required
from sqlalchemy import text

from extensions import db
from recommendation_engine.recommendation_engine import RecommendationEngine

recommendation_bp = Blueprint("recommendation", __name__, url_prefix="/api/recommendations")


@recommendation_bp.route("/generate", methods=["POST"])
@jwt_required()
def generate_recommendations():
    payload = request.get_json(silent=True) or {}
    identity = get_jwt_identity()
    if identity is None:
        return jsonify(message="UNAUTHORIZED"), 401

    try:
        user_id = int(identity)
    except (TypeError, ValueError):
        return jsonify(message="INVALID_IDENTITY"), 401

    top_n = 5
    try:
        top_n_raw = payload.get("top_n")
        if top_n_raw is not None:
            top_n = max(1, int(top_n_raw))
    except (TypeError, ValueError):
        top_n = 5

    try:
        engine = RecommendationEngine()
        result = engine.generate(user_id, filter=payload.get("filter"), top_n=top_n)
        return jsonify(result), 200
    except ValueError as exc:
        if str(exc) == "NO_SKIN_PROFILE":
            return jsonify(message="NO_SKIN_PROFILE"), 404
        raise


@recommendation_bp.route("/history/<int:user_id>", methods=["GET"])
@jwt_required()
def get_recommendation_history(user_id: int):
    identity = get_jwt_identity()
    if identity is None:
        return jsonify(message="UNAUTHORIZED"), 401

    try:
        if int(identity) != int(user_id):
            return jsonify(message="FORBIDDEN"), 403
    except (TypeError, ValueError):
        return jsonify(message="INVALID_IDENTITY"), 401

    query = text(
        """
        SELECT record_id, generated_at, filter_used, total_products_evaluated
        FROM recommendation_records
        WHERE user_id = :user_id
        ORDER BY generated_at DESC
        """
    )
    rows = db.session.execute(query, {"user_id": user_id}).mappings().all()
    records = []
    for row in rows:
        records.append(
            {
                "record_id": row.get("record_id"),
                "generated_at": row.get("generated_at").isoformat() if row.get("generated_at") else None,
                "filter_used": row.get("filter_used"),
                "total_products_evaluated": row.get("total_products_evaluated"),
            }
        )
    return jsonify(records=records), 200


@recommendation_bp.route("/explain/<int:record_id>/<int:product_id>", methods=["GET"])
@jwt_required()
def explain_recommendation(record_id: int, product_id: int):
    identity = get_jwt_identity()
    if identity is None:
        return jsonify(message="UNAUTHORIZED"), 401

    query = text(
        """
        SELECT
            product_id,
            final_score,
            block_reason,
            boost_summary,
            warning_summary,
            allergy_flags,
            explanation
        FROM recommendation_products
        WHERE record_id = :record_id AND product_id = :product_id
        """
    )
    row = db.session.execute(query, {"record_id": record_id, "product_id": product_id}).mappings().first()
    if not row:
        return jsonify(message="NOT_FOUND"), 404

    return jsonify(
        {
            "product_id": row.get("product_id"),
            "final_score": row.get("final_score"),
            "block_reason": row.get("block_reason"),
            "boost_summary": row.get("boost_summary"),
            "warning_summary": row.get("warning_summary"),
            "allergy_flags": row.get("allergy_flags"),
            "explanation": row.get("explanation"),
        }
    ), 200
