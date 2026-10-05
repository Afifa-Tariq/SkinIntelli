from datetime import datetime

from extensions import db


class Routine(db.Model):
    __tablename__ = "routines"

    routine_id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    name = db.Column(db.String(120), nullable=False, default="My Routine")
    is_active = db.Column(db.Boolean, default=False, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)

    items = db.relationship(
        "RoutineItem",
        backref="routine",
        cascade="all, delete-orphan",
        order_by="RoutineItem.time_of_day, RoutineItem.step_order",
    )


class RoutineItem(db.Model):
    __tablename__ = "routine_items"

    routine_item_id = db.Column("item_id", db.Integer, primary_key=True)
    routine_id = db.Column(db.Integer, db.ForeignKey("routines.routine_id"), nullable=False)
    product_id = db.Column(db.Integer, nullable=False)
    time_of_day = db.Column(db.String(2), nullable=False)
    step_order = db.Column(db.Integer, nullable=False)
    notes = db.Column(db.Text, nullable=True)
