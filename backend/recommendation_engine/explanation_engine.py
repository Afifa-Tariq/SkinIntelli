from __future__ import annotations

from typing import Any, Dict, Iterable, List, Optional, Sequence, Tuple

EVIDENCE_WEIGHT = {"strong": 1.0, "moderate": 0.8, "anecdotal": 0.5}
BENEFIT_MAP = {
    "anti-acne": "Reduced acne lesion count over 4-8 weeks",
    "antibacterial": "Fewer acne-causing bacteria on the skin",
    "anti-inflammatory": "Calmer, less inflamed skin",
    "brightening": "Improved skin radiance and reduced dark spots over 8-12 weeks",
    "moisturizing": "Sustained skin hydration for 24+ hours",
    "barrier-repair": "Strengthened skin barrier, reduced transepidermal water loss",
    "anti-aging": "Reduced appearance of fine lines and wrinkles over 12 weeks",
    "soothing": "Reduced redness and skin reactivity",
    "sebum-regulating": "Minimized pore appearance and reduced shine",
    "antioxidant": "Protection against environmental oxidative stress",
    "exfoliant": "Smoother skin texture and improved cell turnover",
    "collagen-boosting": "Firmer, more elastic skin over 8-12 weeks",
    "cell-turnover": "Faster skin renewal and smoother texture",
    "plumping": "Plumper, more hydrated-looking skin",
    "humectant": "Deeper hydration by drawing moisture into the skin",
    "wound-healing": "Faster recovery of irritated or compromised skin",
    "occlusive": "Locked-in moisture and reduced water loss",
    "emollient": "Softer, smoother skin texture",
    "sebum-balancing": "Balanced oil production without over-drying",
    "sunscreen": "Daily protection against UV damage and premature aging",
    "anti-puffiness": "Reduced puffiness for a more refreshed look",
    "melanin-inhibiting": "Faded dark spots and a more even tone over time",
    "oil-absorbing": "Reduced shine and a mattified look throughout the day",
    "purifying": "Clearer pores and reduced buildup",
}


def calculate_confidence(fired_rules: Sequence[Any], final_score: float) -> int:
    if not fired_rules:
        return 50

    boost_rules = [rule for rule in fired_rules if str(_value(rule, "effect", "")).upper() in {"BOOST", "ALLOW"}]
    if not boost_rules:
        return 50

    total_weight = sum(EVIDENCE_WEIGHT.get(str(_value(rule, "evidence_level", "moderate") or "moderate").lower(), 0.5) for rule in boost_rules)
    max_possible = float(len(boost_rules))
    raw = (total_weight / max_possible) * 100.0 if max_possible else 0.0
    confidence = int((raw * 0.6) + (float(final_score or 0.0) * 0.4))
    return max(0, min(100, confidence))


def get_priority(final_score: float) -> str:
    if final_score >= 80:
        return "HIGH"
    if final_score >= 55:
        return "MEDIUM"
    return "LOW"


def _priority_reason(final_score: float) -> str:
    if final_score >= 80:
        return "An excellent match for your skin profile."
    if final_score >= 55:
        return "A solid match for your skin profile."
    return "A modest match — worth trying, but not a standout fit."


