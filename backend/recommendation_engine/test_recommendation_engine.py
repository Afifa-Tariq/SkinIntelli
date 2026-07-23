import unittest

try:
    from .recommendation_engine import UserProfile, condition_matches
except ImportError:  # pragma: no cover - fallback for direct discovery
    from recommendation_engine.recommendation_engine import UserProfile, condition_matches


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


if __name__ == "__main__":
    unittest.main()
