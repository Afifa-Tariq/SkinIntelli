from datetime import datetime, timedelta
from random import randint

from extensions import bcrypt, db
from sqlalchemy import Boolean, DateTime, Integer, JSON, String, Text


class User(db.Model):
    __tablename__ = "users"

    id = db.Column(Integer, primary_key=True)
    full_name = db.Column(String(120), nullable=False)
    username = db.Column(String(80), unique=True, nullable=True)
    email = db.Column(String(120), unique=True, nullable=False)
    password_hash = db.Column(String(256), nullable=False)
    gender = db.Column(String(20), nullable=True)
    is_verified = db.Column(Boolean, default=False, nullable=False)
    otp_code = db.Column(String(6), nullable=True)
    otp_expires_at = db.Column(DateTime, nullable=True)
    skin_type = db.Column(String(50), nullable=True)
    skin_concerns = db.Column(JSON, nullable=True)
    allergies = db.Column(Text, nullable=True)
    environment = db.Column(String(50), nullable=True)
    goals = db.Column(JSON, nullable=True)
    created_at = db.Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = db.Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    skin_profiles = db.relationship(
        "SkinProfile",
        back_populates="user",
        order_by="SkinProfile.created_at.desc()",
        cascade="all, delete-orphan",
        passive_deletes=True,
    )

    def set_password(self, plain: str) -> None:
        self.password_hash = bcrypt.generate_password_hash(plain).decode("utf-8")

    def check_password(self, plain: str) -> bool:
        return bcrypt.check_password_hash(self.password_hash, plain)

    def set_otp(self) -> str:
        code = f"{randint(0, 999999):06d}"
        self.otp_code = code
        self.otp_expires_at = datetime.utcnow() + timedelta(minutes=10)
        return code

    def verify_otp(self, code: str) -> bool:
        if not self.otp_code or not self.otp_expires_at:
            return False
        if self.otp_code != code:
            return False
        return self.otp_expires_at >= datetime.utcnow()

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "full_name": self.full_name,
            "username": self.username,
            "email": self.email,
            "gender": self.gender,
            "is_verified": self.is_verified,
            "skin_type": self.skin_type,
            "skin_concerns": self.skin_concerns,
            "allergies": self.allergies,
            "environment": self.environment,
            "goals": self.goals,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }
