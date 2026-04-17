from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, Enum as SQLEnum, Text, JSON
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base
import enum


class FieldUserStatus(str, enum.Enum):
    ACTIVE = "ACTIVE"
    INACTIVE = "INACTIVE"
    SUSPENDED = "SUSPENDED"


class WardAdminStatus(str, enum.Enum):
    ACTIVE = "ACTIVE"
    INACTIVE = "INACTIVE"
    SUSPENDED = "SUSPENDED"


class FieldUser(Base):
    __tablename__ = "field_users"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True, nullable=False)
    assignment_area = Column(String(255), nullable=False)
    region = Column(String(100), nullable=True)
    ward_ids = Column(JSON, default=list)  # List of ward IDs assigned
    status = Column(SQLEnum(FieldUserStatus), default=FieldUserStatus.ACTIVE)
    contact_info = Column(String(15), nullable=False)
    assigned_by = Column(Integer, ForeignKey("users.id"), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    user = relationship("User", foreign_keys=[user_id])
    admin = relationship("User", foreign_keys=[assigned_by])


class WardAdmin(Base):
    __tablename__ = "ward_admins"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True, nullable=False)
    ward_id = Column(Integer, ForeignKey("wards.id"), nullable=False)
    status = Column(SQLEnum(WardAdminStatus), default=WardAdminStatus.ACTIVE)
    phone = Column(String(15), nullable=False)
    jurisdiction_area = Column(String(500), nullable=True)
    assigned_by = Column(Integer, ForeignKey("users.id"), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    user = relationship("User", foreign_keys=[user_id])
    ward = relationship("Ward")
    admin = relationship("User", foreign_keys=[assigned_by])


class Role(Base):
    __tablename__ = "roles"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), unique=True, nullable=False)
    description = Column(Text, nullable=True)
    permissions = Column(JSON, default=dict)  # Key: permission_name, Value: boolean
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
