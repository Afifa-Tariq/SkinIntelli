import unittest
from types import SimpleNamespace

try:
    from .recommendation_engine import UserProfile, condition_matches
except ImportError:  # pragma: no cover - fallback for direct discovery
    from recommendation_engine.recommendation_engine import UserProfile, condition_matches

try:
    from .explanation_engine import build_explanation, calculate_confidence, get_priority
except ImportError:  # pragma: no cover - fallback for direct discovery
    from recommendation_engine.explanation_engine import build_explanation, calculate_confidence, get_priority


class RecommendationEngineConditionTests(unittest.TestCase):
    def test_skin_type_condition_matches_case_insensitively(self) -> None:
        profile = UserProfile(profile_id=1, user_id=1, skin_type="Oily")
        rule = {"condition_type": "skin_type", "condition_value": "oily", "ingredient_id": 1}
        self.assertTrue(condition_matches(rule, profile))

    def test_concern_condition_matches_case_insensitively(self) -> None:
        profile = UserProfile(profile_id=1, user_id=1, concerns=["Acne", "Sensitivity"])
        rule = {"condition_type": "concern", "condition_value": "acne", "ingredient_id": 2}
        self.assertTrue(condition_matches(rule, profile))

    def test_age_range_condition_matches(self) -> None:
        profile = UserProfile(profile_id=1, user_id=1, age=22)
        rule = {"condition_type": "age_range", "condition_value": "18-25", "ingredient_id": 3}
        self.assertTrue(condition_matches(rule, profile))


class ExplanationEngineContractTests(unittest.TestCase):
    def test_confidence_score_stays_in_range_and_priority_format(self) -> None:
        fired_rules = [
            SimpleNamespace(effect="BOOST", evidence_level="strong"),
            SimpleNamespace(effect="BOOST", evidence_level="moderate"),
            SimpleNamespace(effect="BOOST", evidence_level="anecdotal"),
        ]
        confidence = calculate_confidence(fired_rules, final_score=92.5)
        self.assertGreaterEqual(confidence, 0)
        self.assertLessEqual(confidence, 100)
        self.assertEqual(get_priority(92.5), "HIGH")

    def test_build_explanation_returns_all_required_fields(self) -> None:
        product = SimpleNamespace(product_id=14, name="The Ordinary Niacinamide 10% + Zinc 1%")
        fired_rules = [
            SimpleNamespace(
                rule_id=7,
                effect="BOOST",
                evidence_level="strong",
                condition_type="skin_type",
                condition_value="oily",
                explanation_template="Niacinamide helps {condition_value} skin by reducing excess sebum.",
                ingredient=SimpleNamespace(inci_name="Niacinamide"),
                clinical_source="PubMed_PMID_17147561",
            ),
            SimpleNamespace(
                rule_id=9,
                effect="BOOST",
                evidence_level="strong",
                condition_type="concern",
                condition_value="acne",
                explanation_template="Niacinamide helps with {condition_value}.",
                ingredient=SimpleNamespace(inci_name="Niacinamide"),
                clinical_source="PubMed_PMID_22253406",
            ),
        ]
        explanation = build_explanation(
            product=product,
            eval_result={"final_score": 92.5},
            fired_rules=fired_rules,
            user_profile={
                "skin_type": "oily",
                "concerns": ["acne"],
                "allergen_ingredient_ids": [],
            },
            pi_rows=[],
            ingredient_functions=[],
            conflict_rows=[],
        )

        expected_fields = {
            "skin_type_match",
            "concern_targeting",
            "safety_summary",
            "conflict_exclusions",
            "matched_rules",
            "scientific_reasoning",
            "expected_benefits",
            "confidence_score",
            "confidence_breakdown",
            "recommendation_priority",
            "priority_reason",
        }
        self.assertTrue(expected_fields.issubset(explanation.keys()))
        self.assertEqual(explanation["matched_rules"], ["R-007", "R-009"])
        self.assertTrue(all(0 <= explanation["confidence_score"] <= 100 for _ in [0]))


if __name__ == "__main__":
    unittest.main()
