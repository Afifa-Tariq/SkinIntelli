from datetime import datetime

from extensions import db
from sqlalchemy import DateTime, Integer, String


class TokenBlocklist(db.Model):
    __tablename__ = "token_blocklist"

    id = db.Column(Integer, primary_key=True)
    jti = db.Column(String(36), unique=True, nullable=False, index=True)
    created_at = db.Column(DateTime, default=datetime.utcnow, nullable=False)
