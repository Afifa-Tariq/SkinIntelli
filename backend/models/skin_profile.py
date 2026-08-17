from datetime import datetime

from sqlalchemy.dialects.mysql import LONGBLOB

from extensions import db


class UserImage(db.Model):
    __tablename__ = "user_images"

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    session_id = db.Column(db.Integer, db.ForeignKey("skin_analysis_sessions.id", ondelete="SET NULL"), nullable=True, index=True)
    profile_id = db.Column(db.Integer, db.ForeignKey("skin_profiles.id", ondelete="SET NULL"), nullable=True, index=True)
    filename = db.Column(db.String(255), nullable=False)
    content_type = db.Column(db.String(100), nullable=True)
    source = db.Column(db.String(20), nullable=False, default="upload")
    # Plain LargeBinary compiles to MySQL BLOB (64KB max) with no length
    # given, which is far too small for a real photo. LONGBLOB matches what
    # the original hand-written schema intended (up to 4GB).
    image_bytes = db.Column(LONGBLOB, nullable=False)
    image_size = db.Column(db.Integer, nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)

    user = db.relationship("User", back_populates="user_images")
    session = db.relationship("SkinAnalysisSession", back_populates="images", foreign_keys=[session_id])
    profile = db.relationship("SkinProfile", back_populates="images", foreign_keys=[profile_id])

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "user_id": self.user_id,
            "session_id": self.session_id,
            "profile_id": self.profile_id,
            "filename": self.filename,
            "content_type": self.content_type,
            "source": self.source,
            "image_size": self.image_size,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }


class SkinAnalysisSession(db.Model):
    __tablename__ = "skin_analysis_sessions"

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    profile_id = db.Column(db.Integer, db.ForeignKey("skin_profiles.id", ondelete="SET NULL"), nullable=True, index=True)
    source = db.Column(db.String(32), nullable=False, default="manual")
    skin_type = db.Column(db.String(50), nullable=True)
    sensitivity_level = db.Column(db.String(30), nullable=True)
    confidence = db.Column(db.Integer, nullable=True, default=0)
    concerns = db.Column(db.JSON, nullable=True)
    detected_features = db.Column(db.JSON, nullable=True)
    analysis_notes = db.Column(db.Text, nullable=True)
    image_quality = db.Column(db.String(20), nullable=True, default="acceptable")
    raw_response = db.Column(db.JSON, nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)

    user = db.relationship("User", back_populates="analysis_sessions")
    profile = db.relationship("SkinProfile", back_populates="analysis_sessions", foreign_keys=[profile_id])
    images = db.relationship("UserImage", back_populates="session", foreign_keys="UserImage.session_id")

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "user_id": self.user_id,
            "profile_id": self.profile_id,
            "source": self.source,
            "skin_type": self.skin_type,
            "sensitivity_level": self.sensitivity_level,
            "confidence": self.confidence,
            "concerns": self.concerns,
            "detected_features": self.detected_features,
            "analysis_notes": self.analysis_notes,
            "image_quality": self.image_quality,
            "raw_response": self.raw_response,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }


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
    source = db.Column(db.String(32), nullable=False, default="manual")
    last_analysis_session_id = db.Column(db.Integer, db.ForeignKey("skin_analysis_sessions.id", ondelete="SET NULL"), nullable=True, index=True)
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
    analysis_sessions = db.relationship(
        "SkinAnalysisSession",
        back_populates="profile",
        foreign_keys="SkinAnalysisSession.profile_id",
    )
    images = db.relationship("UserImage", back_populates="profile", foreign_keys="UserImage.profile_id")

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "user_id": self.user_id,
            "skin_type": self.skin_type,
            "skin_concerns": self.skin_concerns,
            "allergies": self.allergies,
            "environment": self.environment,
            "goals": self.goals,
            "source": self.source,
            "last_analysis_session_id": self.last_analysis_session_id,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }
