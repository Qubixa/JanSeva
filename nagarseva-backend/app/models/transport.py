from sqlalchemy import Column, Integer, String, Text, DateTime, Time, Enum as SQLEnum
from sqlalchemy.sql import func
from app.core.database import Base
import enum


class TransportType(str, enum.Enum):
    RAILWAY = "RAILWAY"
    BUS = "BUS"
    METRO = "METRO"
    AUTO = "AUTO"


class Transport(Base):
    __tablename__ = "transports"

    id = Column(Integer, primary_key=True, index=True)
    transport_type = Column(SQLEnum(TransportType), nullable=False)
    name = Column(String(200), nullable=False)  # Route name or train name
    route_number = Column(String(50), nullable=True)
    source = Column(String(200), nullable=False)
    destination = Column(String(200), nullable=False)
    via_stops = Column(Text, nullable=True)  # JSON array of stops
    departure_time = Column(Time, nullable=True)
    arrival_time = Column(Time, nullable=True)
    frequency = Column(String(100), nullable=True)  # e.g., "Every 15 mins"
    fare = Column(String(100), nullable=True)
    map_link = Column(String(500), nullable=True)
    is_active = Column(String(1), default="Y")
    created_at = Column(DateTime(timezone=True), server_default=func.now())


class JobVacancy(Base):
    __tablename__ = "job_vacancies"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(300), nullable=False)
    organization = Column(String(200), nullable=False)
    job_type = Column(String(50), nullable=True)  # Government, Private, Contract
    location = Column(String(200), nullable=True)
    description = Column(Text, nullable=True)
    eligibility = Column(Text, nullable=True)
    salary_range = Column(String(100), nullable=True)
    application_link = Column(String(500), nullable=True)
    last_date = Column(DateTime(timezone=True), nullable=True)
    is_active = Column(String(1), default="Y")
    created_at = Column(DateTime(timezone=True), server_default=func.now())


class RTIInfo(Base):
    __tablename__ = "rti_info"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(300), nullable=False)
    description = Column(Text, nullable=True)
    content = Column(Text, nullable=True)  # Detailed content or HTML
    form_link = Column(String(500), nullable=True)
    portal_link = Column(String(500), nullable=True)
    display_order = Column(Integer, default=0)
    is_active = Column(String(1), default="Y")
    created_at = Column(DateTime(timezone=True), server_default=func.now())
