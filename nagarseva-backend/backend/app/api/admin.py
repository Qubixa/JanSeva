from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import Optional, List
from datetime import datetime, timedelta

from app.core.database import get_db
from app.core.security import get_current_user, require_role, get_password_hash
from app.models.user import User, UserRole
from app.models.ward import Ward
from app.models.complaint import Complaint, ComplaintStatus, ComplaintCategory
from app.schemas.auth import UserResponse
from app.schemas.common import MessageResponse
from pydantic import BaseModel, Field


router = APIRouter(prefix="/admin", tags=["Admin"])


class CreateUserRequest(BaseModel):
    name: str = Field(..., min_length=2, max_length=100)
    mobile: str = Field(..., min_length=10, max_length=15)
    email: Optional[str] = None
    password: str = Field(..., min_length=6)
    role: UserRole
    ward_id: int
    address: str = Field(..., min_length=10, max_length=500)


class DashboardStats(BaseModel):
    total_complaints: int
    pending_complaints: int
    resolved_complaints: int
    in_progress_complaints: int
    total_citizens: int
    total_officers: int
    complaints_today: int
    complaints_this_week: int
    category_wise: dict
    status_wise: dict


class UserListResponse(BaseModel):
    users: List[UserResponse]
    total: int
    page: int
    page_size: int


