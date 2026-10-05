from flask import Blueprint, jsonify, request
from flask_jwt_extended import get_jwt_identity, jwt_required
from sqlalchemy import text

from extensions import db
from models.routine import Routine, RoutineItem
from routine_engine.routine_engine import generate_routine

routine_bp = Blueprint("routine", __name__, url_prefix="/api/routine")


def _get_product(product_id):
    row = db.session.execute(
        text(
            "SELECT product_id, name, brand, category, image_url, usage_time FROM products WHERE product_id = :pid"
        ),
        {"pid": product_id},
    ).mappings().first()
    return dict(row) if row else None


def _serialize_item(item):
    return {
        "routine_item_id": item.routine_item_id,
        "product_id": item.product_id,
        "time_of_day": item.time_of_day,
        "step_order": item.step_order,
        "notes": item.notes,
        "product": _get_product(item.product_id),
    }


def _serialize_routine(routine, include_items=True):
    updated_at = getattr(routine, "updated_at", None)
    data = {
        "routine_id": routine.routine_id,
        "user_id": routine.user_id,
        "name": routine.name,
        "is_active": routine.is_active,
        "created_at": routine.created_at.isoformat() if routine.created_at else None,
        "updated_at": updated_at.isoformat() if updated_at else None,
    }
    if include_items:
        data["items"] = [_serialize_item(item) for item in routine.items]
    return data


def _validate_product(product_id):
    if not isinstance(product_id, int):
        return "product_id must be an integer"
    row = db.session.execute(
        text("SELECT 1 FROM products WHERE product_id = :pid"),
        {"pid": product_id},
    ).first()
    if not row:
        return f"Product {product_id} not found"
    return None


def _validate_item(item_data):
    if "product_id" not in item_data:
        return "product_id is required for new items"
    err = _validate_product(item_data["product_id"])
    if err:
        return err
    if "time_of_day" in item_data and item_data["time_of_day"] not in ("AM", "PM"):
        return "time_of_day must be AM or PM"
    if "step_order" in item_data:
        if not isinstance(item_data["step_order"], int) or item_data["step_order"] < 1:
            return "step_order must be a positive integer"
    return None


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
    routine = db.session.get(Routine, result.get("routine_id"))
    if routine is None:
        return jsonify(message="Routine generation failed"), 500

    Routine.query.filter(Routine.user_id == user_id, Routine.routine_id != routine.routine_id).update(
        {"is_active": False}, synchronize_session=False
    )
    routine.is_active = True
    db.session.commit()

    return jsonify(
        {
            "routine_id": routine.routine_id,
            "routine": _serialize_routine(routine),
            "message": "Routine generated successfully",
        }
    ), 201


@routine_bp.route("/active", methods=["GET"])
@jwt_required()
def get_active_routine():
    user_id = int(get_jwt_identity())
    routine = Routine.query.filter_by(user_id=user_id, is_active=True).order_by(Routine.created_at.desc()).first()
    if not routine:
        return jsonify({"message": "No active routine found"}), 404
    return jsonify(_serialize_routine(routine)), 200


@routine_bp.route("/<int:routine_id>", methods=["GET"])
@jwt_required()
def get_routine_by_id(routine_id: int):
    user_id = int(get_jwt_identity())
    routine = db.session.get(Routine, routine_id)
    if not routine:
        return jsonify({"message": "Routine not found"}), 404
    if routine.user_id != user_id:
        return jsonify({"message": "Forbidden"}), 403
    return jsonify(_serialize_routine(routine)), 200


@routine_bp.route("/<int:routine_id>", methods=["PATCH"])
@jwt_required()
def patch_routine(routine_id: int):
    user_id = int(get_jwt_identity())
    routine = db.session.get(Routine, routine_id)
    if not routine:
        return jsonify({"message": "Routine not found"}), 404
    if routine.user_id != user_id:
        return jsonify({"message": "Forbidden"}), 403

    data = request.get_json(silent=True) or {}
    try:
        if "name" in data:
            name = data["name"]
            if not isinstance(name, str) or not name.strip():
                return jsonify({"message": "name must be a non-empty string"}), 400
            routine.name = name.strip()

        if "is_active" in data:
            new_active = bool(data["is_active"])
            if new_active:
                Routine.query.filter(Routine.user_id == user_id, Routine.routine_id != routine_id).update(
                    {"is_active": False}, synchronize_session=False
                )
            routine.is_active = new_active

        if "remove_item_ids" in data:
            ids = data["remove_item_ids"]
            if not isinstance(ids, list):
                return jsonify({"message": "remove_item_ids must be a list"}), 400
            RoutineItem.query.filter(
                RoutineItem.routine_id == routine_id,
                RoutineItem.routine_item_id.in_(ids),
            ).delete(synchronize_session=False)

        if data.get("replace_items") is True:
            RoutineItem.query.filter_by(routine_id=routine_id).delete(synchronize_session=False)
            for idx, item_data in enumerate(data.get("items", []), start=1):
                err = _validate_item(item_data)
                if err:
                    return jsonify({"message": err}), 400
                db.session.add(
                    RoutineItem(
                        routine_id=routine_id,
                        product_id=item_data["product_id"],
                        time_of_day=item_data.get("time_of_day", "AM"),
                        step_order=item_data.get("step_order", idx),
                        notes=item_data.get("notes", ""),
                    )
                )
        elif "items" in data:
            for item_data in data["items"]:
                if "routine_item_id" in item_data:
                    item = RoutineItem.query.filter_by(
                        routine_item_id=item_data["routine_item_id"],
                        routine_id=routine_id,
                    ).first()
                    if not item:
                        return jsonify({"message": f"Item {item_data['routine_item_id']} not found"}), 404
                    if "product_id" in item_data:
                        err = _validate_product(item_data["product_id"])
                        if err:
                            return jsonify({"message": err}), 400
                        item.product_id = item_data["product_id"]
                    if "time_of_day" in item_data:
                        if item_data["time_of_day"] not in ("AM", "PM"):
                            return jsonify({"message": "time_of_day must be AM or PM"}), 400
                        item.time_of_day = item_data["time_of_day"]
                    if "step_order" in item_data:
                        if not isinstance(item_data["step_order"], int) or item_data["step_order"] < 1:
                            return jsonify({"message": "step_order must be a positive integer"}), 400
                        item.step_order = item_data["step_order"]
                    if "notes" in item_data:
                        item.notes = item_data["notes"]
                elif "product_id" in item_data:
                    err = _validate_item(item_data)
                    if err:
                        return jsonify({"message": err}), 400
                    db.session.add(
                        RoutineItem(
                            routine_id=routine_id,
                            product_id=item_data["product_id"],
                            time_of_day=item_data.get("time_of_day", "AM"),
                            step_order=item_data.get("step_order", 1),
                            notes=item_data.get("notes", ""),
                        )
                    )
                else:
                    return jsonify({"message": "Each item must have routine_item_id or product_id"}), 400

        db.session.commit()
        return jsonify(_serialize_routine(routine)), 200
    except Exception as exc:
        db.session.rollback()
        return jsonify({"message": "Failed to update routine", "error": str(exc)}), 400
