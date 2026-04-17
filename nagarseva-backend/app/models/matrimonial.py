from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, Enum as SQLEnum, Text, Float
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base
import enum


class MaritalStatus(str, enum.Enum):
    SINGLE = "SINGLE"
    DIVORCED = "DIVORCED"
    WIDOWED = "WIDOWED"


class Gender(str, enum.Enum):
    MALE = "MALE"
    FEMALE = "FEMALE"
    OTHER = "OTHER"


class MatrimonialUserStatus(str, enum.Enum):
    ACTIVE = "ACTIVE"
    INACTIVE = "INACTIVE"
    BLOCKED = "BLOCKED"
    HIDDEN = "HIDDEN"


class MatrimonialUserType(str, enum.Enum):
    INDIVIDUAL = "INDIVIDUAL"
    AGENCY = "AGENCY"


class MatchStatus(str, enum.Enum):
    PENDING = "PENDING"
    ACCEPTED = "ACCEPTED"
    REJECTED = "REJECTED"
    EXPIRED = "EXPIRED"


class MessageStatus(str, enum.Enum):
    SENT = "SENT"
    DELIVERED = "DELIVERED"
    READ = "READ"


class MatrimonialUser(Base):
    __tablename__ = "matrimonial_users"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    first_name = Column(String(100), nullable=False)
    last_name = Column(String(100), nullable=False)
    email = Column(String(100), unique=True, nullable=False, index=True)
    phone = Column(String(15), nullable=False)
    gender = Column(SQLEnum(Gender), nullable=False)
    date_of_birth = Column(DateTime, nullable=False)
    marital_status = Column(SQLEnum(MaritalStatus), nullable=False)
    religion = Column(String(50), nullable=True)
    caste = Column(String(50), nullable=True)
    height = Column(String(10), nullable=True)  # e.g., "5'8\""
    occupation = Column(String(100), nullable=True)
    education = Column(String(100), nullable=True)
    location = Column(String(255), nullable=False)
    ward_id = Column(Integer, ForeignKey("wards.id"), nullable=True)
    profile_image = Column(String(255), nullable=True)
    bio = Column(Text, nullable=True)
    status = Column(SQLEnum(MatrimonialUserStatus), default=MatrimonialUserStatus.ACTIVE)
    is_verified = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    preferences = relationship("UserPreference", uselist=False, back_populates="user", cascade="all, delete-orphan")
    sent_matches = relationship("Match", foreign_keys="Match.sender_id", back_populates="sender")
    received_matches = relationship("Match", foreign_keys="Match.receiver_id", back_populates="receiver")
    sent_messages = relationship("MatrimonialMessage", foreign_keys="MatrimonialMessage.sender_id", back_populates="sender")
    received_messages = relationship("MatrimonialMessage", foreign_keys="MatrimonialMessage.receiver_id", back_populates="receiver")


class UserPreference(Base):
    __tablename__ = "user_preferences"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("matrimonial_users.id"), unique=True, nullable=False)
    min_age = Column(Integer, nullable=True)
    max_age = Column(Integer, nullable=True)
    preferred_height = Column(String(10), nullable=True)
    preferred_religion = Column(String(50), nullable=True)
    preferred_caste = Column(String(50), nullable=True)
    preferred_education = Column(String(100), nullable=True)
    preferred_occupation = Column(String(100), nullable=True)
    preferred_location = Column(String(255), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    user = relationship("MatrimonialUser", back_populates="preferences")


class MatrimonialAgency(Base):
    __tablename__ = "matrimonial_agencies"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    agency_name = Column(String(255), unique=True, nullable=False, index=True)
    contact_email = Column(String(100), nullable=False)
    phone = Column(String(15), nullable=False)
    owner_name = Column(String(100), nullable=False)
    registration_number = Column(String(100), unique=True, nullable=False)
    location = Column(String(255), nullable=False)
    ward_id = Column(Integer, ForeignKey("wards.id"), nullable=True)
    logo = Column(String(255), nullable=True)
    about = Column(Text, nullable=True)
    is_verified = Column(Boolean, default=False)
    status = Column(SQLEnum(MatrimonialUserStatus), default=MatrimonialUserStatus.ACTIVE)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    profiles = relationship("AgencyProfile", back_populates="agency", cascade="all, delete-orphan")
    sent_messages = relationship("MatrimonialMessage", foreign_keys="MatrimonialMessage.agency_id", back_populates="agency")


class AgencyProfile(Base):
    __tablename__ = "agency_profiles"

    id = Column(Integer, primary_key=True, index=True)
    agency_id = Column(Integer, ForeignKey("matrimonial_agencies.id"), nullable=False)
    matrimonial_user_id = Column(Integer, ForeignKey("matrimonial_users.id"), nullable=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    name = Column(String(100), nullable=False)
    description = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    agency = relationship("MatrimonialAgency", back_populates="profiles")


class Match(Base):
    __tablename__ = "matches"

    id = Column(Integer, primary_key=True, index=True)
    sender_id = Column(Integer, ForeignKey("matrimonial_users.id"), nullable=False)
    receiver_id = Column(Integer, ForeignKey("matrimonial_users.id"), nullable=False)
    agency_id = Column(Integer, ForeignKey("matrimonial_agencies.id"), nullable=True)
    status = Column(SQLEnum(MatchStatus), default=MatchStatus.PENDING)
    message = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    responded_at = Column(DateTime(timezone=True), nullable=True)

    # Relationships
    sender = relationship("MatrimonialUser", foreign_keys=[sender_id], back_populates="sent_matches")
    receiver = relationship("MatrimonialUser", foreign_keys=[receiver_id], back_populates="received_matches")


class MatrimonialMessage(Base):
    __tablename__ = "matrimonial_messages"

    id = Column(Integer, primary_key=True, index=True)
    sender_id = Column(Integer, ForeignKey("matrimonial_users.id"), nullable=True)
    receiver_id = Column(Integer, ForeignKey("matrimonial_users.id"), nullable=True)
    agency_id = Column(Integer, ForeignKey("matrimonial_agencies.id"), nullable=True)
    content = Column(Text, nullable=False)
    status = Column(SQLEnum(MessageStatus), default=MessageStatus.SENT)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    read_at = Column(DateTime(timezone=True), nullable=True)

    # Relationships
    sender = relationship("MatrimonialUser", foreign_keys=[sender_id], back_populates="sent_messages")
    receiver = relationship("MatrimonialUser", foreign_keys=[receiver_id], back_populates="received_messages")
    agency = relationship("MatrimonialAgency", back_populates="sent_messages")
