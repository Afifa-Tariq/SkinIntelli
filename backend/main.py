import os
from dotenv import load_dotenv
from sqlalchemy import create_engine, text

dotenv_path = os.path.join(os.path.dirname(__file__), ".env")
load_dotenv(dotenv_path)

from flask import Flask, jsonify
from auth import auth_bp
from config import DevelopmentConfig, ProductionConfig
from extensions import bcrypt, db, jwt, limiter, mail, cors
from models import TokenBlocklist
from recommendation_engine.recommendation import recommendation_bp
from routine_engine.routine import routine_bp
from skin_analysis import skin_analysis_bp
from skin_profile import skin_profile_bp
from user import user_bp


def resolve_database_uri():
    uri = os.environ.get("DATABASE_URL") or os.environ.get("DEV_DATABASE_URL") or "sqlite:///skinintelli.db"
    if uri.startswith("mysql"):
        try:
            engine = create_engine(uri)
            with engine.connect() as connection:
                connection.execute(text("SELECT 1"))
            return uri
        except Exception as exc:
            print(f"MySQL connection failed ({exc}); falling back to SQLite")
            return "sqlite:///skinintelli.db"
    return uri


def create_app():
    env = os.environ.get("FLASK_ENV", "development").lower()
    config_object = ProductionConfig if env == "production" else DevelopmentConfig

    app = Flask(__name__)
    app.config.from_object(config_object)
    app.config["SQLALCHEMY_DATABASE_URI"] = resolve_database_uri()

    db.init_app(app)
    jwt.init_app(app)
    bcrypt.init_app(app)
    mail.init_app(app)
    # Allow CORS from any origin on all routes so the frontend can reach the API
    cors.init_app(app, resources={r"/*": {"origins": "*"}})
    limiter.init_app(app)

    @jwt.token_in_blocklist_loader
    def check_if_token_revoked(jwt_header, jwt_payload):
        jti = jwt_payload.get("jti")
        return TokenBlocklist.query.filter_by(jti=jti).first() is not None

    app.register_blueprint(auth_bp)
    app.register_blueprint(user_bp)
    app.register_blueprint(skin_analysis_bp)
    app.register_blueprint(skin_profile_bp)
    app.register_blueprint(recommendation_bp)
    app.register_blueprint(routine_bp)

    @app.route("/", methods=["GET"])
    def health_check():
        return jsonify(status="SkinIntel API running"), 200

    with app.app_context():
        db.create_all()

    return app


if __name__ == "__main__":
    app = create_app()
    app.run(host='0.0.0.0', debug=True)
