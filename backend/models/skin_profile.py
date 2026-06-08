from datetime import datetime

from extensions import db


class SkinProfile(db.Model):
    __tablename__ = "skin_profiles"

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(
        db.Integer,
        db.ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    skin_type = db.Column(db.String(50), nullable=True)
    skin_concerns = db.Column(db.JSON, nullable=True)
    allergies = db.Column(db.Text, nullable=True)
    environment = db.Column(db.String(50), nullable=True)
    goals = db.Column(db.JSON, nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    updated_at = db.Column(
        db.DateTime,
        default=datetime.utcnow,
        onupdate=datetime.utcnow,
        nullable=False,
    )

    user = db.relationship(
        "User",
        back_populates="skin_profiles",
    )

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "user_id": self.user_id,
            "skin_type": self.skin_type,
            "skin_concerns": self.skin_concerns,
            "allergies": self.allergies,
            "environment": self.environment,
            "goals": self.goals,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }
