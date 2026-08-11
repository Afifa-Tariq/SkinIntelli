import json
from main import create_app
from extensions import db
from recommendation_engine.recommendation_engine import RecommendationEngine
from sqlalchemy import text

app = create_app()
with app.app_context():
    row = db.session.execute(text("SELECT user_id FROM skin_profiles ORDER BY id DESC LIMIT 1")).first()
    user_id = row[0]

    result = RecommendationEngine().generate(user_id)
    top_product = result["products"][0]
    print("Product:", top_product["name"], "score:", top_product["final_score"])
    print(json.dumps(top_product["explanation"], indent=2))
