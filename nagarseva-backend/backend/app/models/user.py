from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, Enum as SQLEnum
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base
import enum


class UserRole(str, enum.Enum):
    CITIZEN = "CITIZEN"
    FIELD_OFFICER = "FIELD_OFFICER"
    WARD_ADMIN = "WARD_ADMIN"
    SUPER_ADMIN = "SUPER_ADMIN"


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    mobile = Column(String(15), unique=True, index=True, nullable=False)
    email = Column(String(100), nullable=True)
    password_hash = Column(String(255), nullable=True)
    role = Column(SQLEnum(UserRole), default=UserRole.CITIZEN)
    ward_id = Column(Integer, ForeignKey("wards.id"), nullable=False)
    address = Column(String(500), nullable=False)
    profile_image = Column(String(255), nullable=True)
    is_active = Column(Boolean, default=True)
    is_verified = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    ward = relationship("Ward", back_populates="users")
    complaints = relationship("Complaint", back_populates="user", foreign_keys="Complaint.user_id")
    assigned_complaints = relationship("Complaint", back_populates="assigned_officer", foreign_keys="Complaint.assigned_officer_id")
    complaint_logs = relationship("ComplaintLog", back_populates="action_by_user")
    notifications = relationship("UserNotification", back_populates="user")
