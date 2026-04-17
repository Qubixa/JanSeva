from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import Optional, List
from datetime import datetime

from app.core.database import get_db
from app.core.security import get_current_user, require_role, get_password_hash
from app.models.user import User, UserRole
from app.models.admin import FieldUser, WardAdmin, Role, FieldUserStatus, WardAdminStatus
from app.models.home_content import HomeContent, ContentType
from app.models.ward import Ward
from app.models.matrimonial import MatrimonialUser, MatrimonialAgency
from pydantic import BaseModel, Field, EmailStr
from typing import Optional, List, Dict


router = APIRouter(prefix="/admin", tags=["Admin Extended"])


# Pydantic Models
class FieldUserRequest(BaseModel):
    user_id: int
    assignment_area: str = Field(..., min_length=2, max_length=255)
    region: Optional[str] = None
    ward_ids: Optional[List[int]] = None
    contact_info: str = Field(..., min_length=10, max_length=15)


class FieldUserResponse(BaseModel):
    id: int
    user_id: int
    assignment_area: str
    region: Optional[str]
    ward_ids: List[int]
    status: FieldUserStatus
    contact_info: str
    created_at: datetime

    class Config:
        from_attributes = True


class WardAdminRequest(BaseModel):
    user_id: int
    ward_id: int
    phone: str = Field(..., min_length=10, max_length=15)
    jurisdiction_area: Optional[str] = None


class WardAdminResponse(BaseModel):
    id: int
    user_id: int
    ward_id: int
    phone: str
    jurisdiction_area: Optional[str]
    status: WardAdminStatus
    created_at: datetime

    class Config:
        from_attributes = True


class RoleRequest(BaseModel):
    name: str = Field(..., min_length=2, max_length=100)
    description: Optional[str] = None
    permissions: Dict[str, bool] = {}


class RoleResponse(BaseModel):
    id: int
    name: str
    description: Optional[str]
    permissions: Dict[str, bool]
    created_at: datetime

    class Config:
        from_attributes = True


class HomeContentRequest(BaseModel):
    title: str = Field(..., min_length=2, max_length=255)
    content_type: ContentType
    description: Optional[str] = None
    image_url: Optional[str] = None
    redirect_url: Optional[str] = None
    metadata: Optional[Dict] = None
    display_order: int = 0
    is_active: bool = True
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    ward_id: Optional[int] = None


class HomeContentResponse(BaseModel):
    id: int
    title: str
    content_type: ContentType
    description: Optional[str]
    image_url: Optional[str]
    redirect_url: Optional[str]
    metadata: Optional[Dict]
    display_order: int
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True


