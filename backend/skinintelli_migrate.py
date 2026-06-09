"""
Safe SkinIntelli migration helper.

This script now delegates schema creation to the Flask app's SQLAlchemy models.
Use:
  python skinintelli_migrate.py
"""

from main import create_app


def main():
    app = create_app()
    with app.app_context():
        print('Creating missing tables using SQLAlchemy models...')
        # create_all only creates tables that do not already exist.
        # This avoids hand-written DDL drift and keeps schema aligned with models.
        from extensions import db
        db.create_all()
        print('Schema creation completed.')


if __name__ == '__main__':
    main()
