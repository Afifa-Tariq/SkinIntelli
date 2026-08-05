from flask import Blueprint, jsonify, request
from flask_jwt_extended import get_jwt_identity, jwt_required

from extensions import db
from routine_engine.routine_engine import generate_routine

routine_bp = Blueprint("routine", __name__, url_prefix="/api/routine")


@routine_bp.route("/generate", methods=["POST"])
@jwt_required()
def generate_routine_route():
    identity = get_jwt_identity()
    if identity is None:
        return jsonify(message="UNAUTHORIZED"), 401

    payload = request.get_json(silent=True) or {}
    user_id = int(identity)
    profile_id = int(payload.get("profile_id") or 0)
    recommendations = payload.get("recommendations") or payload.get("products") or []

    if not recommendations:
        return jsonify(message="NO_RECOMMENDATIONS"), 400

    result = generate_routine(user_id=user_id, profile_id=profile_id, recommendations=recommendations)
    return jsonify(result), 200


@routine_bp.route("/active", methods=["GET"])
@jwt_required()
def get_active_routine():
    return jsonify(message="NOT_IMPLEMENTED"), 501


@routine_bp.route("/<int:routine_id>", methods=["GET"])
@jwt_required()
def get_routine_by_id(routine_id: int):
    return jsonify(message="NOT_IMPLEMENTED"), 501


@routine_bp.route("/<int:routine_id>", methods=["PATCH"])
@jwt_required()
def patch_routine(routine_id: int):
    return jsonify(message="NOT_IMPLEMENTED"), 501
