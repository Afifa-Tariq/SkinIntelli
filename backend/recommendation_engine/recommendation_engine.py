import json
from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional

from sqlalchemy import text

from extensions import db
from recommendation_engine.explanation_engine import build_explanation



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
                ing.category AS ingredient_category,
                ing.comedogenic_score AS ingredient_comedogenic_score,
                ing.irritancy_score AS ingredient_irritancy_score,
                ing.base_safety_score AS ingredient_base_safety_score,
                ing.cir_approved AS ingredient_cir_approved,
                ir.rule_id,
                ir.rule_name,
                ir.condition_type,
                ir.condition_value,
                ir.effect,
                ir.effect_magnitude,
                ir.priority,
                ir.evidence_level,
                ir.clinical_source,
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
                        "category": row.get("ingredient_category"),
                        "comedogenic_score": row.get("ingredient_comedogenic_score"),
                        "irritancy_score": row.get("ingredient_irritancy_score"),
                        "base_safety_score": row.get("ingredient_base_safety_score"),
                        "cir_approved": row.get("ingredient_cir_approved"),
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
                            "clinical_source": row.get("clinical_source"),
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

    def _build_ingredient_list(
        self, products: List[Dict[str, Any]], limit: Optional[int] = None
    ) -> List[Dict[str, Any]]:
        seen = set()
        # Tier 0: ingredients boosted specifically for one of the user's
        # named concerns (the strongest, most relevant match). Tier 1:
        # boosted only via a skin-type match. Tier 2: no matched rule at
        # all, described from its general known functions instead.
        tiers: List[List[Dict[str, Any]]] = [[], [], []]

        ingredient_ids = sorted(
            {
                int(ingredient["ingredient_id"])
                for product in products
                for ingredient in product.get("ingredients", [])
                if ingredient.get("ingredient_id") is not None
            }
        )
        functions_map = self._load_ingredient_functions_map(ingredient_ids)

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
                key = (ingredient_id, name)
                if key in seen:
                    continue

                matched_rules = [
                    rule for rule in boost_rules if int(rule.get("ingredient_id") or 0) == ingredient_id
                ]
                concern_rule = next(
                    (rule for rule in matched_rules if str(rule.get("condition_type") or "").lower() == "concern"),
                    None,
                )
                best_rule = concern_rule or (matched_rules[0] if matched_rules else None)
                function_labels = [_humanize_function(fn) for fn in functions_map.get(ingredient_id, [])]

                if best_rule:
                    benefit = str(
                        best_rule.get("explanation_template") or best_rule.get("rule_name") or ""
                    ).strip() or "Supports your skin's needs."
                    evidence_level = str(best_rule.get("evidence_level") or "moderate").lower()
                    source = _format_source(best_rule.get("clinical_source"))
                    if concern_rule:
                        why_recommended = f"Targets your {concern_rule.get('condition_value')} concern"
                        tier = 0
                    else:
                        why_recommended = f"Well-suited to {best_rule.get('condition_value')} skin"
                        tier = 1
                else:
                    benefit = (
                        f"Known for {function_labels[0].lower()} benefits."
                        if function_labels
                        else "A supporting ingredient in this product."
                    )
                    why_recommended = "General skincare support"
                    evidence_level = None
                    source = None
                    tier = 2

                seen.add(key)
                tiers[tier].append(
                    {
                        "ingredient_id": ingredient_id,
                        "name": name,
                        "common_name": common_name,
                        "category": _humanize_category(ingredient.get("category")),
                        "functions": function_labels,
                        "benefit": benefit,
                        "why_recommended": why_recommended,
                        "evidence_level": evidence_level,
                        "source": source,
                        "safety_note": _safety_note(ingredient),
                    }
                )

        ordered = tiers[0] + tiers[1] + tiers[2]
        if limit:
            ordered = ordered[:limit]
        return ordered

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
        profile: Optional[UserProfile] = None,
    ) -> Dict[str, Any]:
        profile_payload = {
            "skin_type": profile.skin_type if profile else None,
            "concerns": list(profile.concerns or []) if profile else [],
            "allergen_ingredient_ids": list(profile.allergy_ingredient_ids or []) if profile else [],
        }
        ingredient_functions = self._load_ingredient_functions(product.get("ingredient_ids") or [])
        proof_rows = [
            {
                "ingredient_id": ingredient.get("ingredient_id"),
                "ingredient": {
                    "inci_name": ingredient.get("inci_name"),
                    "cir_approved": bool(ingredient.get("cir_approved")),
                    "irritancy_score": ingredient.get("irritancy_score") if ingredient.get("irritancy_score") is not None else 0,
                    "base_safety_score": ingredient.get("base_safety_score") if ingredient.get("base_safety_score") is not None else 50,
                },
            }
            for ingredient in product.get("ingredients", [])
        ]
        return build_explanation(
            product=product,
            eval_result={"final_score": self.aggregate_score(product, matched_rules, [])},
            fired_rules=matched_rules,
            user_profile=profile_payload,
            pi_rows=proof_rows,
            ingredient_functions=ingredient_functions,
            conflict_rows=conflicts,
        )

    def _fill_template(self, template: Optional[str], values: Dict[str, Any]) -> str:
        if not template:
            return ""
        safe_values = {key: "" if value is None else str(value) for key, value in values.items()}
        try:
            return template.format(**safe_values)
        except Exception:
            return ""

    def generate(
        self,
        user_id: int,
        filter: Optional[Dict[str, Any]] = None,
        top_n: Optional[int] = 5,
    ) -> Dict[str, Any]:
        profile = self.load_user_profile(user_id)
        if profile is None:
            raise ValueError("NO_SKIN_PROFILE")

        candidates = self.load_candidate_products(filter)
        conflicts = self.load_conflicts(candidates)

        evaluated_products: List[Dict[str, Any]] = []
        for candidate in candidates:
            rule_result = self.evaluate_rules(candidate, profile)
            matched_rules = rule_result["boosts"] + rule_result["warns"]
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
                        "ingredients": candidate.get("ingredients", []),
                        "explanation": self.generate_explanation(candidate, matched_rules, [], profile),
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
                        "ingredients": candidate.get("ingredients", []),
                        "explanation": self.generate_explanation(candidate, matched_rules, conflict_result["conflicts"], profile),
                        "rank": None,
                        "block_source": "conflict",
                    }
                )
                continue

            final_score = self.aggregate_score(candidate, rule_result["boosts"], rule_result["warns"])
            explanation = self.generate_explanation(candidate, matched_rules, conflict_result["conflicts"], profile)
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
                    "ingredients": candidate.get("ingredients", []),
                    "explanation": explanation,
                    "rank": None,
                    "block_source": None,
                }
            )

        # Blocked products (hard rule/allergy/conflict blocks) are exclusions,
        # not recommendations, so they never enter the ranked/returned list.
        # They're still recorded in full below for audit/explainability.
        viable_products = [product for product in evaluated_products if not product["is_blocked"]]
        # Products that address one of the user's named concerns (not just a
        # generic skin-type/base-score match) are the "best for the specific
        # concern" — they always outrank products that merely score well.
        viable_products.sort(
            key=lambda item: (len(_matched_concern_labels(item)), item["final_score"]),
            reverse=True,
        )
        for index, product in enumerate(viable_products, start=1):
            product["rank"] = index
            product["matched_concerns"] = _matched_concern_labels(product)

        best_matches = viable_products[:top_n] if top_n else viable_products
        ingredients = self._build_ingredient_list(best_matches, limit=top_n)

        record_id = self._persist_result(user_id, profile.profile_id if profile else None, filter, len(candidates), evaluated_products)
        response_products = [
            {
                "product_id": product["product_id"],
                "name": product["name"],
                "final_score": round(product["final_score"], 2),
                "is_blocked": product["is_blocked"],
                "rank": product["rank"],
                "matched_concerns": product.get("matched_concerns", []),
                "explanation": product["explanation"],
            }
            for product in best_matches
        ]
        return {
            "record_id": record_id,
            "recommendations": {
                "products": response_products,
                "ingredients": ingredients,
            },
            "products": response_products,
            "ingredients": ingredients,
        }

    def _load_ingredient_functions(self, ingredient_ids: List[int]) -> List[Dict[str, Any]]:
        if not ingredient_ids:
            return []
        placeholders = ", ".join([f":ingredient_{index}" for index in range(len(ingredient_ids))])
        query = text(
            f"""
            SELECT
                ingredient_id,
                function_name
            FROM ingredient_functions
            WHERE ingredient_id IN ({placeholders})
            """
        )
        params = {f"ingredient_{index}": ingredient_id for index, ingredient_id in enumerate(ingredient_ids)}
        rows = db.session.execute(query, params).mappings().all()
        return [{"ingredient_id": row.get("ingredient_id"), "function_name": row.get("function_name")} for row in rows]

    def _load_ingredient_functions_map(self, ingredient_ids: List[int]) -> Dict[int, List[str]]:
        result: Dict[int, List[str]] = {}
        for row in self._load_ingredient_functions(ingredient_ids):
            ingredient_id = row.get("ingredient_id")
            function_name = row.get("function_name")
            if ingredient_id is None or not function_name:
                continue
            result.setdefault(int(ingredient_id), []).append(function_name)
        return result

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
                    "explanation": json.dumps(product.get("explanation"), ensure_ascii=False) if isinstance(product.get("explanation"), dict) else product.get("explanation"),
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


