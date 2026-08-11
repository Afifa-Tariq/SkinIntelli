import io
import json
import os
import unittest
from unittest.mock import patch

from flask_jwt_extended import create_access_token

from extensions import db
from main import create_app
from models import SkinAnalysisSession, SkinProfile, User, UserImage
from skin_analysis import _merge_questionnaire_data, _normalise_analysis


class SkinAnalysisPipelineTests(unittest.TestCase):
    def test_normalise_analysis_sets_defaults(self):
        analysis = _normalise_analysis({
            "skin_type": "combination",
            "sensitivity_level": "medium",
            "confidence": "92",
            "concerns": ["dryness", "redness"],
            "detected_features": {"dryness": True, "redness": True},
            "analysis_notes": "Looks balanced.",
            "image_quality": "good",
        })

        self.assertEqual(analysis["skin_type"], "combination")
        self.assertEqual(analysis["sensitivity_level"], "medium")
        self.assertEqual(analysis["confidence"], 92)
        self.assertEqual(analysis["concerns"], ["dryness", "redness"])
        self.assertTrue(analysis["detected_features"]["dryness"])

    def test_merge_questionnaire_data_keeps_questionnaire_values_when_present(self):
        merged = _merge_questionnaire_data(
            {
                "skin_type": "dry",
                "sensitivity_level": "high",
                "concerns": ["dehydration"],
                "image_quality": "acceptable",
            },
            {
                "skin_type": "normal",
                "sensitivity_level": "low",
                "concerns": ["acne", "texture"],
                "image_quality": "good",
                "other_field": "keep",
            },
        )

        self.assertEqual(merged["skin_type"], "dry")
        self.assertEqual(merged["sensitivity_level"], "high")
        self.assertEqual(merged["concerns"], ["dehydration"])
        self.assertEqual(merged["image_quality"], "acceptable")
        self.assertEqual(merged["other_field"], "keep")


class SkinAnalysisImageWorkflowTests(unittest.TestCase):
    def setUp(self):
        os.environ["DATABASE_URL"] = "sqlite:///:memory:"
        os.environ["GEMINI_API_KEY"] = "test-key"
        self.app = create_app()
        self.app.config.update(TESTING=True)
        self.client = self.app.test_client()

        with self.app.app_context():
            db.drop_all()
            db.create_all()
            self.user = User(
                full_name="Test User",
                username="testuser",
                email="testuser@example.com",
                password_hash="not-real-hash",
            )
            db.session.add(self.user)
            db.session.commit()
            self.token = create_access_token(identity=self.user.id)

    def tearDown(self):
        with self.app.app_context():
            db.session.remove()
            db.drop_all()

    def test_image_upload_persists_analysis_and_recommendations(self):
        analysis_payload = {
            "skin_type": "oily",
            "sensitivity_level": "medium",
            "confidence": 92,
            "concerns": ["acne", "oiliness"],
            "detected_features": {"acne": True, "oiliness": True, "redness": False},
            "analysis_notes": "Oily and acne-prone skin detected.",
            "image_quality": "good",
            "recommendations": {
                "products": [{"name": "Oil-Free Gel Cleanser", "brand": "SkinIntel"}],
                "ingredients": [{"name": "Salicylic Acid", "benefits": ["Targets acne"]}],
            },
        }

        class FakeContentResponse:
            def __init__(self, text):
                self.text = text

        class FakeModelsClient:
            def generate_content(self, model, contents):
                return FakeContentResponse(json.dumps(analysis_payload))

        class FakeGenaiClient:
            def __init__(self, *args, **kwargs):
                self.models = FakeModelsClient()

        with patch("skin_analysis.genai.Client", FakeGenaiClient), patch(
            "skin_analysis.types.Part.from_bytes",
            return_value=object(),
        ):
            response = self.client.post(
                "/api/skin/analyze-and-recommend",
                data={"image": (io.BytesIO(b"fake-image-bytes"), "face.jpg")},
                headers={"Authorization": f"Bearer {self.token}"},
            )

        self.assertEqual(response.status_code, 200)
        body = response.get_json()
        self.assertEqual(body["skin_analysis"]["skin_type"], "oily")
        self.assertEqual(body["skin_analysis"]["concerns"], ["acne", "oiliness"])
        self.assertEqual(body["recommendations"]["products"][0]["name"], "Oil-Free Gel Cleanser")

        with self.app.app_context():
            profile = (
                SkinProfile.query.filter_by(user_id=self.user.id)
                .order_by(SkinProfile.created_at.desc(), SkinProfile.id.desc())
                .first()
            )
            session = (
                SkinAnalysisSession.query.filter_by(user_id=self.user.id)
                .order_by(SkinAnalysisSession.created_at.desc(), SkinAnalysisSession.id.desc())
                .first()
            )
            stored_image = (
                UserImage.query.filter_by(user_id=self.user.id)
                .order_by(UserImage.created_at.desc(), UserImage.id.desc())
                .first()
            )

            self.assertIsNotNone(profile)
            self.assertEqual(profile.skin_type, "oily")
            self.assertEqual(profile.skin_concerns, ["acne", "oiliness"])
            self.assertEqual(profile.source, "image")
            self.assertIsNotNone(session)
            self.assertEqual(session.concerns, ["acne", "oiliness"])
            self.assertEqual(session.image_quality, "good")
            self.assertEqual(session.raw_response["recommendations"]["products"][0]["name"], "Oil-Free Gel Cleanser")
            self.assertIsNotNone(stored_image)
            self.assertEqual(stored_image.image_bytes, b"fake-image-bytes")
            self.assertEqual(stored_image.filename, "face.jpg")


if __name__ == "__main__":
    unittest.main()
