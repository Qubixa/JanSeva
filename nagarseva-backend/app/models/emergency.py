from datetime import datetime, date
from typing import Optional
from pydantic import BaseModel
from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Enum as SQLEnum
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base
import enum


# app/schemas/emergency.py

class EmergencyServiceType(str, enum.Enum):
    HOSPITAL = "Hospital"
    SCHOOL = "School"
    FIRE = "Fire Brigade"
    LIBRARY = "Library"
    SHELTER = "Night Shelter"
    SENIOR_CITIZEN = "Senior Citizen Centre"


class EmergencyServiceBase(BaseModel):
    name: str
    type: str
    phone: str
    alternate_phone: Optional[str] = None
    address: Optional[str] = None
    is_24x7: str = 'N'

class EmergencyServiceResponse(EmergencyServiceBase):
    id: int
    is_active: str
    created_at: datetime
    
    class Config:
        from_attributes = True


class EmergencyService(Base):
    __tablename__ = "emergency_services"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(200), nullable=False)
    type = Column(String(50), nullable=False)
    phone = Column(String(20), nullable=True)
    alternate_phone = Column(String(20), nullable=True)
    email = Column(String(100), nullable=True)
    address = Column(String(500), nullable=True)
    google_maps_link = Column(String(500), nullable=True)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    ward_id = Column(Integer, ForeignKey("wards.id"), nullable=True)
    category = Column(String(100), nullable=True)  # Custom category field
    is_citywide = Column(String(1), default="N")  # Y for citywide services
    is_active = Column(String(1), default="Y")
    is_24x7 = Column(String(1), default="N")  # Added this line
    created_by = Column(Integer, ForeignKey("users.id"), nullable=True)  # Track who created it
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    ward = relationship("Ward", back_populates="emergency_services")
    creator = relationship("User", foreign_keys=[created_by])
