import os
import unittest

from flask_jwt_extended import create_access_token
from sqlalchemy import text

from extensions import db
from main import create_app
from models import User


class RoutineEndpointTests(unittest.TestCase):
    def setUp(self):
        os.environ["DATABASE_URL"] = "sqlite:///:memory:"
        self.app = create_app()
        self.app.config.update(TESTING=True)
        self.client = self.app.test_client()

        with self.app.app_context():
            db.drop_all()
            db.create_all()

            db.session.execute(
                text(
                    """
                    CREATE TABLE products (
                        product_id INTEGER PRIMARY KEY,
                        name VARCHAR(200),
                        brand VARCHAR(200),
                        category VARCHAR(50),
                        image_url VARCHAR(255),
                        usage_time VARCHAR(10)
                    )
                    """
                )
            )
            db.session.execute(
                text(
                    """
                    CREATE TABLE ingredients (
                        ingredient_id INTEGER PRIMARY KEY,
                        inci_name VARCHAR(200)
                    )
                    """
                )
            )
            db.session.execute(
                text(
                    """
                    CREATE TABLE product_ingredients (
                        product_id INTEGER,
                        ingredient_id INTEGER
                    )
                    """
                )
            )
            db.session.execute(
                text(
                    """
                    INSERT INTO products (product_id, name, brand, category, image_url, usage_time)
                    VALUES
                        (1, 'Gentle Cleanser', 'Brand X', 'cleanser', '', 'AM'),
                        (2, 'Niacinamide Serum', 'Brand X', 'serum', '', 'AM'),
                        (3, 'Retinol Cream', 'Brand X', 'moisturizer', '', 'PM')
                    """
                )
            )
            db.session.execute(
                text(
                    """
                    INSERT INTO ingredients (ingredient_id, inci_name)
                    VALUES (1, 'Salicylic Acid'), (2, 'Retinol')
                    """
                )
            )
            db.session.execute(
                text(
                    """
                    INSERT INTO product_ingredients (product_id, ingredient_id)
                    VALUES (1, 1), (2, 1), (3, 2)
                    """
                )
            )

            owner = User(full_name="Owner User", username="owner", email="owner@example.com", password_hash="hash")
            other = User(full_name="Other User", username="other", email="other@example.com", password_hash="hash")
            db.session.add_all([owner, other])
            db.session.commit()

            self.user_id = owner.id
            self.other_user_id = other.id
            self.auth_headers = {"Authorization": f"Bearer {create_access_token(identity=str(owner.id))}"}
            self.other_auth_headers = {"Authorization": f"Bearer {create_access_token(identity=str(other.id))}"}
            self.routine_id = self._generate_routine()

            db.session.commit()

    def tearDown(self):
        with self.app.app_context():
            db.session.remove()
            db.drop_all()

    def _generate_routine(self):
        response = self.client.post(
            "/api/routine/generate",
            json={
                "recommendations": [
                    {"product_id": 1, "is_blocked": False},
                    {"product_id": 3, "is_blocked": False},
                ]
            },
            headers=self.auth_headers,
        )
        self.assertEqual(response.status_code, 201, response.get_data(as_text=True))
        payload = response.get_json()
        return payload["routine_id"]

    def test_get_active_routine(self):
        response = self.client.get("/api/routine/active", headers=self.auth_headers)
        self.assertEqual(response.status_code, 200)
        body = response.get_json()
        self.assertIn("items", body)
        self.assertTrue(body["is_active"])

    def test_get_routine_by_id(self):
        response = self.client.get(f"/api/routine/{self.routine_id}", headers=self.auth_headers)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.get_json()["routine_id"], self.routine_id)

    def test_forbidden_access(self):
        response = self.client.get(f"/api/routine/{self.routine_id}", headers=self.other_auth_headers)
        self.assertEqual(response.status_code, 403)

    def test_patch_routine_name(self):
        response = self.client.patch(
            f"/api/routine/{self.routine_id}",
            json={"name": "Updated Routine"},
            headers=self.auth_headers,
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.get_json()["name"], "Updated Routine")

    def test_patch_add_item(self):
        response = self.client.patch(
            f"/api/routine/{self.routine_id}",
            json={
                "items": [
                    {"product_id": 2, "time_of_day": "PM", "step_order": 2, "notes": "Test item"}
                ]
            },
            headers=self.auth_headers,
        )
        self.assertEqual(response.status_code, 200)
        items = response.get_json()["items"]
        self.assertTrue(any(item["product_id"] == 2 and item["notes"] == "Test item" for item in items))

    def test_patch_remove_item(self):
        add_response = self.client.patch(
            f"/api/routine/{self.routine_id}",
            json={
                "items": [
                    {"product_id": 2, "time_of_day": "PM", "step_order": 3, "notes": "Temporary item"}
                ]
            },
            headers=self.auth_headers,
        )
        added_item = next(item for item in add_response.get_json()["items"] if item["product_id"] == 2 and item["notes"] == "Temporary item")

        remove_response = self.client.patch(
            f"/api/routine/{self.routine_id}",
            json={"remove_item_ids": [added_item["routine_item_id"]]},
            headers=self.auth_headers,
        )
        self.assertEqual(remove_response.status_code, 200)
        remaining = remove_response.get_json()["items"]
        self.assertFalse(any(item["routine_item_id"] == added_item["routine_item_id"] for item in remaining))

    def test_patch_replace_items(self):
        response = self.client.patch(
            f"/api/routine/{self.routine_id}",
            json={
                "replace_items": True,
                "items": [
                    {"product_id": 2, "time_of_day": "AM", "step_order": 1, "notes": "Replacement step"}
                ],
            },
            headers=self.auth_headers,
        )
        self.assertEqual(response.status_code, 200)
        payload = response.get_json()
        self.assertEqual(len(payload["items"]), 1)
        self.assertEqual(payload["items"][0]["product_id"], 2)
        self.assertEqual(payload["items"][0]["notes"], "Replacement step")

    def test_patch_invalid_product_returns_400(self):
        response = self.client.patch(
            f"/api/routine/{self.routine_id}",
            json={"items": [{"product_id": 999, "time_of_day": "AM", "step_order": 1}]},
            headers=self.auth_headers,
        )
        self.assertEqual(response.status_code, 400)

    def test_requires_authentication(self):
        response = self.client.get("/api/routine/active")
        self.assertEqual(response.status_code, 401)


if __name__ == "__main__":
    unittest.main()
