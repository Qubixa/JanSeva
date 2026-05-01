# app/models/notification.py
from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey, Enum as SQLEnum
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base
from app.models.user import UserRole
import enum


class NotificationType(str, enum.Enum):
    NOTICE = "NOTICE"
    ALERT = "ALERT"
    EVENT = "EVENT"
    CIRCULAR = "CIRCULAR"
    UPDATE = "UPDATE"


class Notification(Base):
    __tablename__ = "notifications"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(500), nullable=False)  # Increased from 300
    message = Column(Text, nullable=False)  # Text has no length limit in most DBs
    notification_type = Column(SQLEnum(NotificationType), default=NotificationType.NOTICE)
    ward_id = Column(Integer, ForeignKey("wards.id"), nullable=True)
    target_role = Column(SQLEnum(UserRole), nullable=True)
    is_active = Column(String(1), default="Y")
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    expires_at = Column(DateTime(timezone=True), nullable=True)

    # Relationships
    ward = relationship("Ward", back_populates="notifications")
    user_notifications = relationship("UserNotification", back_populates="notification")


class UserNotification(Base):
    __tablename__ = "user_notifications"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    notification_id = Column(Integer, ForeignKey("notifications.id"), nullable=False)
    is_read = Column(String(1), default="N")
    read_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    user = relationship("User", back_populates="notifications")
    notification = relationship("Notification", back_populates="user_notifications")
