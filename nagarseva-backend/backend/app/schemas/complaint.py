# app/schemas/complaint.py

from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


class ComplaintCategorySchema(BaseModel):
    """Schema for complaint categories"""
    id: int
    code: str
    name: str
    description: Optional[str] = None
    icon: Optional[str] = None
    department: Optional[str] = None
    is_active: str = 'Y'
    
    class Config:
        from_attributes = True


class ComplaintCreate(BaseModel):
    """Create complaint request"""
    category: str  # Changed from Enum to str (category code)
    title: str = Field(..., min_length=5, max_length=200)
    description: str = Field(..., min_length=20)
    address: str = Field(..., min_length=5)
    latitude: Optional[str] = None
    longitude: Optional[str] = None
    priority: str = Field(default='MEDIUM')  # Changed from Enum to str
    ward_id: int


class ComplaintUpdate(BaseModel):
    """Update complaint (admin only)"""
    status: Optional[str] = None  # Changed from Enum to str
    priority: Optional[str] = None  # Changed from Enum to str
    assigned_officer_id: Optional[int] = None
    resolution_remarks: Optional[str] = None


class ComplaintFeedback(BaseModel):
    """User feedback after resolution"""
    rating: int = Field(..., ge=1, le=5)
    feedback: Optional[str] = None


class ComplaintMediaResponse(BaseModel):
    id: int
    file_path: str
    file_type: str
    file_name: Optional[str] = None
    uploaded_at: datetime
    
    class Config:
        from_attributes = True


class ComplaintLogResponse(BaseModel):
    id: int
    action: str
    old_status: Optional[str] = None
    new_status: Optional[str] = None
    remarks: Optional[str] = None
    action_by_name: Optional[str] = None
    created_at: datetime
    
    class Config:
        from_attributes = True


class ComplaintResponse(BaseModel):
    id: int
    complaint_number: str
    category: str
    title: str
    description: str
    address: str
    latitude: Optional[str] = None
    longitude: Optional[str] = None
    status: str  # Changed from Enum to str
    priority: str  # Changed from Enum to str
    resolution_remarks: Optional[str] = None
    feedback: Optional[str] = None  # NEW
    rating: Optional[int] = None  # NEW
    user_name: Optional[str] = None
    user_mobile: Optional[str] = None
    ward_name: Optional[str] = None
    assigned_officer_name: Optional[str] = None
    category_info: Optional[ComplaintCategorySchema] = None  # NEW
    media: List[ComplaintMediaResponse] = []
    created_at: datetime
    updated_at: Optional[datetime] = None
    resolved_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True