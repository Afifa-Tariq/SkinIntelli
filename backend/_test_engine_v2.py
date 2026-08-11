import json
from main import create_app
from extensions import db
from recommendation_engine.recommendation_engine import RecommendationEngine
from sqlalchemy import text

app = create_app()
with app.app_context():
    row = db.session.execute(text("SELECT user_id FROM skin_profiles ORDER BY id DESC LIMIT 1")).first()
    user_id = row[0]

    profile_row = db.session.execute(
        text("SELECT skin_type, skin_concerns FROM skin_profiles WHERE user_id=:uid ORDER BY id DESC LIMIT 1"),
        {"uid": user_id},
    ).first()
    print("Profile:", profile_row)

    result = RecommendationEngine().generate(user_id)
    products = result["products"]
    ingredients = result["ingredients"]

    print()
    print(f"Products returned: {len(products)}")
    for p in products:
        print(f"  #{p['rank']} {p['name']} score={p['final_score']} matched_concerns={p['matched_concerns']}")

    print()
    print(f"Ingredients returned: {len(ingredients)}")
    for i in ingredients:
        print(f"  - {i['name']} ({i['category']})")
        print(f"    benefit: {i['benefit']}")
        print(f"    why: {i['why_recommended']} | evidence: {i['evidence_level']} | source: {i['source']}")
        print(f"    functions: {i['functions']}")
        print(f"    safety: {i['safety_note']}")
