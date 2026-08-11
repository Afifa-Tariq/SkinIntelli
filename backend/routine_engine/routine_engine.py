from __future__ import annotations

from typing import Any, Dict, Iterable, List, Optional, Sequence, Set, Tuple

from extensions import db
from sqlalchemy import text

PM_ONLY_INGREDIENTS = {
    "Retinol",
    "Glycolic Acid",
    "Lactic Acid",
    "The Ordinary AHA 30% + BHA 2% Peeling Solution",
}

SPF_TRIGGER_INGREDIENTS = {
    "Ascorbic Acid",
    "Glycolic Acid",
    "Lactic Acid",
    "Salicylic Acid",
    "Retinol",
}

PATCH_TEST_INGREDIENTS = {
    "Retinol",
    "Glycolic Acid",
    "Benzoyl Peroxide",
    "Azelaic Acid",
    "Lactic Acid",
    "Salicylic Acid",
}

STEP_ORDER = {
    "cleanser": 1,
    "toner": 2,
    "serum": 3,
    "eye_cream": 4,
    "exfoliant": 3,
    "mask": 3,
    "moisturizer": 6,
    "oil": 7,
    "sunscreen": 8,
}


def _humanize_category(category: Any) -> str:
    text_value = str(category or "").replace("_", " ").strip()
    return text_value.title() if text_value else "Product"


def _get_product(product_id: int) -> Optional[Any]:
    return db.session.execute(text("SELECT * FROM products WHERE product_id = :product_id"), {"product_id": product_id}).mappings().first()


def _get_ingredient_names(product_id: int) -> Set[str]:
    rows = db.session.execute(
        text(
            """
            SELECT pi.product_id, i.inci_name
            FROM product_ingredients pi
            JOIN ingredients i ON i.ingredient_id = pi.ingredient_id
            WHERE pi.product_id = :product_id
            """
        ),
        {"product_id": product_id},
    ).mappings().all()
    return {str(row.get("inci_name") or "") for row in rows}


def _classify_time(product: Any, ing_names: Set[str]) -> List[str]:
    usage_time = str(getattr(product, "usage_time", "") or "").upper()
    category = str(getattr(product, "category", "") or "").lower()

    if usage_time == "AM":
        return ["AM"]
    if usage_time == "PM":
        return ["PM"]

    if ing_names & PM_ONLY_INGREDIENTS:
        return ["PM"]
    if category == "sunscreen":
        return ["AM"]
    if category in {"cleanser", "moisturizer"}:
        return ["AM", "PM"]
    return ["AM", "PM"]


def _build_reminders(ing_names: Set[str], time_of_day: str, is_new_to_routine: bool = True) -> Optional[str]:
    reminders: List[str] = []
    if time_of_day == "AM" and ing_names & SPF_TRIGGER_INGREDIENTS:
        reminders.append("SPF REMINDER: Apply sunscreen as final step.")
    if ing_names & {"Retinol", "Glycolic Acid", "Lactic Acid", "Salicylic Acid"}:
        reminders.append("HYDRATION REMINDER: Follow with moisturizer.")
    if is_new_to_routine and ing_names & PATCH_TEST_INGREDIENTS:
        reminders.append("PATCH TEST: Test on small area for 24h before full use.")
    return " | ".join(reminders) if reminders else None


def generate_routine(user_id: int, profile_id: int, recommendations: Sequence[Dict[str, Any]]) -> Dict[str, Any]:
    products = []
    for item in recommendations:
        if item.get("is_blocked"):
            continue
        product_id = item.get("product_id")
        product_row = _get_product(int(product_id))
        if product_row is None:
            continue
        products.append((product_row, _get_ingredient_names(int(product_id))))

    am_slots: List[Tuple[Any, Set[str]]] = []
    pm_slots: List[Tuple[Any, Set[str]]] = []
    for product, ing_names in products:
        times = _classify_time(product, ing_names)
        if "AM" in times:
            am_slots.append((product, ing_names))
        if "PM" in times:
            pm_slots.append((product, ing_names))

    am_slots.sort(key=lambda x: STEP_ORDER.get(str(getattr(x[0], "category", "") or "").lower(), 5))
    pm_slots.sort(key=lambda x: STEP_ORDER.get(str(getattr(x[0], "category", "") or "").lower(), 5))

    routine_query = text(
        """
        INSERT INTO routines (user_id, name, is_active)
        VALUES (:user_id, :name, :is_active)
        """
    )
    routine_result = db.session.execute(routine_query, {"user_id": user_id, "name": "My Personalized Routine", "is_active": True})
    db.session.commit()
    routine_id = getattr(routine_result, "lastrowid", None) or db.session.execute(text("SELECT LAST_INSERT_ID()")).scalar()

    routine_items_data: List[Dict[str, Any]] = []
    for step, (product, ing_names) in enumerate(am_slots, start=1):
        step_order = step
        note = _build_reminders(ing_names, "AM")
        db.session.execute(
            text(
                """
                INSERT INTO routine_items (routine_id, product_id, time_of_day, step_order, notes)
                VALUES (:routine_id, :product_id, :time_of_day, :step_order, :notes)
                """
            ),
            {
                "routine_id": routine_id,
                "product_id": int(product.get("product_id") if isinstance(product, dict) else product["product_id"]),
                "time_of_day": "AM",
                "step_order": step_order,
                "notes": note,
            },
        )
        routine_items_data.append(
            {
                "step": step_order,
                "time": "AM",
                "product": product.get("name") if isinstance(product, dict) else product["name"],
                "category": _humanize_category(product.get("category") if isinstance(product, dict) else product["category"]),
                "reminder": note,
            }
        )

    for step, (product, ing_names) in enumerate(pm_slots, start=1):
        step_order = step
        note = _build_reminders(ing_names, "PM")
        db.session.execute(
            text(
                """
                INSERT INTO routine_items (routine_id, product_id, time_of_day, step_order, notes)
                VALUES (:routine_id, :product_id, :time_of_day, :step_order, :notes)
                """
            ),
            {
                "routine_id": routine_id,
                "product_id": int(product.get("product_id") if isinstance(product, dict) else product["product_id"]),
                "time_of_day": "PM",
                "step_order": step_order,
                "notes": note,
            },
        )
        routine_items_data.append(
            {
                "step": step_order,
                "time": "PM",
                "product": product.get("name") if isinstance(product, dict) else product["name"],
                "category": _humanize_category(product.get("category") if isinstance(product, dict) else product["category"]),
                "reminder": note,
            }
        )

    db.session.commit()

    reminders = [item["reminder"] for item in routine_items_data if item.get("reminder")]
    return {
        "routine_id": int(routine_id),
        "routine_name": "My Personalized Routine",
        "morning_steps": [item for item in routine_items_data if item["time"] == "AM"],
        "night_steps": [item for item in routine_items_data if item["time"] == "PM"],
        "reminders": list(dict.fromkeys(reminders)),
    }