def _matched_concern_labels(product: Dict[str, Any]) -> List[str]:
    labels: List[str] = []
    for rule in product.get("boosts", []):
        if str(rule.get("condition_type") or "").lower() != "concern":
            continue
        value = rule.get("condition_value")
        if value and value not in labels:
            labels.append(str(value))
    return labels


# Human-friendly labels for every ingredient_functions.function_name value
# currently in the catalog. _humanize_function() falls back to a title-cased
# version of any future/unmapped function name instead of dropping it.
FUNCTION_LABELS = {
    "anti-acne": "Anti-acne",
    "antibacterial": "Antibacterial",
    "exfoliant": "Exfoliating",
    "anti-inflammatory": "Anti-inflammatory",
    "brightening": "Brightening",
    "sebum-regulating": "Oil control",
    "anti-aging": "Anti-aging",
    "cell-turnover": "Cell renewal",
    "antioxidant": "Antioxidant",
    "collagen-boosting": "Collagen support",
    "moisturizing": "Hydrating",
    "plumping": "Plumping",
    "humectant": "Moisture-binding",
    "soothing": "Soothing",
    "wound-healing": "Healing support",
    "barrier-repair": "Barrier repair",
    "occlusive": "Moisture-sealing",
    "emollient": "Softening",
    "sebum-balancing": "Oil-balancing",
    "sunscreen": "Sun protection",
    "anti-puffiness": "De-puffing",
    "melanin-inhibiting": "Dark spot fading",
    "oil-absorbing": "Oil-absorbing",
    "purifying": "Purifying",
}


