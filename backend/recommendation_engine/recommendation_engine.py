import json
from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional

from sqlalchemy import text

from extensions import db



@dataclass
class UserProfile:
    profile_id: Optional[int]
    user_id: Optional[int]
    skin_type: Optional[str] = None
    concerns: List[str] = field(default_factory=list)
    age: Optional[int] = None
    sensitivity_level: Optional[str] = None
    allergy_ingredient_ids: List[int] = field(default_factory=list)


class RecommendationEngine:
    def __init__(self) -> None:
        self._evidence_weights = {
            "strong": 1.0,
            "moderate": 0.7,
            "anecdotal": 0.4,
        }

    def load_user_profile(self, user_id: int) -> Optional[UserProfile]:
        profile_query = text(
            """
            SELECT
                id,
                user_id,
                skin_type,
                skin_concerns,
                allergies,
                environment,
                goals,
                created_at
            FROM skin_profiles
            WHERE user_id = :user_id
            ORDER BY created_at DESC, id DESC
            LIMIT 1
            """
        )
        profile_row = db.session.execute(profile_query, {"user_id": user_id}).mappings().first()
        if not profile_row:
            return None

        concerns = self._parse_json_array(profile_row.get("skin_concerns"))
        allergy_terms = self._parse_allergy_terms(profile_row.get("allergies"))
        allergy_ids = self._resolve_allergy_ids(allergy_terms)

        return UserProfile(
            profile_id=int(profile_row.get("id")),
            user_id=int(profile_row.get("user_id")),
            skin_type=profile_row.get("skin_type"),
            concerns=concerns,
            age=None,
            sensitivity_level=None,
            allergy_ingredient_ids=allergy_ids,
        )

    def _parse_json_array(self, value: Any) -> List[str]:
        if isinstance(value, list):
            return [str(item) for item in value if item is not None]
        if isinstance(value, str):
            try:
                parsed = json.loads(value)
                if isinstance(parsed, list):
                    return [str(item) for item in parsed if item is not None]
            except Exception:
                pass
        return []

    def _parse_allergy_terms(self, value: Any) -> List[str]:
        if not value:
            return []
        if isinstance(value, list):
            values = value
        else:
            values = str(value).replace(";", ",").split(",")
        normalized = []
        for item in values:
            cleaned = str(item).strip()
            if cleaned:
                normalized.append(cleaned.lower())
        return normalized

    def _resolve_allergy_ids(self, allergy_terms: List[str]) -> List[int]:
        if not allergy_terms:
            return []
        ingredient_query = text(
            """
            SELECT ingredient_id, inci_name, common_name
            FROM ingredients
            """
        )
        ingredient_rows = db.session.execute(ingredient_query).mappings().all()
        matched_ids = []
        seen = set()
        for term in allergy_terms:
            for row in ingredient_rows:
                names = [row.get("inci_name"), row.get("common_name")]
                if any(name and _normalize_value(name) == term for name in names):
                    ingredient_id = int(row.get("ingredient_id"))
                    if ingredient_id not in seen:
                        matched_ids.append(ingredient_id)
                        seen.add(ingredient_id)
                    break
        return matched_ids

    def load_candidate_products(self, filter: Optional[Dict[str, Any]] = None) -> List[Dict[str, Any]]:
        conditions: List[str] = []
        params: Dict[str, Any] = {}

        if filter:
            category = filter.get("category")
            if category:
                conditions.append("p.category = :category")
                params["category"] = category

            product_ids = filter.get("product_ids") or filter.get("product_id")
            if isinstance(product_ids, int):
                product_ids = [product_ids]
            if isinstance(product_ids, list) and product_ids:
                placeholders = ", ".join([f":product_id_{index}" for index in range(len(product_ids))])
                conditions.append(f"p.product_id IN ({placeholders})")
                for index, product_id in enumerate(product_ids):
                    params[f"product_id_{index}"] = product_id

        where_clause = f" WHERE {' AND '.join(conditions)}" if conditions else ""

        query = text(
            f"""
            SELECT
                p.product_id,
                p.name,
                p.base_score,
                p.category,
                pi.ingredient_id,
                pi.concentration,
                ing.inci_name AS ingredient_inci_name,
                ing.common_name AS ingredient_common_name,
                ir.rule_id,
                ir.rule_name,
                ir.condition_type,
                ir.condition_value,
                ir.effect,
                ir.effect_magnitude,
                ir.priority,
                ir.evidence_level,
                ir.explanation_template
            FROM products p
            LEFT JOIN product_ingredients pi ON pi.product_id = p.product_id
            LEFT JOIN ingredient_rules ir ON ir.ingredient_id = pi.ingredient_id
            LEFT JOIN ingredients ing ON ing.ingredient_id = pi.ingredient_id
            {where_clause}
            ORDER BY p.product_id, pi.ingredient_id, ir.priority, ir.rule_id
            """
        )
        rows = db.session.execute(query, params).mappings().all()

        product_map: Dict[int, Dict[str, Any]] = {}
        for row in rows:
            product_id = row.get("product_id")
            if product_id is None:
                continue
            if product_id not in product_map:
                product_map[product_id] = {
                    "product_id": product_id,
                    "name": row.get("name"),
                    "base_score": float(row.get("base_score") or 0.0),
                    "category": row.get("category"),
                    "ingredient_ids": [],
                    "ingredients": [],
                    "rules": [],
                }

            product_entry = product_map[product_id]
            ingredient_id = row.get("ingredient_id")
            if ingredient_id is not None and ingredient_id not in product_entry["ingredient_ids"]:
                product_entry["ingredient_ids"].append(int(ingredient_id))
                product_entry["ingredients"].append(
                    {
                        "ingredient_id": int(ingredient_id),
                        "concentration": row.get("concentration"),
                        "inci_name": row.get("ingredient_inci_name"),
                        "common_name": row.get("ingredient_common_name"),
                    }
                )

            rule_id = row.get("rule_id")
            if rule_id is not None:
                if not any(existing.get("rule_id") == rule_id for existing in product_entry["rules"]):
                    product_entry["rules"].append(
                        {
                            "rule_id": int(rule_id),
                            "rule_name": row.get("rule_name"),
                            "condition_type": row.get("condition_type"),
                            "condition_value": row.get("condition_value"),
                            "effect": row.get("effect"),
                            "effect_magnitude": float(row.get("effect_magnitude") or 0.0),
                            "priority": row.get("priority"),
                            "evidence_level": row.get("evidence_level"),
                            "explanation_template": row.get("explanation_template"),
                            "ingredient_id": row.get("ingredient_id"),
                        }
                    )

        return list(product_map.values())

    def load_conflicts(self, candidates: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        ingredient_ids = sorted({ingredient_id for candidate in candidates for ingredient_id in candidate.get("ingredient_ids", [])})
        if not ingredient_ids:
            return []

        placeholders = ", ".join([f":ingredient_{index}" for index in range(len(ingredient_ids))])
        query = text(
            f"""
            SELECT
                conflict_id,
                ingredient_a_id,
                ingredient_b_id,
                severity,
                explanation
            FROM ingredient_conflicts
            WHERE ingredient_a_id IN ({placeholders}) AND ingredient_b_id IN ({placeholders})
            """
        )
        params = {f"ingredient_{index}": ingredient_id for index, ingredient_id in enumerate(ingredient_ids)}
        rows = db.session.execute(query, params).mappings().all()
        return [
            {
                "conflict_id": row.get("conflict_id"),
                "ingredient_a_id": row.get("ingredient_a_id"),
                "ingredient_b_id": row.get("ingredient_b_id"),
                "severity": row.get("severity"),
                "explanation": row.get("explanation"),
            }
            for row in rows
        ]

    def evaluate_rules(self, candidate: Dict[str, Any], profile: Optional[UserProfile]) -> Dict[str, Any]:
        boosts: List[Dict[str, Any]] = []
        warns: List[Dict[str, Any]] = []
        block_reason: Optional[str] = None

        if not profile:
            return {"boosts": boosts, "warns": warns, "is_blocked": False, "block_reason": None}

        for rule in candidate.get("rules", []):
            if not rule:
                continue
            if condition_matches(rule, profile):
                effect = str(rule.get("effect") or "").upper()
                if effect == "BLOCK":
                    block_reason = rule.get("rule_name") or "Rule matched"
                    return {"boosts": boosts, "warns": warns, "is_blocked": True, "block_reason": block_reason}
                if effect == "BOOST":
                    boosts.append(rule)
                elif effect == "WARN":
                    warns.append(rule)

        return {"boosts": boosts, "warns": warns, "is_blocked": False, "block_reason": None}

    def detect_conflicts(self, candidate: Dict[str, Any], conflicts: Optional[List[Dict[str, Any]]] = None) -> Dict[str, Any]:
        ingredient_ids = set(candidate.get("ingredient_ids", []))
        if not ingredient_ids or not conflicts:
            return {"conflicts": [], "is_blocked": False, "block_reason": None}

        matching_conflicts: List[Dict[str, Any]] = []
        for conflict in conflicts:
            if conflict.get("ingredient_a_id") in ingredient_ids and conflict.get("ingredient_b_id") in ingredient_ids:
                matching_conflicts.append(conflict)

        for conflict in matching_conflicts:
            if str(conflict.get("severity") or "").lower() == "hard_block":
                return {
                    "conflicts": matching_conflicts,
                    "is_blocked": True,
                    "block_reason": conflict.get("explanation") or "Ingredient conflict detected",
                }

        return {"conflicts": matching_conflicts, "is_blocked": False, "block_reason": None}

    def _build_ingredient_list(self, products: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        seen = set()
        ingredients: List[Dict[str, Any]] = []
        for product in products:
            boost_rules = [
                rule
                for rule in product.get("boosts", [])
                if str(rule.get("effect") or "").upper() == "BOOST"
            ]
            for ingredient in product.get("ingredients", []):
                ingredient_id = ingredient.get("ingredient_id")
                if ingredient_id is None:
                    continue
                try:
                    ingredient_id = int(ingredient_id)
                except (TypeError, ValueError):
                    continue

                inci_name = str(ingredient.get("inci_name") or "").strip()
                common_name = str(ingredient.get("common_name") or "").strip()
                name = inci_name if inci_name else common_name if common_name else f"Ingredient {ingredient_id}"
                benefit = None
                for rule in boost_rules:
                    try:
                        if int(rule.get("ingredient_id") or 0) == ingredient_id:
                            benefit = rule.get("rule_name") or rule.get("explanation_template")
                            if benefit:
                                break
                    except (TypeError, ValueError):
                        continue
                key = (ingredient_id, name)
                if key not in seen:
                    seen.add(key)
                    ingredients.append(
                        {
                            "ingredient_id": ingredient_id,
                            "name": name,
                            "common_name": common_name,
                            "benefit": benefit or "Supports your skin profile.",
                        }
                    )
        return ingredients

    def aggregate_score(self, product: Dict[str, Any], boosts: List[Dict[str, Any]], warns: List[Dict[str, Any]]) -> float:
        base_score = float(product.get("base_score") or 0.0)
        boost_total = sum(float(rule.get("effect_magnitude") or 0.0) for rule in boosts)
        warn_total = sum(
            float(rule.get("effect_magnitude") or 0.0) * self._evidence_weights.get(str(rule.get("evidence_level") or "moderate").lower(), 0.7)
            for rule in warns
        )
        final_score = base_score + boost_total - warn_total
        return max(final_score, 0.0)

    def generate_explanation(
        self,
        product: Dict[str, Any],
        matched_rules: List[Dict[str, Any]],
        conflicts: List[Dict[str, Any]],
    ) -> str:
        segments: List[str] = []
        boost_rules = [rule for rule in matched_rules if str(rule.get("effect") or "").upper() == "BOOST"]
        warn_rules = [rule for rule in matched_rules if str(rule.get("effect") or "").upper() == "WARN"]

        for rule in boost_rules:
            template = rule.get("explanation_template") or f"Boosted because {rule.get('rule_name') or 'a matching rule'} applied."
            segment = self._fill_template(template, {"product": product.get("name"), **rule})
            if segment:
                segments.append(segment)

        for rule in warn_rules:
            template = rule.get("explanation_template") or f"Warning because {rule.get('rule_name') or 'a matching rule'} applied."
            segment = self._fill_template(template, {"product": product.get("name"), **rule})
            if segment:
                segments.append(segment)

        for conflict in conflicts:
            if str(conflict.get("severity") or "").lower() == "hard_block":
                continue
            segment = self._fill_template(
                conflict.get("explanation") or "Potential ingredient interaction detected.",
                {
                    "product": product.get("name"),
                    "ingredient_a_id": conflict.get("ingredient_a_id"),
                    "ingredient_b_id": conflict.get("ingredient_b_id"),
                },
            )
            if segment:
                segments.append(segment)

        if not segments:
            return f"{product.get('name') or 'This product'} was assessed against your profile."
        return " ".join(segments)

    def _fill_template(self, template: Optional[str], values: Dict[str, Any]) -> str:
        if not template:
            return ""
        safe_values = {key: "" if value is None else str(value) for key, value in values.items()}
        try:
            return template.format(**safe_values)
        except Exception:
            return ""

    def generate(self, user_id: int, filter: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        profile = self.load_user_profile(user_id)
        if profile is None:
            raise ValueError("NO_SKIN_PROFILE")

        candidates = self.load_candidate_products(filter)
        conflicts = self.load_conflicts(candidates)

        evaluated_products: List[Dict[str, Any]] = []
        for candidate in candidates:
            rule_result = self.evaluate_rules(candidate, profile)
            if rule_result["is_blocked"]:
                evaluated_products.append(
                    {
                        "product_id": candidate.get("product_id"),
                        "name": candidate.get("name"),
                        "final_score": 0.0,
                        "is_blocked": True,
                        "block_reason": rule_result["block_reason"],
                        "boosts": rule_result["boosts"],
                        "warns": rule_result["warns"],
                        "conflicts": [],
                        "explanation": self.generate_explanation(candidate, rule_result["boosts"] + rule_result["warns"], []),
                        "rank": None,
                        "block_source": "rule",
                    }
                )
                continue

            conflict_result = self.detect_conflicts(candidate, conflicts)
            if conflict_result["is_blocked"]:
                evaluated_products.append(
                    {
                        "product_id": candidate.get("product_id"),
                        "name": candidate.get("name"),
                        "final_score": 0.0,
                        "is_blocked": True,
                        "block_reason": conflict_result["block_reason"],
                        "boosts": rule_result["boosts"],
                        "warns": rule_result["warns"],
                        "conflicts": conflict_result["conflicts"],
                        "explanation": self.generate_explanation(candidate, rule_result["boosts"] + rule_result["warns"], conflict_result["conflicts"]),
                        "rank": None,
                        "block_source": "conflict",
                    }
                )
                continue

            final_score = self.aggregate_score(candidate, rule_result["boosts"], rule_result["warns"])
            explanation = self.generate_explanation(candidate, rule_result["boosts"] + rule_result["warns"], conflict_result["conflicts"])
            evaluated_products.append(
                {
                    "product_id": candidate.get("product_id"),
                    "name": candidate.get("name"),
                    "final_score": final_score,
                    "is_blocked": False,
                    "block_reason": None,
                    "boosts": rule_result["boosts"],
                    "warns": rule_result["warns"],
                    "conflicts": conflict_result["conflicts"],
                    "explanation": explanation,
                    "rank": None,
                    "block_source": None,
                }
            )

        ranked_products = [product for product in evaluated_products if not product["is_blocked"] or product.get("block_source") != "conflict"]
        ranked_products.sort(key=lambda item: item["final_score"], reverse=True)
        for index, product in enumerate(ranked_products, start=1):
            product["rank"] = index

        recommended_products = [
            product for product in ranked_products if not product["is_blocked"]
        ]
        ingredients = self._build_ingredient_list(recommended_products)

        record_id = self._persist_result(user_id, profile.profile_id if profile else None, filter, len(candidates), evaluated_products)
        response_products = [
            {
                "product_id": product["product_id"],
                "name": product["name"],
                "final_score": round(product["final_score"], 2),
                "is_blocked": product["is_blocked"],
                "rank": product["rank"],
                "explanation": product["explanation"],
            }
            for product in evaluated_products
            if not product["is_blocked"] or product.get("block_source") != "conflict"
        ]
        return {
            "record_id": record_id,
            "products": response_products,
            "ingredients": ingredients,
        }

    def _persist_result(
        self,
        user_id: int,
        profile_id: Optional[int],
        filter: Optional[Dict[str, Any]],
        total_products_evaluated: int,
        evaluated_products: List[Dict[str, Any]],
    ) -> int:
        record_query = text(
            """
            INSERT INTO recommendation_records (user_id, profile_id, filter_used, total_products_evaluated)
            VALUES (:user_id, :profile_id, :filter_used, :total_products_evaluated)
            """
        )
        result = db.session.execute(
            record_query,
            {
                "user_id": user_id,
                "profile_id": profile_id,
                "filter_used": json.dumps(filter) if filter else None,
                "total_products_evaluated": total_products_evaluated,
            },
        )
        db.session.commit()

        record_id = getattr(result, "lastrowid", None)
        if not record_id:
            record_id = db.session.execute(text("SELECT LAST_INSERT_ID()")).scalar()

        for product in evaluated_products:
            boost_summary = "; ".join(str(rule.get("rule_name") or "boost") for rule in product.get("boosts", [])) or None
            warning_summary = "; ".join(str(rule.get("rule_name") or "warning") for rule in product.get("warns", [])) or None
            allergy_flags = None
            product_query = text(
                """
                INSERT INTO recommendation_products (
                    record_id,
                    product_id,
                    final_score,
                    is_blocked,
                    block_reason,
                    boost_summary,
                    warning_summary,
                    allergy_flags,
                    explanation,
                    `rank`
                )
                VALUES (
                    :record_id,
                    :product_id,
                    :final_score,
                    :is_blocked,
                    :block_reason,
                    :boost_summary,
                    :warning_summary,
                    :allergy_flags,
                    :explanation,
                    :rank
                )
                """
            )
            db.session.execute(
                product_query,
                {
                    "record_id": record_id,
                    "product_id": product.get("product_id"),
                    "final_score": product.get("final_score"),
                    "is_blocked": bool(product.get("is_blocked")),
                    "block_reason": product.get("block_reason"),
                    "boost_summary": boost_summary,
                    "warning_summary": warning_summary,
                    "allergy_flags": allergy_flags,
                    "explanation": product.get("explanation"),
                    "rank": product.get("rank"),
                },
            )
        db.session.commit()
        return int(record_id)


def condition_matches(rule: Dict[str, Any], profile: UserProfile) -> bool:
    """Match a rule against the compiled user profile using a pure rule evaluation path."""
    condition_type = str(rule.get("condition_type") or "").lower()

    if condition_type == "skin_type":
        """Return True when the rule's target skin type equals the profile skin type, case-insensitive."""
        return _normalize_value(rule.get("condition_value")) == _normalize_value(profile.skin_type)

    if condition_type == "concern":
        """Return True when the rule's concern appears in the profile concerns list, case-insensitive."""
        profile_concerns = {_normalize_value(value) for value in profile.concerns or []}
        return _normalize_value(rule.get("condition_value")) in profile_concerns

    if condition_type == "allergy":
        """Return True when the rule's ingredient_id is present in the profile allergy list."""
        return int(rule.get("ingredient_id")) in set(profile.allergy_ingredient_ids or [])

    if condition_type == "sensitivity":
        """Return True when the profile sensitivity level meets or exceeds the rule threshold."""
        return _compare_sensitivity(profile.sensitivity_level, rule.get("condition_value"))

    if condition_type == "age_range":
        """Return True when the profile age falls within the rule's age range expression."""
        return _compare_age_range(profile.age, rule.get("condition_value"))

    return False


def aggregate_score(product: Dict[str, Any], boosts: List[Dict[str, Any]], warns: List[Dict[str, Any]]) -> float:
    return RecommendationEngine().aggregate_score(product, boosts, warns)


def _normalize_value(value: Any) -> str:
    return str(value or "").strip().lower()


def _compare_sensitivity(profile_level: Optional[str], condition_value: Any) -> bool:
    if not profile_level or not condition_value:
        return False
    level_map = {"low": 1, "medium": 2, "high": 3}
    profile_value = level_map.get(_normalize_value(profile_level), 0)
    rule_value = level_map.get(_normalize_value(condition_value), 0)
    return profile_value >= rule_value


def _compare_age_range(age: Optional[int], condition_value: Any) -> bool:
    if age is None or not condition_value:
        return False

    text = _normalize_value(condition_value)
    if "-" in text:
        try:
            lower, upper = text.split("-", 1)
            lower_age = int(lower.strip())
            upper_age = int(upper.strip())
            return lower_age <= int(age) <= upper_age
        except ValueError:
            return False

    if text.startswith(">="):
        try:
            return int(age) >= int(text[2:].strip())
        except ValueError:
            return False
    if text.startswith(">"):
        try:
            return int(age) > int(text[1:].strip())
        except ValueError:
            return False
    if text.startswith("<="):
        try:
            return int(age) <= int(text[2:].strip())
        except ValueError:
            return False
    if text.startswith("<"):
        try:
            return int(age) < int(text[1:].strip())
        except ValueError:
            return False
    return False