# Field Users Management
@router.get("/field-users", response_model=List[FieldUserResponse])
async def get_field_users(
    region: Optional[str] = None,
    status_filter: Optional[FieldUserStatus] = None,
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    """Get all field users"""
    query = db.query(FieldUser)
    
    if region:
        query = query.filter(FieldUser.region == region)
    
    if status_filter:
        query = query.filter(FieldUser.status == status_filter)
    
    field_users = query.all()
    return [FieldUserResponse.from_attributes(fu) for fu in field_users]


@router.post("/field-users", response_model=FieldUserResponse)
async def create_field_user(
    request: FieldUserRequest,
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    """Create a new field user"""
    # Check if user exists
    user = db.query(User).filter(User.id == request.user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Check if already a field user
    existing = db.query(FieldUser).filter(FieldUser.user_id == request.user_id).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User is already a field user"
        )
    
    field_user = FieldUser(
        user_id=request.user_id,
        assignment_area=request.assignment_area,
        region=request.region,
        ward_ids=request.ward_ids or [],
        contact_info=request.contact_info,
        assigned_by=current_user.id,
        status=FieldUserStatus.ACTIVE
    )
    db.add(field_user)
    db.commit()
    db.refresh(field_user)
    
    return FieldUserResponse.from_attributes(field_user)


@router.put("/field-users/{field_user_id}", response_model=FieldUserResponse)
async def update_field_user(
    field_user_id: int,
    request: FieldUserRequest,
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    """Update field user"""
    field_user = db.query(FieldUser).filter(FieldUser.id == field_user_id).first()
    if not field_user:
        raise HTTPException(status_code=404, detail="Field user not found")
    
    field_user.assignment_area = request.assignment_area
    field_user.region = request.region
    field_user.ward_ids = request.ward_ids or []
    field_user.contact_info = request.contact_info
    
    db.commit()
    db.refresh(field_user)
    
    return FieldUserResponse.from_attributes(field_user)


# Ward Admins Management
@router.get("/ward-admins", response_model=List[WardAdminResponse])
async def get_ward_admins(
    ward_id: Optional[int] = None,
    status_filter: Optional[WardAdminStatus] = None,
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    """Get all ward admins"""
    query = db.query(WardAdmin)
    
    if ward_id:
        query = query.filter(WardAdmin.ward_id == ward_id)
    
    if status_filter:
        query = query.filter(WardAdmin.status == status_filter)
    
    ward_admins = query.all()
    return [WardAdminResponse.from_attributes(wa) for wa in ward_admins]


@router.post("/ward-admins", response_model=WardAdminResponse)
async def create_ward_admin(
    request: WardAdminRequest,
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    """Create a new ward admin"""
    # Check if user exists
    user = db.query(User).filter(User.id == request.user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Check if ward exists
    ward = db.query(Ward).filter(Ward.id == request.ward_id).first()
    if not ward:
        raise HTTPException(status_code=404, detail="Ward not found")
    
    # Check if already a ward admin
    existing = db.query(WardAdmin).filter(WardAdmin.user_id == request.user_id).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User is already a ward admin"
        )
    
    ward_admin = WardAdmin(
        user_id=request.user_id,
        ward_id=request.ward_id,
        phone=request.phone,
        jurisdiction_area=request.jurisdiction_area,
        assigned_by=current_user.id,
        status=WardAdminStatus.ACTIVE
    )
    db.add(ward_admin)
    db.commit()
    db.refresh(ward_admin)
    
    return WardAdminResponse.from_attributes(ward_admin)


# Home Content Management
@router.get("/home-content", response_model=List[HomeContentResponse])
async def get_home_content(
    content_type: Optional[ContentType] = None,
    ward_id: Optional[int] = None,
    is_active: Optional[bool] = None,
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN, UserRole.WARD_ADMIN])),
    db: Session = Depends(get_db)
):
    """Get home screen content"""
    query = db.query(HomeContent)
    
    if content_type:
        query = query.filter(HomeContent.content_type == content_type)
    
    if ward_id is not None:
        query = query.filter((HomeContent.ward_id == ward_id) | (HomeContent.ward_id == None))
    
    if is_active is not None:
        query = query.filter(HomeContent.is_active == is_active)
    
    content = query.order_by(HomeContent.display_order).all()
    return [HomeContentResponse.from_attributes(c) for c in content]


@router.post("/home-content", response_model=HomeContentResponse)
async def create_home_content(
    request: HomeContentRequest,
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    """Create home screen content"""
    content = HomeContent(
        title=request.title,
        content_type=request.content_type,
        description=request.description,
        image_url=request.image_url,
        redirect_url=request.redirect_url,
        metadata=request.metadata or {},
        display_order=request.display_order,
        is_active=request.is_active,
        start_date=request.start_date,
        end_date=request.end_date,
        ward_id=request.ward_id,
        created_by=current_user.id
    )
    db.add(content)
    db.commit()
    db.refresh(content)
    
    return HomeContentResponse.from_attributes(content)


@router.put("/home-content/{content_id}", response_model=HomeContentResponse)
async def update_home_content(
    content_id: int,
    request: HomeContentRequest,
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    """Update home screen content"""
    content = db.query(HomeContent).filter(HomeContent.id == content_id).first()
    if not content:
        raise HTTPException(status_code=404, detail="Content not found")
    
    content.title = request.title
    content.content_type = request.content_type
    content.description = request.description
    content.image_url = request.image_url
    content.redirect_url = request.redirect_url
    content.metadata = request.metadata or {}
    content.display_order = request.display_order
    content.is_active = request.is_active
    content.start_date = request.start_date
    content.end_date = request.end_date
    content.ward_id = request.ward_id
    
    db.commit()
    db.refresh(content)
    
    return HomeContentResponse.from_attributes(content)


@router.delete("/home-content/{content_id}")
async def delete_home_content(
    content_id: int,
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    """Delete home screen content"""
    content = db.query(HomeContent).filter(HomeContent.id == content_id).first()
    if not content:
        raise HTTPException(status_code=404, detail="Content not found")
    
    db.delete(content)
    db.commit()
    
    return {"message": "Content deleted successfully"}


# Public endpoint to get home content
@router.get("/public/home-content", response_model=List[HomeContentResponse])
async def get_public_home_content(
    ward_id: Optional[int] = None,
    db: Session = Depends(get_db)
):
    """Get active home screen content (public endpoint for mobile app)"""
    query = db.query(HomeContent).filter(HomeContent.is_active == True)
    
    if ward_id:
        query = query.filter((HomeContent.ward_id == ward_id) | (HomeContent.ward_id == None))
    else:
        query = query.filter(HomeContent.ward_id == None)
    
    # Filter by date if applicable
    now = datetime.utcnow()
    query = query.filter(
        (HomeContent.start_date <= now) | (HomeContent.start_date == None)
    ).filter(
        (HomeContent.end_date >= now) | (HomeContent.end_date == None)
    )
    
    content = query.order_by(HomeContent.display_order).all()
    return [HomeContentResponse.from_attributes(c) for c in content]
