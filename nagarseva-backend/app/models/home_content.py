from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, Enum as SQLEnum, Text, JSON
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base
import enum


class ContentType(str, enum.Enum):
    BANNER = "BANNER"
    SERVICE = "SERVICE"
    ANNOUNCEMENT = "ANNOUNCEMENT"
    WIDGET = "WIDGET"
    LINK = "LINK"
    ALERT = "ALERT"


class HomeContent(Base):
    __tablename__ = "home_content"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(255), nullable=False)
    content_type = Column(SQLEnum(ContentType), nullable=False, index=True)
    description = Column(Text, nullable=True)
    image_url = Column(String(500), nullable=True)
    redirect_url = Column(String(500), nullable=True)
    metadata = Column(JSON, default=dict)  # Extra fields like color, icon, etc.
    display_order = Column(Integer, default=0)
    is_active = Column(Boolean, default=True)
    start_date = Column(DateTime, nullable=True)
    end_date = Column(DateTime, nullable=True)
    ward_id = Column(Integer, ForeignKey("wards.id"), nullable=True)  # NULL means global
    created_by = Column(Integer, ForeignKey("users.id"), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    creator = relationship("User", foreign_keys=[created_by])
