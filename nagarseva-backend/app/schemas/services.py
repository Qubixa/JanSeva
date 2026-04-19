from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


# Emergency Services
class EmergencyServiceBase(BaseModel):
    name: str = Field(..., min_length=2, max_length=200)
    type: str
    phone: Optional[str] = Field(None, max_length=20)
    alternate_phone: Optional[str] = Field(None, max_length=20)
    email: Optional[str] = Field(None, max_length=100)
    address: Optional[str] = Field(None, max_length=500)
    google_maps_link: Optional[str] = Field(None, max_length=500)
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    category: Optional[str] = Field(None, max_length=100)
    is_citywide: bool = False


class EmergencyServiceCreate(EmergencyServiceBase):
    ward_id: Optional[int] = None


class EmergencyServiceUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=2, max_length=200)
    type: Optional[str] = None
    phone: Optional[str] = Field(None, max_length=20)
    alternate_phone: Optional[str] = Field(None, max_length=20)
    email: Optional[str] = Field(None, max_length=100)
    address: Optional[str] = Field(None, max_length=500)
    google_maps_link: Optional[str] = Field(None, max_length=500)
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    category: Optional[str] = Field(None, max_length=100)
    is_citywide: Optional[bool] = None
    is_active: Optional[bool] = None


class EmergencyServiceResponse(EmergencyServiceBase):
    id: int
    ward_id: Optional[int]
    is_active: bool
    created_at: datetime
    updated_at: Optional[datetime]

    class Config:
        from_attributes = True


# Government Schemes
# Government Schemes
class SchemeCreate(BaseModel):
    title: str = Field(..., min_length=5, max_length=300)
    category: str
    description: str
    eligibility: Optional[str] = None
    benefits: Optional[str] = None          # ← ADD THIS
    required_documents: Optional[str] = None
    application_steps: Optional[str] = None
    official_link: Optional[str] = None
    deadline: Optional[datetime] = None     # ← ADD THIS


class SchemeUpdate(BaseModel):
    title: Optional[str] = Field(None, min_length=5, max_length=300)
    category: Optional[str] = None
    description: Optional[str] = None
    eligibility: Optional[str] = None
    benefits: Optional[str] = None          # ← ADD THIS
    required_documents: Optional[str] = None
    application_steps: Optional[str] = None
    official_link: Optional[str] = None
    is_active: Optional[bool] = None


class SchemeResponse(BaseModel):
    id: int
    title: str
    category: str
    description: str
    eligibility: Optional[str]
    benefits: Optional[str]                 # ← ADD THIS
    required_documents: Optional[str]
    application_steps: Optional[str]
    official_link: Optional[str]
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True


# Job Vacancies
class JobVacancyCreate(BaseModel):
    title: str = Field(..., min_length=5, max_length=300)
    organization: str = Field(..., min_length=2, max_length=200)
    job_type: Optional[str] = None
    location: Optional[str] = None
    description: Optional[str] = None
    eligibility: Optional[str] = None
    salary_range: Optional[str] = None
    application_link: Optional[str] = None
    last_date: Optional[datetime] = None


class JobVacancyUpdate(BaseModel):
    title: Optional[str] = Field(None, min_length=5, max_length=300)
    organization: Optional[str] = Field(None, min_length=2, max_length=200)
    job_type: Optional[str] = None
    location: Optional[str] = None
    description: Optional[str] = None
    eligibility: Optional[str] = None
    salary_range: Optional[str] = None
    application_link: Optional[str] = None
    last_date: Optional[datetime] = None
    is_active: Optional[bool] = None


class JobVacancyResponse(BaseModel):
    id: int
    title: str
    organization: str
    job_type: Optional[str]
    location: Optional[str]
    description: Optional[str]
    eligibility: Optional[str]
    salary_range: Optional[str]
    application_link: Optional[str]
    last_date: Optional[datetime]
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True


# RTI Information
class RTIInfoCreate(BaseModel):
    title: str = Field(..., min_length=5, max_length=300)
    description: Optional[str] = None
    content: Optional[str] = None
    form_link: Optional[str] = None
    portal_link: Optional[str] = None


class RTIInfoUpdate(BaseModel):
    title: Optional[str] = Field(None, min_length=5, max_length=300)
    description: Optional[str] = None
    content: Optional[str] = None
    form_link: Optional[str] = None
    portal_link: Optional[str] = None
    display_order: Optional[int] = None
    is_active: Optional[bool] = None


class RTIInfoResponse(BaseModel):
    id: int
    title: str
    description: Optional[str]
    content: Optional[str]
    form_link: Optional[str]
    portal_link: Optional[str]
    display_order: int
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True


# Notices & Announcements
class NoticeCreate(BaseModel):
    title: str = Field(..., min_length=1, max_length=500)  # Increased max_length
    message: str = Field(..., min_length=1)  # No max_length for Text field
    notice_type: str = "NOTICE"
    ward_id: Optional[int] = None
    target_role: Optional[str] = None
    expires_at: Optional[datetime] = None


class NoticeUpdate(BaseModel):
    title: Optional[str] = Field(None, min_length=1, max_length=500)
    message: Optional[str] = None
    notice_type: Optional[str] = None
    ward_id: Optional[int] = None
    target_role: Optional[str] = None
    expires_at: Optional[datetime] = None
    is_active: Optional[bool] = None


class NoticeResponse(BaseModel):
    id: int
    title: str
    message: str
    notice_type: str
    ward_id: Optional[int]
    target_role: Optional[str]
    is_active: bool
    created_at: datetime
    expires_at: Optional[datetime]

    class Config:
        from_attributes = True


# Transport
class TransportCreate(BaseModel):
    transport_type: str  # RAILWAY, BUS, METRO, AUTO
    name: str = Field(..., min_length=2, max_length=200)
    route_number: Optional[str] = None
    source: str
    destination: str
    via_stops: Optional[str] = None
    departure_time: Optional[str] = None
    arrival_time: Optional[str] = None
    frequency: Optional[str] = None
    fare: Optional[str] = None
    map_link: Optional[str] = None


class TransportUpdate(BaseModel):
    transport_type: Optional[str] = None
    name: Optional[str] = Field(None, min_length=2, max_length=200)
    route_number: Optional[str] = None
    source: Optional[str] = None
    destination: Optional[str] = None
    via_stops: Optional[str] = None
    departure_time: Optional[str] = None
    arrival_time: Optional[str] = None
    frequency: Optional[str] = None
    fare: Optional[str] = None
    map_link: Optional[str] = None
    is_active: Optional[bool] = None


class TransportResponse(BaseModel):
    id: int
    transport_type: str
    name: str
    route_number: Optional[str]
    source: str
    destination: str
    via_stops: Optional[str]
    departure_time: Optional[str]
    arrival_time: Optional[str]
    frequency: Optional[str]
    fare: Optional[str]
    map_link: Optional[str]
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True