def build_explanation(
    product: Any,
    eval_result: Dict[str, Any],
    fired_rules: Sequence[Any],
    user_profile: Dict[str, Any],
    pi_rows: Optional[Sequence[Any]] = None,
    ingredient_functions: Optional[Sequence[Any]] = None,
    conflict_rows: Optional[Sequence[Any]] = None,
) -> Dict[str, Any]:
    pi_rows = list(pi_rows or [])
    ingredient_functions = list(ingredient_functions or [])
    conflict_rows = list(conflict_rows or [])

    skin_type_match = _skin_type_match(fired_rules, user_profile.get("skin_type"), getattr(product, "name", None) or getattr(product, "get", lambda *_: "")("name"))
    concern_targeting = _concern_targeting(fired_rules, user_profile.get("concerns") or [])
    safety_summary = _safety_summary(pi_rows, user_profile.get("allergen_ingredient_ids") or [])
    conflict_exclusions = _conflict_exclusions(conflict_rows, pi_rows)
    matched_rules = [f"R-{_rule_id(rule):03d}" for rule in fired_rules if _rule_id(rule) is not None]
    scientific_reasoning = _scientific_reasoning(fired_rules)
    expected_benefits = _expected_benefits(ingredient_functions, pi_rows)
    final_score = float(eval_result.get("final_score") or 0.0)
    confidence = calculate_confidence(fired_rules, final_score)
    priority = get_priority(final_score)
    priority_reason = _priority_reason(final_score)

    return {
        "skin_type_match": skin_type_match,
        "concern_targeting": concern_targeting,
        "safety_summary": safety_summary,
        "conflict_exclusions": conflict_exclusions,
        "matched_rules": matched_rules,
        "scientific_reasoning": scientific_reasoning,
        "expected_benefits": expected_benefits,
        "confidence_score": confidence,
        "confidence_breakdown": _confidence_breakdown(fired_rules, final_score, confidence),
        "recommendation_priority": priority,
        "priority_reason": priority_reason,
    }


def _skin_type_match(fired_rules: Sequence[Any], skin_type: Optional[str], product_name: Optional[str]) -> str:
    matches = [
        rule
        for rule in fired_rules
        if str(_value(rule, "condition_type", "")).lower() == "skin_type"
        and str(_value(rule, "effect", "")).upper() == "BOOST"
    ]
    if matches:
        rule = matches[0]
        explanation = str(_value(rule, "explanation_template", "") or "")
        ingredient_name = _value(_value(rule, "ingredient", None), "inci_name", "")
        explanation = explanation.replace("{ingredient_name}", str(ingredient_name))
        explanation = explanation.replace("{condition_value}", str(skin_type or "your skin type"))
        return explanation
    skin_type = str(skin_type or "your skin type").capitalize()
    return f"Product is compatible with {skin_type} skin type."


def _concern_targeting(fired_rules: Sequence[Any], concerns: Sequence[str]) -> List[str]:
    result: List[str] = []
    for concern in concerns:
        rules = [
            rule
            for rule in fired_rules
            if str(_value(rule, "condition_type", "")).lower() == "concern"
            and str(_value(rule, "condition_value", "") or "").lower() == str(concern).lower()
            and str(_value(rule, "effect", "")).upper() == "BOOST"
        ]
        for rule in rules:
            explanation = str(_value(rule, "explanation_template", "") or "")
            ingredient_name = _value(_value(rule, "ingredient", None), "inci_name", "")
            explanation = explanation.replace("{ingredient_name}", str(ingredient_name))
            explanation = explanation.replace("{condition_value}", str(concern or "your concern"))
            result.append(f"{str(concern).capitalize()}: {explanation}")
    return result if result else ["No specific concern-targeting rules matched."]


def _safety_summary(pi_rows: Sequence[Any], allergen_ids: Sequence[int]) -> List[str]:
    summary: List[str] = []
    allergen_ids_set = set(int(item) for item in allergen_ids)

    for pi in pi_rows:
        ingredient = getattr(pi, "ingredient", None) or (pi.get("ingredient") if isinstance(pi, dict) else None)
        if ingredient is None:
            continue
        inci_name = _lookup(ingredient, "inci_name") or _lookup(ingredient, "name") or "Ingredient"
        cir_approved = _lookup(ingredient, "cir_approved", default=True)
        irritancy_score = _lookup(ingredient, "irritancy_score", default=0)
        base_safety_score = _lookup(ingredient, "base_safety_score", default=95)

        try:
            irritancy_value = int(irritancy_score)
        except (TypeError, ValueError):
            irritancy_value = 0
        if irritancy_value <= 1:
            irritancy_label = "low irritancy"
        elif irritancy_value <= 3:
            irritancy_label = "moderate irritancy"
        else:
            irritancy_label = "higher irritancy — patch test first"

        try:
            safety_value = round(float(base_safety_score))
        except (TypeError, ValueError):
            safety_value = 95

        approval_label = "CIR-approved" if cir_approved else "not CIR-reviewed"
        summary.append(f"{inci_name}: {approval_label}, {irritancy_label}, safety score {safety_value}/100.")

    allergen_names = []
    for pi in pi_rows:
        ingredient = getattr(pi, "ingredient", None) or (pi.get("ingredient") if isinstance(pi, dict) else None)
        ingredient_id = getattr(pi, "ingredient_id", None) or (pi.get("ingredient_id") if isinstance(pi, dict) else None)
        if ingredient and int(ingredient_id) in allergen_ids_set:
            allergen_names.append(_lookup(ingredient, "inci_name") or _lookup(ingredient, "name") or "Ingredient")

    if allergen_names:
        summary.append(f"WARNING: Product contains your allergen(s): {', '.join(allergen_names)}")
    else:
        summary.append("Product contains none of your declared allergens.")
    return summary


