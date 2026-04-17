from sqlalchemy import Column, Integer, String, Text, DateTime, Enum as SQLEnum
from sqlalchemy.sql import func
from app.core.database import Base
import enum


class SchemeCategory(str, enum.Enum):
    HEALTH = "HEALTH"
    EDUCATION = "EDUCATION"
    WOMEN = "WOMEN"
    SENIOR_CITIZEN = "SENIOR_CITIZEN"
    YOUTH = "YOUTH"
    FARMER = "FARMER"
    HOUSING = "HOUSING"
    EMPLOYMENT = "EMPLOYMENT"
    OTHER = "OTHER"


class Scheme(Base):
    __tablename__ = "government_schemes"  # Changed table name
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(300), nullable=False)  # Changed from title
    description = Column(Text, nullable=False)
    category = Column(String(50), nullable=False)
    eligibility = Column(Text, nullable=True)
    benefits = Column(Text, nullable=True)  # NEW FIELD
    documents = Column(Text, nullable=True)  # Changed from required_documents (JSON array)
    application_url = Column(String(500), nullable=True)  # Changed from official_link
    deadline = Column(DateTime(timezone=True), nullable=True)  # Changed from end_date
    is_active = Column(String(1), default='Y')
    created_at = Column(DateTime(timezone=True), server_default=func.now())
