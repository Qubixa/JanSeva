from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, Field
from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey, Enum as SQLEnum
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base
import enum



class Complaint(Base):
    __tablename__ = "complaints"

    id = Column(Integer, primary_key=True, index=True)
    complaint_number = Column(String(20), unique=True, nullable=False, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    ward_id = Column(Integer, ForeignKey("wards.id"), nullable=False)
    
    # Changed from Enum to String to match seed data structure
    category = Column(String(50), nullable=False)  # Links to complaint_categories.code
    
    title = Column(String(200), nullable=False)
    description = Column(Text, nullable=False)
    address = Column(String(500), nullable=False)
    latitude = Column(String(20), nullable=True)
    longitude = Column(String(20), nullable=True)
    
    # Changed from Enum to String
    status = Column(String(20), default='PENDING')  # PENDING, ASSIGNED, IN_PROGRESS, RESOLVED, REJECTED, CLOSED
    priority = Column(String(20), default='MEDIUM')  # LOW, MEDIUM, HIGH, URGENT
    
    assigned_officer_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    resolution_remarks = Column(Text, nullable=True)
    
    # NEW FIELDS based on seed data
    feedback = Column(Text, nullable=True)  # User feedback after resolution
    rating = Column(Integer, nullable=True)  # 1-5 star rating
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    resolved_at = Column(DateTime(timezone=True), nullable=True)

    # Relationships
    user = relationship("User", back_populates="complaints", foreign_keys=[user_id])
    ward = relationship("Ward", back_populates="complaints")
    assigned_officer = relationship("User", back_populates="assigned_complaints", foreign_keys=[assigned_officer_id])
    media = relationship("ComplaintMedia", back_populates="complaint", cascade="all, delete-orphan")
    logs = relationship("ComplaintLog", back_populates="complaint", cascade="all, delete-orphan")
    
    # NEW: Link to category table
    category_info = relationship("ComplaintCategory", foreign_keys=[category], primaryjoin="Complaint.category == ComplaintCategory.code")


# NEW TABLE based on seed data
class ComplaintCategory(Base):
    __tablename__ = "complaint_categories"

    id = Column(Integer, primary_key=True, index=True)
    code = Column(String(50), unique=True, nullable=False, index=True)  # e.g., 'road_potholes', 'water_supply'
    name = Column(String(100), nullable=False)  # Display name
    description = Column(Text, nullable=True)
    icon = Column(String(50), nullable=True)  # Icon name for mobile app
    department = Column(String(100), nullable=True)  # Responsible department
    is_active = Column(String(1), default='Y')
    created_at = Column(DateTime(timezone=True), server_default=func.now())


class ComplaintMedia(Base):
    __tablename__ = "complaint_media"

    id = Column(Integer, primary_key=True, index=True)
    complaint_id = Column(Integer, ForeignKey("complaints.id"), nullable=False)
    file_path = Column(String(500), nullable=False)
    file_type = Column(String(20), nullable=False)  # IMAGE or VIDEO
    file_name = Column(String(255), nullable=True)
    file_size = Column(Integer, nullable=True)
    uploaded_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    complaint = relationship("Complaint", back_populates="media")


class ComplaintLog(Base):
    __tablename__ = "complaint_logs"

    id = Column(Integer, primary_key=True, index=True)
    complaint_id = Column(Integer, ForeignKey("complaints.id"), nullable=False)
    action_by_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    action = Column(String(50), nullable=False)
    
    # Changed from Enum to String
    old_status = Column(String(20), nullable=True)
    new_status = Column(String(20), nullable=True)
    
    remarks = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    complaint = relationship("Complaint", back_populates="logs")
    action_by_user = relationship("User", back_populates="complaint_logs")