def _conflict_exclusions(conflict_rows: Sequence[Any], pi_rows: Sequence[Any]) -> List[str]:
    if not conflict_rows:
        return ["No ingredient conflicts detected in this product."]
    return [str(getattr(conflict, "explanation", "") or conflict.get("explanation") or "Ingredient conflict detected.") for conflict in conflict_rows]


def _scientific_reasoning(fired_rules: Sequence[Any]) -> List[str]:
    result: List[str] = []
    for rule in fired_rules:
        explanation = str(_value(rule, "explanation_template", "") or "")
        ingredient_name = _value(_value(rule, "ingredient", None), "inci_name", "")
        explanation = explanation.replace("{ingredient_name}", str(ingredient_name))
        explanation = explanation.replace("{condition_value}", str(_value(rule, "condition_value", "") or ""))
        if not explanation:
            continue
        source = str(_value(rule, "clinical_source", "") or "").replace("_", " ").strip()
        result.append(f"{explanation} (Source: {source})" if source else explanation)
    return result


def _expected_benefits(ingredient_functions: Sequence[Any], pi_rows: Sequence[Any]) -> List[str]:
    seen = set()
    benefits: List[str] = []
    for item in ingredient_functions:
        function_name = str(getattr(item, "function_name", "") or (item.get("function_name") if isinstance(item, dict) else "")).strip().lower()
        if function_name in BENEFIT_MAP and function_name not in seen:
            benefits.append(BENEFIT_MAP[function_name])
            seen.add(function_name)
    return benefits


def _lookup(value: Any, key: str, default: Any = None) -> Any:
    if isinstance(value, dict):
        return value.get(key, default)
    return getattr(value, key, default)


def _confidence_breakdown(fired_rules: Sequence[Any], final_score: float, confidence: int) -> str:
    boost_rules = [rule for rule in fired_rules if str(_value(rule, "effect", "")).upper() in {"BOOST", "ALLOW"}]
    if not boost_rules:
        return f"No ingredients were specifically matched to your profile, so this is a general suggestion ({confidence}% confidence)."

    total = len(boost_rules)
    strong = sum(1 for rule in boost_rules if str(_value(rule, "evidence_level", "moderate") or "moderate").lower() == "strong")
    match_word = "match" if total == 1 else "matches"

    if strong == total:
        evidence_note = "all backed by strong clinical evidence"
    elif strong > 0:
        evidence_note = f"{strong} of {total} backed by strong clinical evidence"
    else:
        evidence_note = "backed by moderate-strength evidence"

    return f"{total} ingredient {match_word} found for your profile, {evidence_note}. Confidence: {confidence}%."


def _rule_id(rule: Any) -> Optional[int]:
    try:
        return int(_value(rule, "rule_id", None))
    except Exception:
        return None


def _value(item: Any, key: str, default: Any = None) -> Any:
    if isinstance(item, dict):
        return item.get(key, default)
    return getattr(item, key, default)
