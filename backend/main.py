import os
from dotenv import load_dotenv

dotenv_path = os.path.join(os.path.dirname(__file__), ".env")
load_dotenv(dotenv_path)

from flask import Flask, jsonify
from auth import auth_bp
from config import DevelopmentConfig, ProductionConfig
from extensions import bcrypt, cors, db, jwt, limiter, mail
from models import TokenBlocklist
from skin_profile import skin_profile_bp
from user import user_bp

dotenv_path = os.path.join(os.path.dirname(__file__), ".env")
load_dotenv(dotenv_path)


def create_app():
    env = os.environ.get("FLASK_ENV", "development").lower()
    config_object = ProductionConfig if env == "production" else DevelopmentConfig

    app = Flask(__name__)
    app.config.from_object(config_object)

    db.init_app(app)
    jwt.init_app(app)
    bcrypt.init_app(app)
    mail.init_app(app)
    cors.init_app(
        app,
        origins="*",
        allow_headers=["Content-Type", "Authorization"],
        methods=["GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"],
        supports_credentials=False,
    )
    limiter.init_app(app)

    @jwt.token_in_blocklist_loader
    def check_if_token_revoked(jwt_header, jwt_payload):
        jti = jwt_payload.get("jti")
        return TokenBlocklist.query.filter_by(jti=jti).first() is not None

    app.register_blueprint(auth_bp)
    app.register_blueprint(user_bp)
    app.register_blueprint(skin_profile_bp)

    @app.route("/", methods=["GET"])
    def health_check():
        return jsonify(status="SkinIntel API running"), 200

    with app.app_context():
        db.create_all()

    return app


if __name__ == "__main__":
    app = create_app()
    app.run(debug=True)