def _humanize_function(function_name: Any) -> str:
    key = str(function_name or "").strip().lower()
    if key in FUNCTION_LABELS:
        return FUNCTION_LABELS[key]
    humanized = key.replace("-", " ").replace("_", " ").strip().title()
    return humanized or "Skincare support"


def _humanize_category(category: Any) -> Optional[str]:
    if not category:
        return None
    return str(category).replace("_", " ").strip().title()


def _format_source(clinical_source: Any) -> Optional[str]:
    if not clinical_source:
        return None
    return str(clinical_source).replace("_", " ").strip()


def _safety_note(ingredient: Dict[str, Any]) -> str:
    parts: List[str] = []
    if ingredient.get("cir_approved"):
        parts.append("CIR-approved")

    irritancy = ingredient.get("irritancy_score")
    if irritancy is not None:
        try:
            irritancy_value = int(irritancy)
            if irritancy_value <= 1:
                label = "low irritancy risk"
            elif irritancy_value <= 3:
                label = "moderate irritancy risk"
            else:
                label = "higher irritancy risk — patch test first"
            parts.append(label)
        except (TypeError, ValueError):
            pass

    safety_score = ingredient.get("base_safety_score")
    if safety_score is not None:
        try:
            parts.append(f"safety score {round(float(safety_score))}/100")
        except (TypeError, ValueError):
            pass

    return " · ".join(parts) if parts else "Standard safety profile."


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
