from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Enum as SQLEnum
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base
import enum


class ContactType(str, enum.Enum):
    WARD_OFFICER = "WARD_OFFICER"
    CORPORATOR = "CORPORATOR"
    COMMISSIONER = "COMMISSIONER"
    MLA = "MLA"
    MP = "MP"
    OTHER = "OTHER"


class Contact(Base):
    __tablename__ = "contacts"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(200), nullable=False)
    designation = Column(String(200), nullable=False)
    department = Column(String(200), nullable=False)
    phone = Column(String(20), nullable=False)
    email = Column(String(100), nullable=True)
    office_address = Column(String(500), nullable=True)
    is_active = Column(String(1), default='Y')
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    


