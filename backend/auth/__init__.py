from datetime import datetime, timedelta

from flask import Blueprint, jsonify, request
from flask_jwt_extended import (create_access_token, create_refresh_token,
                                decode_token, get_jwt, get_jwt_identity,
                                jwt_required)
from werkzeug.exceptions import BadRequest

from extensions import db, limiter
from models import TokenBlocklist, User
from auth.utils import send_otp_email

auth_bp = Blueprint("auth", __name__, url_prefix="/api/auth")


@auth_bp.route("/register", methods=["POST"])
def register():
    payload = request.get_json(silent=True)
    if not payload:
        raise BadRequest("Request body must be JSON")

    full_name = payload.get("full_name")
    email = payload.get("email")
    password = payload.get("password")

    if not full_name or not email or not password:
        return jsonify(message="MISSING_FIELDS"), 422

    if User.query.filter_by(email=email).first():
        return jsonify(message="EMAIL_EXISTS"), 409

    user = User(full_name=full_name, email=email, is_verified=True)
    user.set_password(password)

    db.session.add(user)
    db.session.commit()

    access_token = create_access_token(identity=str(user.id))
    refresh_token = create_refresh_token(identity=str(user.id))

    return jsonify(
        access_token=access_token,
        refresh_token=refresh_token,
        user=user.to_dict(),
    ), 201


@auth_bp.route("/verify-email", methods=["POST"])
def verify_email():
    payload = request.get_json(silent=True)
    if not payload:
        raise BadRequest("Request body must be JSON")

    email = payload.get("email")
    otp = payload.get("otp")

    if not email or not otp:
        return jsonify(message="MISSING_FIELDS"), 422

    user = User.query.filter_by(email=email).first()
    if not user:
        return jsonify(message="USER_NOT_FOUND"), 404

    if not user.otp_code or not user.otp_expires_at:
        return jsonify(message="OTP_INVALID"), 422

    if user.otp_expires_at < datetime.utcnow():
        return jsonify(message="OTP_EXPIRED"), 410

    if not user.verify_otp(otp):
        return jsonify(message="OTP_INVALID"), 422

    user.is_verified = True
    user.otp_code = None
    user.otp_expires_at = None
    db.session.commit()

    access_token = create_access_token(identity=str(user.id))
    refresh_token = create_refresh_token(identity=str(user.id))

    return jsonify(
        access_token=access_token,
        refresh_token=refresh_token,
        user=user.to_dict(),
    ), 200


@auth_bp.route("/resend-otp", methods=["POST"])
def resend_otp():
    payload = request.get_json(silent=True)
    if not payload:
        raise BadRequest("Request body must be JSON")

    email = payload.get("email")
    if not email:
        return jsonify(message="MISSING_FIELDS"), 422

    user = User.query.filter_by(email=email).first()
    if not user:
        return jsonify(message="USER_NOT_FOUND"), 404

    otp_code = user.set_otp()
    db.session.commit()

    if not send_otp_email(user.email, otp_code, purpose="verify"):
        return jsonify(message="Could not send verification email. Check your mail server configuration."), 500

    return jsonify(message="OTP resent."), 200


@auth_bp.route("/forgot-password", methods=["POST"])
@limiter.limit("5/minute")
def forgot_password():
    payload = request.get_json(silent=True)
    if not payload:
        raise BadRequest("Request body must be JSON")

    email = payload.get("email")
    if not email:
        return jsonify(message="MISSING_FIELDS"), 422

    user = User.query.filter_by(email=email).first()
    if user:
        otp_code = user.set_otp()
        db.session.commit()
        send_otp_email(user.email, otp_code, purpose="reset")

    return jsonify(message="If that email exists, a reset code was sent."), 200


@auth_bp.route("/verify-reset-otp", methods=["POST"])
def verify_reset_otp():
    payload = request.get_json(silent=True)
    if not payload:
        raise BadRequest("Request body must be JSON")

    email = payload.get("email")
    otp = payload.get("otp")

    if not email or not otp:
        return jsonify(message="MISSING_FIELDS"), 422

    user = User.query.filter_by(email=email).first()
    if not user or not user.otp_code or not user.otp_expires_at:
        return jsonify(message="OTP_INVALID"), 422

    if user.otp_expires_at < datetime.utcnow():
        return jsonify(message="OTP_EXPIRED"), 410

    if not user.verify_otp(otp):
        return jsonify(message="OTP_INVALID"), 422

    user.otp_code = None
    user.otp_expires_at = None
    db.session.commit()

    reset_token = create_access_token(
        identity=str(user.id),
        additional_claims={"type": "reset"},
        expires_delta=timedelta(minutes=15),
    )

    return jsonify(reset_token=reset_token), 200


@auth_bp.route("/reset-password", methods=["POST"])
def reset_password():
    payload = request.get_json(silent=True)
    if not payload:
        raise BadRequest("Request body must be JSON")

    reset_token = payload.get("reset_token")
    new_password = payload.get("new_password")

    if not reset_token or not new_password:
        return jsonify(message="MISSING_FIELDS"), 422

    try:
        decoded = decode_token(reset_token)
    except Exception:
        return jsonify(message="INVALID_RESET_TOKEN"), 401

    if decoded.get("type") != "reset":
        return jsonify(message="INVALID_RESET_TOKEN"), 401

    jti = decoded.get("jti")
    if TokenBlocklist.query.filter_by(jti=jti).first():
        return jsonify(message="INVALID_RESET_TOKEN"), 401

    user_id = decoded.get("sub")
    try:
        user_id = int(user_id)
    except (TypeError, ValueError):
        return jsonify(message="INVALID_RESET_TOKEN"), 401

    user = User.query.get(user_id)
    if not user:
        return jsonify(message="USER_NOT_FOUND"), 404

    user.set_password(new_password)
    user.otp_code = None
    user.otp_expires_at = None
    db.session.add(user)
    db.session.commit()

    db.session.add(TokenBlocklist(jti=jti))
    db.session.commit()

    return jsonify(message="Password reset successfully."), 200


@auth_bp.route("/login", methods=["POST"])
@limiter.limit("10/minute")
def login():
    payload = request.get_json(silent=True)
    if not payload:
        raise BadRequest("Request body must be JSON")

    email = payload.get("email")
    password = payload.get("password")

    if not email or not password:
        return jsonify(message="MISSING_FIELDS"), 422

    user = User.query.filter_by(email=email).first()
    if not user:
        return jsonify(message="USER_NOT_FOUND"), 404

    if not user.check_password(password):
        return jsonify(message="INVALID_CREDENTIALS"), 401

    if not user.is_verified:
        return jsonify(message="EMAIL_NOT_VERIFIED"), 401

    access_token = create_access_token(identity=str(user.id))
    refresh_token = create_refresh_token(identity=str(user.id))

    return jsonify(
        access_token=access_token,
        refresh_token=refresh_token,
        user=user.to_dict(),
    ), 200


@auth_bp.route("/refresh", methods=["POST"])
@jwt_required(refresh=True)
def refresh():
    identity = get_jwt_identity()
    access_token = create_access_token(identity=identity)
    return jsonify(access_token=access_token), 200


@auth_bp.route("/logout", methods=["POST"])
@jwt_required()
def logout():
    jti = get_jwt().get("jti")
    block = TokenBlocklist(jti=jti)
    db.session.add(block)
    db.session.commit()
    return jsonify(message="Logged out."), 200
