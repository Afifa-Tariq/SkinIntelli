# SkinIntelli Test Report

## 1. Summary

- Test suite location: `backend/recommendation_engine/test_recommendation_engine.py`
- Test framework: `unittest`
- Total test cases executed: 5
- Pass / Fail: 5 / 0
- Execution command: `PYTHONPATH=backend d:/SkinIntelli/.venv/Scripts/python.exe -m unittest discover -s backend -p 'test_*.py'`
- Result: `OK`

> Note: No other automated tests were found in this repository for Python or Dart files, including `frontend` and other backend modules.

## 2. Test Environment

- Operating System: Windows
- Python interpreter: `d:/SkinIntelli/.venv/Scripts/python.exe`
- Python version: 3.14.4
- Workspace root: `d:\SkinIntelli`

## 3. Tested Modules

The existing tests cover the following backend components:

- `backend/recommendation_engine/recommendation_engine.py`
  - `UserProfile`
  - `condition_matches`
- `backend/recommendation_engine/explanation_engine.py`
  - `calculate_confidence`
  - `get_priority`
  - `build_explanation`

## 4. Detailed Test Cases

### 4.1 RecommendationEngineConditionTests

1. `test_skin_type_condition_matches_case_insensitively`
   - Purpose: Verify the skin type matching logic is case-insensitive.
   - Input:
     - User profile skin type: `Oily`
     - Rule condition type: `skin_type`
     - Rule condition value: `oily`
   - Expected result: `condition_matches()` returns `True`

2. `test_concern_condition_matches_case_insensitively`
   - Purpose: Verify concern matching is case-insensitive.
   - Input:
     - User profile concerns: `['Acne', 'Sensitivity']`
     - Rule condition type: `concern`
     - Rule condition value: `acne`
   - Expected result: `condition_matches()` returns `True`

3. `test_age_range_condition_matches`
   - Purpose: Verify age range matching works correctly.
   - Input:
     - User profile age: `22`
     - Rule condition type: `age_range`
     - Rule condition value: `18-25`
   - Expected result: `condition_matches()` returns `True`

### 4.2 ExplanationEngineContractTests

4. `test_confidence_score_stays_in_range_and_priority_format`
   - Purpose: Validate confidence scoring behavior and priority classification.
   - Input:
     - Three fired rules with `BOOST` effect and varying evidence levels: `strong`, `moderate`, `anecdotal`
     - Final score: `92.5`
   - Expected results:
     - `calculate_confidence()` returns a score between `0` and `100`
     - `get_priority(92.5)` returns `HIGH`

5. `test_build_explanation_returns_all_required_fields`
   - Purpose: Ensure explanation output contains all required fields and correct matched rule formatting.
   - Input:
     - Product: `The Ordinary Niacinamide 10% + Zinc 1%`
     - Fired rules: two sample boost rules for skin type and concern
     - User profile: skin type `oily`, concerns `['acne']`, no allergens
   - Expected results:
     - `build_explanation()` returns keys:
       - `skin_type_match`
       - `concern_targeting`
       - `safety_summary`
       - `conflict_exclusions`
       - `matched_rules`
       - `scientific_reasoning`
       - `expected_benefits`
       - `confidence_score`
       - `confidence_breakdown`
       - `recommendation_priority`
       - `priority_reason`
     - `matched_rules` equals `["R-007", "R-009"]`
     - `confidence_score` remains in the `0-100` range

## 5. Test Result Output

```
.....
----------------------------------------------------------------------
Ran 5 tests in 0.001s

OK
```

## 6. Coverage and Gaps

- The current automated tests cover only the recommendation and explanation engines.
- No tests were discovered for:
  - `backend/auth/`
  - `backend/skin_profile/`
  - `backend/routine_engine/`
  - `backend/user.py`
  - `backend/main.py` or request routing logic
  - `frontend/skinintelli/` Flutter code
- There is no existing frontend test suite in the `frontend/skinintelli/test/` directory.

## 7. Recommendations for Thesis

- Include the above test cases as proof of unit test coverage for core recommendation logic.
- Mention the environment and command used to execute the tests.
- Note the current limitations: only 5 unit tests exist, and additional integration or frontend tests are needed for complete system validation.
- If you need a fuller report, add tests for API endpoints, database queries, user authentication flows, and Flutter UI screens.