@router.get("/dashboard", response_model=DashboardStats)
async def get_dashboard_stats(
    current_user: User = Depends(require_role([UserRole.WARD_ADMIN, UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    """Get dashboard statistics"""
    # Base query filter based on role
    base_filter = []
    if current_user.role == UserRole.WARD_ADMIN:
        base_filter.append(Complaint.ward_id == current_user.ward_id)
    
    # Total complaints
    total_query = db.query(func.count(Complaint.id))
    if base_filter:
        total_query = total_query.filter(*base_filter)
    total_complaints = total_query.scalar()
    
    # Status-wise counts
    status_counts = {}
    for status in ComplaintStatus:
        count_query = db.query(func.count(Complaint.id)).filter(Complaint.status == status)
        if base_filter:
            count_query = count_query.filter(*base_filter)
        status_counts[status.value] = count_query.scalar()
    
    # Category-wise counts
    category_counts = {}
    for category in ComplaintCategory:
        count_query = db.query(func.count(Complaint.id)).filter(Complaint.category == category)
        if base_filter:
            count_query = count_query.filter(*base_filter)
        count = count_query.scalar()
        if count > 0:
            category_counts[category.value] = count
    
    # Time-based counts
    today = datetime.utcnow().date()
    week_ago = today - timedelta(days=7)
    
    today_query = db.query(func.count(Complaint.id)).filter(
        func.date(Complaint.created_at) == today
    )
    if base_filter:
        today_query = today_query.filter(*base_filter)
    complaints_today = today_query.scalar()
    
    week_query = db.query(func.count(Complaint.id)).filter(
        func.date(Complaint.created_at) >= week_ago
    )
    if base_filter:
        week_query = week_query.filter(*base_filter)
    complaints_this_week = week_query.scalar()
    
    # User counts
    user_filter = []
    if current_user.role == UserRole.WARD_ADMIN:
        user_filter.append(User.ward_id == current_user.ward_id)
    
    citizens_query = db.query(func.count(User.id)).filter(User.role == UserRole.CITIZEN)
    if user_filter:
        citizens_query = citizens_query.filter(*user_filter)
    total_citizens = citizens_query.scalar()
    
    officers_query = db.query(func.count(User.id)).filter(User.role == UserRole.FIELD_OFFICER)
    if user_filter:
        officers_query = officers_query.filter(*user_filter)
    total_officers = officers_query.scalar()
    
    return DashboardStats(
        total_complaints=total_complaints,
        pending_complaints=status_counts.get(ComplaintStatus.PENDING.value, 0),
        resolved_complaints=status_counts.get(ComplaintStatus.RESOLVED.value, 0),
        in_progress_complaints=status_counts.get(ComplaintStatus.IN_PROGRESS.value, 0),
        total_citizens=total_citizens,
        total_officers=total_officers,
        complaints_today=complaints_today,
        complaints_this_week=complaints_this_week,
        category_wise=category_counts,
        status_wise=status_counts
    )


@router.get("/users", response_model=UserListResponse)
async def get_users(
    role: Optional[UserRole] = None,
    ward_id: Optional[int] = None,
    search: Optional[str] = None,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    current_user: User = Depends(require_role([UserRole.WARD_ADMIN, UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    """Get all users"""
    query = db.query(User)
    
    # Ward admin can only see users from their ward
    if current_user.role == UserRole.WARD_ADMIN:
        query = query.filter(User.ward_id == current_user.ward_id)
    elif ward_id:
        query = query.filter(User.ward_id == ward_id)
    
    if role:
        query = query.filter(User.role == role)
    
    if search:
        query = query.filter(
            (User.name.ilike(f"%{search}%")) |
            (User.mobile.ilike(f"%{search}%"))
        )
    
    total = query.count()
    users = query.offset((page - 1) * page_size).limit(page_size).all()
    
    user_responses = []
    for user in users:
        ward = db.query(Ward).filter(Ward.id == user.ward_id).first()
        user_responses.append(UserResponse(
            id=user.id,
            name=user.name,
            mobile=user.mobile,
            email=user.email,
            role=user.role,
            ward_id=user.ward_id,
            ward_name=ward.name if ward else None,
            address=user.address,
            profile_image=user.profile_image,
            is_active=user.is_active,
            is_verified=user.is_verified
        ))
    
    return UserListResponse(
        users=user_responses,
        total=total,
        page=page,
        page_size=page_size
    )


@router.post("/users", response_model=UserResponse)
async def create_user(
    request: CreateUserRequest,
    current_user: User = Depends(require_role([UserRole.WARD_ADMIN, UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    """Create a new user (Admin only)"""
    # Check if mobile already exists
    existing = db.query(User).filter(User.mobile == request.mobile).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Mobile number already registered"
        )
    
    # Ward admin can only create users for their ward
    if current_user.role == UserRole.WARD_ADMIN:
        if request.ward_id != current_user.ward_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You can only create users for your ward"
            )
        # Ward admin cannot create super admins
        if request.role == UserRole.SUPER_ADMIN:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You cannot create super admin users"
            )
    
    # Verify ward exists
    ward = db.query(Ward).filter(Ward.id == request.ward_id).first()
    if not ward:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid ward"
        )
    
    user = User(
        name=request.name,
        mobile=request.mobile,
        email=request.email,
        password_hash=get_password_hash(request.password),
        role=request.role,
        ward_id=request.ward_id,
        address=request.address,
        is_verified=True
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    
    return UserResponse(
        id=user.id,
        name=user.name,
        mobile=user.mobile,
        email=user.email,
        role=user.role,
        ward_id=user.ward_id,
        ward_name=ward.name,
        address=user.address,
        profile_image=user.profile_image,
        is_active=user.is_active,
        is_verified=user.is_verified
    )


@router.put("/users/{user_id}/toggle-status", response_model=MessageResponse)
async def toggle_user_status(
    user_id: int,
    current_user: User = Depends(require_role([UserRole.WARD_ADMIN, UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    """Activate/Deactivate user"""
    user = db.query(User).filter(User.id == user_id).first()
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Ward admin can only modify users from their ward
    if current_user.role == UserRole.WARD_ADMIN:
        if user.ward_id != current_user.ward_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You can only modify users from your ward"
            )
    
    user.is_active = not user.is_active
    db.commit()
    
    status_text = "activated" if user.is_active else "deactivated"
    return MessageResponse(message=f"User {status_text} successfully")


@router.get("/field-officers", response_model=List[UserResponse])
async def get_field_officers(
    current_user: User = Depends(require_role([UserRole.WARD_ADMIN, UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    """Get field officers for complaint assignment"""
    query = db.query(User).filter(
        User.role == UserRole.FIELD_OFFICER,
        User.is_active == True
    )
    
    if current_user.role == UserRole.WARD_ADMIN:
        query = query.filter(User.ward_id == current_user.ward_id)
    
    officers = query.all()
    
    result = []
    for officer in officers:
        ward = db.query(Ward).filter(Ward.id == officer.ward_id).first()
        result.append(UserResponse(
            id=officer.id,
            name=officer.name,
            mobile=officer.mobile,
            email=officer.email,
            role=officer.role,
            ward_id=officer.ward_id,
            ward_name=ward.name if ward else None,
            address=officer.address,
            profile_image=officer.profile_image,
            is_active=officer.is_active,
            is_verified=officer.is_verified
        ))
    
    return result
