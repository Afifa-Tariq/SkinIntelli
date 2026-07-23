from main import create_app
from recommendation_engine.recommendation import recommendation_bp


app = create_app()
app.register_blueprint(recommendation_bp)


if __name__ == "__main__":
    app.run(host="0.0.0.0", debug=True)
