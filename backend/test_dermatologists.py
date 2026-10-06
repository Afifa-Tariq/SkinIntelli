import io
import json
import os
import unittest
from unittest.mock import patch
from urllib.parse import urlparse

from flask_jwt_extended import create_access_token

from extensions import db
from main import create_app
from models import User


class NearbyDermatologistsTests(unittest.TestCase):
    def setUp(self):
        self.database_url = os.environ.get("DATABASE_URL")
        os.environ["DATABASE_URL"] = "sqlite:///:memory:"
        self.app = create_app()
        self.app.config.update(TESTING=True)
        self.client = self.app.test_client()

        with self.app.app_context():
            db.drop_all()
            db.create_all()
            user = User(
                full_name="Dermatology Search User",
                username="dermatology-search",
                email="dermatology-search@example.com",
                password_hash="test",
            )
            db.session.add(user)
            db.session.commit()
            self.headers = {
                "Authorization": f"Bearer {create_access_token(identity=str(user.id))}"
            }

    def tearDown(self):
        with self.app.app_context():
            db.session.remove()
            db.drop_all()
        if self.database_url is None:
            os.environ.pop("DATABASE_URL", None)
        else:
            os.environ["DATABASE_URL"] = self.database_url

    def test_search_returns_google_ranked_places_and_contact_details(self):
        def fake_urlopen(request, timeout):
            self.assertEqual(
                urlparse(request.full_url).path,
                "/v1/places:searchText",
            )
            self.assertEqual(timeout, 20)
            self.assertEqual(request.get_header("X-goog-api-key"), "test-key")
            search = json.loads(request.data.decode("utf-8"))
            self.assertEqual(search["textQuery"], "dermatologist")
            self.assertEqual(search["rankPreference"], "RELEVANCE")
            self.assertEqual(
                search["locationBias"]["circle"]["center"],
                {"latitude": 40.1, "longitude": -73.9},
            )
            payload = {
                "places": [
                    {
                        "id": "place-first",
                        "displayName": {"text": "First Dermatology"},
                        "formattedAddress": "1 Main Street",
                        "rating": 4.8,
                        "userRatingCount": 120,
                        "currentOpeningHours": {"openNow": True},
                        "regularOpeningHours": {
                            "weekdayDescriptions": ["Monday: 9:00 AM - 5:00 PM"]
                        },
                        "nationalPhoneNumber": "+1 place-first",
                        "websiteUri": "https://example.com",
                        "location": {"latitude": 40.1, "longitude": -73.9},
                    },
                    {
                        "id": "place-second",
                        "displayName": {"text": "Second Dermatology"},
                        "formattedAddress": "2 Main Street",
                        "rating": 4.9,
                        "userRatingCount": 20,
                        "location": {"latitude": 40.2, "longitude": -73.8},
                    },
                ]
            }
            return io.BytesIO(json.dumps(payload).encode("utf-8"))

        with patch.dict(os.environ, {"GOOGLE_MAPS_API_KEY": "test-key"}), patch(
            "dermatologists.urlopen", side_effect=fake_urlopen
        ):
            response = self.client.get(
                "/api/dermatologists/nearby?latitude=40.1&longitude=-73.9",
                headers=self.headers,
            )

        self.assertEqual(response.status_code, 200)
        results = response.get_json()["results"]
        self.assertEqual(
            [place["place_id"] for place in results],
            ["place-first", "place-second"],
        )
        self.assertEqual(results[0]["phone_number"], "+1 place-first")
        self.assertEqual(results[0]["opening_hours"], ["Monday: 9:00 AM - 5:00 PM"])

    def test_missing_google_places_key_returns_configuration_error(self):
        with patch.dict(os.environ, {}, clear=True):
            response = self.client.get(
                "/api/dermatologists/nearby?latitude=40.1&longitude=-73.9",
                headers=self.headers,
            )

        self.assertEqual(response.status_code, 503)
        self.assertIn("not configured", response.get_json()["message"])

    def test_invalid_coordinates_are_rejected(self):
        with patch.dict(os.environ, {"GOOGLE_MAPS_API_KEY": "test-key"}):
            response = self.client.get(
                "/api/dermatologists/nearby?latitude=100&longitude=-73.9",
                headers=self.headers,
            )

        self.assertEqual(response.status_code, 400)


if __name__ == "__main__":
    unittest.main()
