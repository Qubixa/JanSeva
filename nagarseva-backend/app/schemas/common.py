from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime, time
from app.models.emergency import EmergencyServiceType
from app.models.scheme import SchemeCategory
from app.models.contact import ContactType
from app.models.notification import NotificationType
from app.models.transport import TransportType
from app.models.user import UserRole


# Ward Schemas
class WardResponse(BaseModel):
    id: int
    ward_number: int
    name: str
    city: str
    state: str
    description: Optional[str]

    class Config:
        from_attributes = True


class WardCreateRequest(BaseModel):
    ward_number: int = Field(..., gt=0, le=500)
    name: str = Field(..., min_length=2, max_length=100)
    city: str = Field(..., min_length=2, max_length=100)
    state: str = Field(..., min_length=2, max_length=100)
    description: Optional[str] = None


# Emergency Service Schemas
class EmergencyServiceResponse(BaseModel):
    id: int
    name: str
    type: EmergencyServiceType
    phone: str
    alternate_phone: Optional[str]
    address: Optional[str]
    latitude: Optional[float]
    longitude: Optional[float]
    ward_id: Optional[int]
    is_citywide: str

    class Config:
        from_attributes = True


class EmergencyServiceCreateRequest(BaseModel):
    name: str = Field(..., min_length=2, max_length=200)
    type: EmergencyServiceType
    phone: str = Field(..., min_length=10, max_length=20)
    alternate_phone: Optional[str] = None
    address: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    ward_id: Optional[int] = None
    is_citywide: str = "N"


# Scheme Schemas
class SchemeResponse(BaseModel):
    id: int
    title: str
    category: SchemeCategory
    description: str
    eligibility: Optional[str]
    required_documents: Optional[str]
    application_steps: Optional[str]
    official_link: Optional[str]
    start_date: Optional[datetime]
    end_date: Optional[datetime]
    is_active: str

    class Config:
        from_attributes = True


class SchemeCreateRequest(BaseModel):
    title: str = Field(..., min_length=5, max_length=300)
    category: SchemeCategory
    description: str = Field(..., min_length=20)
    eligibility: Optional[str] = None
    required_documents: Optional[str] = None
    application_steps: Optional[str] = None
    official_link: Optional[str] = None
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None


# Contact Schemas
class ContactResponse(BaseModel):
    id: int
    name: str
    designation: str
    contact_type: ContactType
    phone: str
    alternate_phone: Optional[str]
    email: Optional[str]
    photo: Optional[str]
    office_address: Optional[str]
    ward_id: Optional[int]
    is_citywide: str
    display_order: int

    class Config:
        from_attributes = True


class ContactCreateRequest(BaseModel):
    name: str = Field(..., min_length=2, max_length=200)
    designation: str = Field(..., min_length=2, max_length=200)
    contact_type: ContactType
    phone: str = Field(..., min_length=10, max_length=20)
    alternate_phone: Optional[str] = None
    email: Optional[str] = None
    office_address: Optional[str] = None
    ward_id: Optional[int] = None
    is_citywide: str = "N"
    display_order: int = 0


# Notification Schemas
class NotificationResponse(BaseModel):
    id: int
    title: str
    message: str
    notification_type: NotificationType
    ward_id: Optional[int]
    target_role: Optional[UserRole]
    is_active: str
    created_at: datetime
    expires_at: Optional[datetime]
    is_read: str = "N"

    class Config:
        from_attributes = True


class NotificationCreateRequest(BaseModel):
    title: str = Field(..., min_length=5, max_length=300)
    message: str = Field(..., min_length=10)
    notification_type: NotificationType = NotificationType.NOTICE
    ward_id: Optional[int] = None
    target_role: Optional[UserRole] = None
    expires_at: Optional[datetime] = None


# Transport Schemas
class TransportResponse(BaseModel):
    id: int
    transport_type: TransportType
    name: str
    route_number: Optional[str]
    source: str
    destination: str
    via_stops: Optional[str]
    departure_time: Optional[time]
    arrival_time: Optional[time]
    frequency: Optional[str]
    fare: Optional[str]
    map_link: Optional[str]

    class Config:
        from_attributes = True


# Job Vacancy Schemas
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
    created_at: datetime

    class Config:
        from_attributes = True


# RTI Schemas
class RTIInfoResponse(BaseModel):
    id: int
    title: str
    description: Optional[str]
    content: Optional[str]
    form_link: Optional[str]
    portal_link: Optional[str]
    display_order: int

    class Config:
        from_attributes = True


# Generic Response
class MessageResponse(BaseModel):
    message: str
    success: bool = True
