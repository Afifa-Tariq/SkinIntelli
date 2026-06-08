from flask import Blueprint, jsonify, request
from flask_jwt_extended import get_jwt_identity, jwt_required
from werkzeug.exceptions import BadRequest

from extensions import db
from models import User

user_bp = Blueprint("user", __name__, url_prefix="/api/user")


def _get_current_user():
    identity = get_jwt_identity()
    if identity is None:
        return None

    try:
        user_id = int(identity)
    except (TypeError, ValueError):
        return None

    return User.query.get(user_id)


@user_bp.route("/profile", methods=["GET"])
@jwt_required()
def get_profile():
    user = _get_current_user()
    if not user:
        return jsonify(message="USER_NOT_FOUND"), 404
    return jsonify(user.to_dict()), 200


@user_bp.route("/profile", methods=["PUT"])
@jwt_required()
def update_profile():
    payload = request.get_json(silent=True)
    if not payload:
        raise BadRequest("Request body must be JSON")

    user = _get_current_user()
    if not user:
        return jsonify(message="USER_NOT_FOUND"), 404

    full_name = payload.get("full_name")
    username = payload.get("username")
    gender = payload.get("gender")

    if username is not None:
        existing = User.query.filter(User.username == username, User.id != user.id).first()
        if existing:
            return jsonify(message="USERNAME_EXISTS"), 409
        user.username = username

    if full_name is not None:
        user.full_name = full_name

    if gender is not None:
        user.gender = gender

    db.session.commit()
    return jsonify(user.to_dict()), 200


@user_bp.route("/questionnaire", methods=["PUT"])
@jwt_required()
def update_questionnaire():
    payload = request.get_json(silent=True)
    if not payload:
        raise BadRequest("Request body must be JSON")

    user = _get_current_user()
    if not user:
        return jsonify(message="USER_NOT_FOUND"), 404

    skin_type = payload.get("skin_type")
    skin_concerns = payload.get("skin_concerns")
    allergies = payload.get("allergies")
    environment = payload.get("environment")
    goals = payload.get("goals")

    if skin_type is not None:
        user.skin_type = skin_type

    if skin_concerns is not None:
        if not isinstance(skin_concerns, list):
            return jsonify(message="INVALID_SKIN_CONCERNS"), 422
        user.skin_concerns = skin_concerns

    if allergies is not None:
        user.allergies = allergies

    if environment is not None:
        user.environment = environment

    if goals is not None:
        if not isinstance(goals, list):
            return jsonify(message="INVALID_GOALS"), 422
        user.goals = goals

    db.session.commit()
    return jsonify(user.to_dict()), 200
