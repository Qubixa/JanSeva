import os

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import func, or_
from typing import Optional, List
from datetime import datetime, timedelta

from app.core.database import get_db
from app.core.security import get_current_user, require_role, get_password_hash
from app.models.user import User, UserRole
from app.models.ward import Ward
from app.models.complaint import Complaint, ComplaintCategory
from app.schemas.auth import UserResponse
from app.schemas.common import MessageResponse
from pydantic import BaseModel, Field, EmailStr


router = APIRouter(prefix="/admin", tags=["Admin"])

STATUS_PENDING = "PENDING"
STATUS_ASSIGNED = "ASSIGNED"
STATUS_IN_PROGRESS = "IN_PROGRESS"
STATUS_RESOLVED = "RESOLVED"
STATUS_REJECTED = "REJECTED"
STATUS_CLOSED = "CLOSED"


# ==================== Request/Response Schemas ====================

class CreateUserRequest(BaseModel):
    name: str = Field(..., min_length=2, max_length=100)
    mobile: str = Field(..., min_length=10, max_length=15)
    email: Optional[EmailStr] = None
    password: str = Field(..., min_length=6)
    role: UserRole
    ward_id: int
    address: str = Field(..., min_length=10, max_length=500)
    is_active: bool = True
    is_verified: bool = True


class UpdateUserRequest(BaseModel):
    name: Optional[str] = Field(None, min_length=2, max_length=100)
    mobile: Optional[str] = Field(None, min_length=10, max_length=15)
    email: Optional[EmailStr] = None
    role: Optional[UserRole] = None
    ward_id: Optional[int] = None
    address: Optional[str] = Field(None, min_length=10, max_length=500)
    is_active: Optional[bool] = None
    is_verified: Optional[bool] = None
    password: Optional[str] = Field(None, min_length=6)


class ChangePasswordRequest(BaseModel):
    new_password: str = Field(..., min_length=6)


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
    total_pages: int


class BulkUserResponse(BaseModel):
    message: str
    created_count: int
    failed_count: int
    errors: List[dict] = []


# ==================== Dashboard ====================

@router.get("/dashboard", response_model=DashboardStats)
async def get_dashboard_stats(
    current_user: User = Depends(require_role([UserRole.WARD_ADMIN, UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    """Get dashboard statistics"""
    base_filter = []
    if current_user.role == UserRole.WARD_ADMIN:
        base_filter.append(Complaint.ward_id == current_user.ward_id)
    
    # Total complaints
    total_query = db.query(func.count(Complaint.id))
    if base_filter:
        total_query = total_query.filter(*base_filter)
    total_complaints = total_query.scalar()
    
    # Status-wise counts
    status_list = [STATUS_PENDING, STATUS_ASSIGNED, STATUS_IN_PROGRESS, 
                   STATUS_RESOLVED, STATUS_REJECTED, STATUS_CLOSED]
    status_counts = {}
    for status in status_list:
        count_query = db.query(func.count(Complaint.id)).filter(Complaint.status == status)
        if base_filter:
            count_query = count_query.filter(*base_filter)
        status_counts[status] = count_query.scalar()
    
    # Category-wise counts
    categories = db.query(ComplaintCategory).filter(ComplaintCategory.is_active == 'Y').all()
    category_counts = {}
    for category in categories:
        count_query = db.query(func.count(Complaint.id)).filter(Complaint.category == category.code)
        if base_filter:
            count_query = count_query.filter(*base_filter)
        count = count_query.scalar()
        if count > 0:
            category_counts[category.name] = count
    
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
        pending_complaints=status_counts.get(STATUS_PENDING, 0),
        resolved_complaints=status_counts.get(STATUS_RESOLVED, 0),
        in_progress_complaints=status_counts.get(STATUS_IN_PROGRESS, 0),
        total_citizens=total_citizens,
        total_officers=total_officers,
        complaints_today=complaints_today,
        complaints_this_week=complaints_this_week,
        category_wise=category_counts,
        status_wise=status_counts
    )


# ==================== User Management CRUD ====================

@router.get("/users", response_model=UserListResponse)
async def get_users(
    role: Optional[UserRole] = None,
    ward_id: Optional[int] = None,
    search: Optional[str] = None,
    status: Optional[str] = None,  # 'active', 'inactive', 'pending'
    page: int = Query(1, ge=1),
    page_size: int = Query(10, ge=1, le=100),
    current_user: User = Depends(require_role([UserRole.WARD_ADMIN, UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    """Get all users with pagination, search, and filters"""
    query = db.query(User)
    
    # Ward admin can only see users from their ward
    if current_user.role == UserRole.WARD_ADMIN:
        query = query.filter(User.ward_id == current_user.ward_id)
    elif ward_id:
        query = query.filter(User.ward_id == ward_id)
    
    # Apply role filter
    if role:
        query = query.filter(User.role == role)
    
    # Apply status filter
    if status == "active":
        query = query.filter(User.is_active == True)
    elif status == "inactive":
        query = query.filter(User.is_active == False)
    elif status == "pending":
        query = query.filter(User.is_verified == False)
    
    # Apply search
    if search:
        query = query.filter(
            or_(
                User.name.ilike(f"%{search}%"),
                User.email.ilike(f"%{search}%"),
                User.mobile.ilike(f"%{search}%")
            )
        )
    
    total = query.count()
    total_pages = (total + page_size - 1) // page_size
    
    users = query.order_by(User.created_at.desc()).offset((page - 1) * page_size).limit(page_size).all()
    
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
            is_verified=user.is_verified,
            created_at=user.created_at,
            updated_at=user.updated_at
        ))
    
    return UserListResponse(
        users=user_responses,
        total=total,
        page=page,
        page_size=page_size,
        total_pages=total_pages
    )







@router.get("/users/bulk-template")
async def download_bulk_template(
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN, UserRole.WARD_ADMIN])),
):
    """Download template for bulk import"""
    import csv
    from io import StringIO
    from fastapi.responses import StreamingResponse
    
    output = StringIO()
    writer = csv.writer(output)
    
    # Write headers
    writer.writerow([
        "name", "mobile", "email", "password", "role", "ward_id", "address", "is_active", "is_verified"
    ])
    
    # Write example rows
    writer.writerow([
        "John Doe", "9876543210", "john@example.com", "Welcome@123", "CITIZEN", "1", "123 Main Street, City", "TRUE", "TRUE"
    ])
    writer.writerow([
        "Jane Smith", "9876543211", "jane@example.com", "Welcome@123", "FIELD_OFFICER", "2", "456 Oak Avenue, City", "TRUE", "TRUE"
    ])
    writer.writerow([
        "Admin User", "9876543212", "admin@example.com", "Welcome@123", "WARD_ADMIN", "3", "789 Pine Road, City", "TRUE", "TRUE"
    ])
    
    output.seek(0)
    filename = f"bulk_user_template_{datetime.now().strftime('%Y%m%d')}.csv"
    
    return StreamingResponse(
        iter([output.getvalue()]),
        media_type="text/csv",
        headers={"Content-Disposition": f"attachment; filename={filename}"}
    )


# Add these imports at the top
import pandas as pd
import io
from fastapi import UploadFile, File

# Add this new endpoint for bulk import
@router.post("/users/bulk-import")
async def bulk_import_users(
    file: UploadFile = File(...),
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    """Bulk import users from Excel or CSV file"""
    
    # Validate file type
    if not file.filename.endswith(('.xlsx', '.xls', '.csv')):
        raise HTTPException(
            status_code=400, 
            detail="Invalid file format. Please upload Excel (.xlsx, .xls) or CSV file"
        )
    
    created_count = 0
    failed_count = 0
    errors = []
    
    try:
        # Read file content
        contents = await file.read()
        
        # Parse based on file type
        if file.filename.endswith('.csv'):
            df = pd.read_csv(io.StringIO(contents.decode('utf-8')))
        else:
            df = pd.read_excel(io.BytesIO(contents))
        
        # Expected columns
        required_columns = ['name', 'mobile', 'role', 'ward_id', 'address']
        optional_columns = ['email', 'password', 'is_active', 'is_verified']
        
        # Check for required columns
        missing_columns = [col for col in required_columns if col not in df.columns]
        if missing_columns:
            raise HTTPException(
                status_code=400,
                detail=f"Missing required columns: {', '.join(missing_columns)}"
            )
        
        # Default password if not provided
        default_password = "Welcome@123"
        
        for index, row in df.iterrows():
            try:
                # Validate role
                role = row.get('role', 'CITIZEN').upper()
                if role not in [r.value for r in UserRole]:
                    errors.append({
                        "row": index + 2,
                        "mobile": row.get('mobile', 'N/A'),
                        "error": f"Invalid role: {role}"
                    })
                    failed_count += 1
                    continue
                
                # Check if mobile exists
                mobile = str(row['mobile']).strip()
                existing = db.query(User).filter(User.mobile == mobile).first()
                if existing:
                    errors.append({
                        "row": index + 2,
                        "mobile": mobile,
                        "error": "Mobile number already exists"
                    })
                    failed_count += 1
                    continue
                
                # Validate ward
                ward_id = int(row['ward_id'])
                ward = db.query(Ward).filter(Ward.id == ward_id).first()
                if not ward:
                    errors.append({
                        "row": index + 2,
                        "mobile": mobile,
                        "error": f"Invalid ward ID: {ward_id}"
                    })
                    failed_count += 1
                    continue
                
                # Prepare user data
                password = str(row.get('password', default_password))
                if len(password) < 6:
                    password = default_password
                
                user = User(
                    name=str(row['name']).strip(),
                    mobile=mobile,
                    email=str(row.get('email', '')).strip() or None,
                    password_hash=get_password_hash(password),
                    role=UserRole(role),
                    ward_id=ward_id,
                    address=str(row['address']).strip(),
                    is_active=bool(row.get('is_active', True)),
                    is_verified=bool(row.get('is_verified', True))
                )
                db.add(user)
                created_count += 1
                
            except Exception as e:
                errors.append({
                    "row": index + 2,
                    "mobile": row.get('mobile', 'N/A'),
                    "error": str(e)
                })
                failed_count += 1
        
        db.commit()
        
        return {
            "message": f"Import completed: {created_count} created, {failed_count} failed",
            "created_count": created_count,
            "failed_count": failed_count,
            "errors": errors[:100]  # Limit errors to first 100
        }
        
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Error processing file: {str(e)}")


@router.get("/users/export")
async def export_users(
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    """Export users to CSV (Super Admin only)"""
    import csv
    from io import StringIO
    from fastapi.responses import StreamingResponse
    
    users = db.query(User).order_by(User.id).all()
    
    output = StringIO()
    writer = csv.writer(output)
    writer.writerow([
        "ID", "Name", "Email", "Mobile", "Role", "Ward ID", "Ward Name", 
        "Address", "Status", "Verified", "Created At"
    ])
    
    for user in users:
        ward = db.query(Ward).filter(Ward.id == user.ward_id).first()
        writer.writerow([
            user.id, user.name, user.email or "", user.mobile, user.role.value,
            user.ward_id, ward.name if ward else "", user.address,
            "Active" if user.is_active else "Inactive",
            "Yes" if user.is_verified else "No",
            user.created_at.strftime("%Y-%m-%d %H:%M:%S") if user.created_at else ""
        ])
    
    output.seek(0)
    filename = f"users_export_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv"
    
    return StreamingResponse(
        iter([output.getvalue()]),
        media_type="text/csv",
        headers={"Content-Disposition": f"attachment; filename={filename}"}
    )


@router.post("/users", response_model=UserResponse)
async def create_user(
    request: CreateUserRequest,
    current_user: User = Depends(require_role([UserRole.WARD_ADMIN, UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    """Create a new user"""
    # Check if mobile already exists
    existing = db.query(User).filter(User.mobile == request.mobile).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Mobile number already registered"
        )
    
    # Check if email already exists
    if request.email:
        existing_email = db.query(User).filter(User.email == request.email).first()
        if existing_email:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already registered"
            )
    
    # Ward admin can only create users for their ward
    if current_user.role == UserRole.WARD_ADMIN:
        if request.ward_id != current_user.ward_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You can only create users for your ward"
            )
        # Ward admin cannot create super admins or ward admins
        if request.role in [UserRole.SUPER_ADMIN, UserRole.WARD_ADMIN]:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You cannot create admin users"
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
        is_active=request.is_active,
        is_verified=request.is_verified
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
        is_verified=user.is_verified,
        created_at=user.created_at,
        updated_at=user.updated_at
    )


@router.get("/users/{user_id}", response_model=UserResponse)
async def get_user(
    user_id: int,
    current_user: User = Depends(require_role([UserRole.WARD_ADMIN, UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    """Get user by ID"""
    user = db.query(User).filter(User.id == user_id).first()
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Ward admin can only view users from their ward
    if current_user.role == UserRole.WARD_ADMIN:
        if user.ward_id != current_user.ward_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You can only view users from your ward"
            )
    
    ward = db.query(Ward).filter(Ward.id == user.ward_id).first()
    
    return UserResponse(
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
        is_verified=user.is_verified,
        created_at=user.created_at,
        updated_at=user.updated_at
    )


@router.put("/users/{user_id}", response_model=UserResponse)
async def update_user(
    user_id: int,
    request: UpdateUserRequest,
    current_user: User = Depends(require_role([UserRole.WARD_ADMIN, UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    """Update user details"""
    user = db.query(User).filter(User.id == user_id).first()
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Ward admin can only update users from their ward
    if current_user.role == UserRole.WARD_ADMIN:
        if user.ward_id != current_user.ward_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You can only update users from your ward"
            )
        # Ward admin cannot change role to admin
        if request.role and request.role in [UserRole.SUPER_ADMIN, UserRole.WARD_ADMIN]:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You cannot assign admin roles"
            )
    
    # Check if mobile already exists (if being changed)
    if request.mobile and request.mobile != user.mobile:
        existing = db.query(User).filter(User.mobile == request.mobile).first()
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Mobile number already registered"
            )
    
    # Check if email already exists (if being changed)
    if request.email and request.email != user.email:
        existing_email = db.query(User).filter(User.email == request.email).first()
        if existing_email:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already registered"
            )
    
    # Update fields
    update_data = request.dict(exclude_unset=True)
    for field, value in update_data.items():
        if field == "password" and value:
            setattr(user, "password_hash", get_password_hash(value))
        elif value is not None:
            setattr(user, field, value)
    
    db.commit()
    db.refresh(user)
    
    ward = db.query(Ward).filter(Ward.id == user.ward_id).first()
    
    return UserResponse(
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
        is_verified=user.is_verified,
        created_at=user.created_at,
        updated_at=user.updated_at
    )


@router.patch("/users/{user_id}/toggle-status", response_model=MessageResponse)
async def toggle_user_status(
    user_id: int,
    current_user: User = Depends(require_role([UserRole.WARD_ADMIN, UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    """Activate/Deactivate user"""
    user = db.query(User).filter(User.id == user_id).first()
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Cannot deactivate yourself
    if user.id == current_user.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You cannot change your own status"
        )
    
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


@router.post("/users/{user_id}/resend-verification", response_model=MessageResponse)
async def resend_verification(
    user_id: int,
    current_user: User = Depends(require_role([UserRole.WARD_ADMIN, UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    """Resend verification email/SMS"""
    user = db.query(User).filter(User.id == user_id).first()
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    if user.is_verified:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User is already verified"
        )
    
    # Here you would integrate with your email/SMS service
    # For now, just mark as verified or send a notification
    
    # Example: Send verification email
    # await send_verification_email(user.email, user.name)
    
    return MessageResponse(message=f"Verification sent to {user.mobile}")


@router.delete("/users/{user_id}", response_model=MessageResponse)
async def delete_user(
    user_id: int,
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    """Delete user (Super Admin only)"""
    user = db.query(User).filter(User.id == user_id).first()
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Cannot delete yourself
    if user.id == current_user.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You cannot delete your own account"
        )
    
    # Check if user has related records
    complaint_count = db.query(func.count(Complaint.id)).filter(
        or_(
            Complaint.user_id == user_id,
            Complaint.assigned_officer_id == user_id
        )
    ).scalar()
    
    if complaint_count > 0:
        # Soft delete or prevent deletion
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot delete user with {complaint_count} associated complaints. Deactivate instead."
        )
    
    db.delete(user)
    db.commit()
    
    return MessageResponse(message="User deleted successfully")


# @router.post("/users/bulk", response_model=BulkUserResponse)
# async def bulk_create_users(
#     users_data: List[CreateUserRequest],
#     current_user: User = Depends(require_role([UserRole.SUPER_ADMIN])),
#     db: Session = Depends(get_db)
# ):
#     """Bulk create users (Super Admin only)"""
#     created_count = 0
#     failed_count = 0
#     errors = []
    
#     for user_data in users_data:
#         try:
#             # Check if mobile exists
#             existing = db.query(User).filter(User.mobile == user_data.mobile).first()
#             if existing:
#                 errors.append({"mobile": user_data.mobile, "error": "Mobile number already exists"})
#                 failed_count += 1
#                 continue
            
#             ward = db.query(Ward).filter(Ward.id == user_data.ward_id).first()
#             if not ward:
#                 errors.append({"mobile": user_data.mobile, "error": "Invalid ward ID"})
#                 failed_count += 1
#                 continue
            
#             user = User(
#                 name=user_data.name,
#                 mobile=user_data.mobile,
#                 email=user_data.email,
#                 password_hash=get_password_hash(user_data.password),
#                 role=user_data.role,
#                 ward_id=user_data.ward_id,
#                 address=user_data.address,
#                 is_active=True,
#                 is_verified=True
#             )
#             db.add(user)
#             created_count += 1
            
#         except Exception as e:
#             errors.append({"mobile": user_data.mobile, "error": str(e)})
#             failed_count += 1
    
#     db.commit()
    
#     return BulkUserResponse(
#         message=f"Created {created_count} users, failed {failed_count}",
#         created_count=created_count,
#         failed_count=failed_count,
#         errors=errors
#     )


# ==================== Field Officers ====================

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
            is_verified=officer.is_verified,
            created_at=officer.created_at,
            updated_at=officer.updated_at
        ))
    
    return result


# ==================== User Stats ====================

@router.get("/users/stats")
async def get_user_stats(
    current_user: User = Depends(require_role([UserRole.WARD_ADMIN, UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    """Get user statistics"""
    query = db.query(User)
    
    if current_user.role == UserRole.WARD_ADMIN:
        query = query.filter(User.ward_id == current_user.ward_id)
    
    total_users = query.count()
    active_users = query.filter(User.is_active == True).count()
    inactive_users = query.filter(User.is_active == False).count()
    verified_users = query.filter(User.is_verified == True).count()
    unverified_users = query.filter(User.is_verified == False).count()
    
    role_counts = {}
    for role in UserRole:
        role_counts[role.value] = query.filter(User.role == role).count()
    
    return {
        "total_users": total_users,
        "active_users": active_users,
        "inactive_users": inactive_users,
        "verified_users": verified_users,
        "unverified_users": unverified_users,
        "role_counts": role_counts
    }





@router.get("/dashboard/trends")
async def get_dashboard_trends(
    range: str = Query("week", pattern="^(week|month|year)$"),
    current_user: User = Depends(require_role([UserRole.WARD_ADMIN, UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    """Get complaint trends for charts"""
    
    end_date = datetime.utcnow()
    
    if range == "week":
        start_date = end_date - timedelta(days=7)
        date_format = "%Y-%m-%d"
    elif range == "month":
        start_date = end_date - timedelta(days=30)
        date_format = "%Y-%m-%d"
    else:  # year
        start_date = end_date - timedelta(days=365)
        date_format = "%Y-%m"
    
    # Query complaints by date
    complaints_query = db.query(
        func.date_format(Complaint.created_at, date_format).label("date"),
        func.count(Complaint.id).label("count")
    ).filter(Complaint.created_at >= start_date)
    
    resolved_query = db.query(
        func.date_format(Complaint.resolved_at, date_format).label("date"),
        func.count(Complaint.id).label("count")
    ).filter(Complaint.resolved_at >= start_date, Complaint.resolved_at.isnot(None))
    
    # Apply role filter
    if current_user.role == UserRole.WARD_ADMIN:
        complaints_query = complaints_query.filter(Complaint.ward_id == current_user.ward_id)
        resolved_query = resolved_query.filter(Complaint.ward_id == current_user.ward_id)
    
    complaints_results = complaints_query.group_by("date").order_by("date").all()
    resolved_results = resolved_query.group_by("date").order_by("date").all()
    
    # Create lookup dicts
    complaints_dict = {r.date: r.count for r in complaints_results}
    resolved_dict = {r.date: r.count for r in resolved_results}
    
    # Generate date range
    dates = []
    current = start_date
    while current <= end_date:
        if range == "year":
            dates.append(current.strftime("%Y-%m"))
            current = current.replace(month=current.month + 1) if current.month < 12 else current.replace(year=current.year + 1, month=1)
        else:
            dates.append(current.strftime("%Y-%m-%d"))
            current += timedelta(days=1)
    
    return [
        {"date": d, "complaints": complaints_dict.get(d, 0), "resolved": resolved_dict.get(d, 0)}
        for d in dates
    ]




# Add this import at the top of your admin router
from app.models.complaint import Complaint, ComplaintMedia, ComplaintLog
from app.schemas.complaint import ComplaintMediaResponse, ComplaintResponse, OfficerBrief, UserBrief, WardBrief

# Add this to your admin router (after the dashboard endpoints)

# ==================== Complaint Management (Admin) ====================

class ComplaintListResponseAdmin(BaseModel):
    complaints: List[ComplaintResponse]
    total: int
    page: int
    page_size: int
    total_pages: int


def complaint_to_response_admin(complaint: Complaint, db: Session) -> ComplaintResponse:
    """Convert complaint model to response for admin"""
    user = db.query(User).filter(User.id == complaint.user_id).first()
    ward = db.query(Ward).filter(Ward.id == complaint.ward_id).first()
    officer = None
    if complaint.assigned_officer_id:
        officer = db.query(User).filter(User.id == complaint.assigned_officer_id).first()
    
    # Get category info
    category_info = None
    if complaint.category:
        cat = db.query(ComplaintCategory).filter(
            ComplaintCategory.code == complaint.category
        ).first()
        if cat:
            from app.schemas.complaint import ComplaintCategorySchema
            category_info = ComplaintCategorySchema(
                id=cat.id,
                code=cat.code,
                name=cat.name,
                description=cat.description,
                icon=cat.icon,
                department=cat.department,
                is_active=cat.is_active
            )
    
    media_list = [
        ComplaintMediaResponse(
            id=m.id,
            file_path=m.file_path,
            file_type=m.file_type,
            file_name=m.file_name,
            uploaded_at=m.uploaded_at
        ) for m in complaint.media
    ]
    
    # Create nested objects as dictionaries
    user_dict = None
    if user:
        user_dict = {
            "id": user.id,
            "name": user.name,
            "mobile": user.mobile
        }
    
    ward_dict = None
    if ward:
        ward_dict = {
            "id": ward.id,
            "name": ward.name
        }
    
    officer_dict = None
    if officer:
        officer_dict = {
            "id": officer.id,
            "name": officer.name
        }
    
    return ComplaintResponse(
        id=complaint.id,
        complaint_number=complaint.complaint_number,
        category=complaint.category,
        title=complaint.title,
        description=complaint.description,
        address=complaint.address,
        latitude=complaint.latitude,
        longitude=complaint.longitude,
        status=complaint.status,
        priority=complaint.priority,
        resolution_remarks=complaint.resolution_remarks,
        feedback=complaint.feedback,
        rating=complaint.rating,
        user_id=complaint.user_id,
        user=user_dict,  # Dictionary
        ward_id=complaint.ward_id,
        ward=ward_dict,  # Dictionary
        assigned_officer_id=complaint.assigned_officer_id,
        assigned_officer=officer_dict,  # Dictionary
        user_name=user.name if user else None,
        user_mobile=user.mobile if user else None,
        ward_name=ward.name if ward else None,
        assigned_officer_name=officer.name if officer else None,
        category_info=category_info,
        media=media_list,
        created_at=complaint.created_at,
        updated_at=complaint.updated_at,
        resolved_at=complaint.resolved_at
    )


@router.get("/complaints", response_model=ComplaintListResponseAdmin)
async def get_admin_complaints(
    page: int = Query(1, ge=1),
    page_size: int = Query(10, ge=1, le=100),
    status: Optional[str] = None,
    category: Optional[str] = None,
    priority: Optional[str] = None,
    ward_id: Optional[int] = None,
    search: Optional[str] = None,
    from_date: Optional[str] = None,
    to_date: Optional[str] = None,
    current_user: User = Depends(require_role([UserRole.WARD_ADMIN, UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    """Get all complaints with filters for admin panel"""
    query = db.query(Complaint)
    
    # Ward admin can only see complaints from their ward
    if current_user.role == UserRole.WARD_ADMIN:
        query = query.filter(Complaint.ward_id == current_user.ward_id)
    elif ward_id:
        query = query.filter(Complaint.ward_id == ward_id)
    
    # Apply filters
    if status:
        query = query.filter(Complaint.status == status.upper())
    if category:
        query = query.filter(Complaint.category == category)
    if priority:
        query = query.filter(Complaint.priority == priority.upper())
    if search:
        query = query.filter(
            or_(
                Complaint.complaint_number.ilike(f"%{search}%"),
                Complaint.title.ilike(f"%{search}%"),
                Complaint.description.ilike(f"%{search}%")
            )
        )
    
    # Date range filter
    if from_date:
        try:
            from_date_obj = datetime.strptime(from_date, "%Y-%m-%d")
            query = query.filter(Complaint.created_at >= from_date_obj)
        except ValueError:
            pass
    
    if to_date:
        try:
            to_date_obj = datetime.strptime(to_date, "%Y-%m-%d")
            query = query.filter(Complaint.created_at <= to_date_obj)
        except ValueError:
            pass
    
    total = query.count()
    total_pages = (total + page_size - 1) // page_size
    
    complaints = query.order_by(Complaint.created_at.desc()).offset(
        (page - 1) * page_size
    ).limit(page_size).all()
    
    return ComplaintListResponseAdmin(
        complaints=[complaint_to_response_admin(c, db) for c in complaints],
        total=total,
        page=page,
        page_size=page_size,
        total_pages=total_pages
    )


@router.get("/complaints/{complaint_id}")
async def get_admin_complaint(
    complaint_id: int,
    current_user: User = Depends(require_role([UserRole.WARD_ADMIN, UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    """Get single complaint details for admin"""
    complaint = db.query(Complaint).filter(Complaint.id == complaint_id).first()
    
    if not complaint:
        raise HTTPException(status_code=404, detail="Complaint not found")
    
    # Ward admin can only view complaints from their ward
    if current_user.role == UserRole.WARD_ADMIN:
        if complaint.ward_id != current_user.ward_id:
            raise HTTPException(status_code=403, detail="Access denied")
    
    return complaint_to_response_admin(complaint, db)


@router.put("/complaints/{complaint_id}/status")
async def admin_update_complaint_status(
    complaint_id: int,
    status: str = Query(..., pattern="^(PENDING|ASSIGNED|IN_PROGRESS|RESOLVED|REJECTED|CLOSED)$"),
    remarks: Optional[str] = None,
    current_user: User = Depends(require_role([UserRole.WARD_ADMIN, UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    """Update complaint status (Admin only)"""
    complaint = db.query(Complaint).filter(Complaint.id == complaint_id).first()
    
    if not complaint:
        raise HTTPException(status_code=404, detail="Complaint not found")
    
    # Ward admin can only update complaints from their ward
    if current_user.role == UserRole.WARD_ADMIN:
        if complaint.ward_id != current_user.ward_id:
            raise HTTPException(status_code=403, detail="Access denied")
    
    old_status = complaint.status
    complaint.status = status
    
    if status == STATUS_RESOLVED:
        complaint.resolved_at = datetime.utcnow()
    
    # Create log
    log = ComplaintLog(
        complaint_id=complaint.id,
        action_by_id=current_user.id,
        action="STATUS_UPDATED",
        old_status=old_status,
        new_status=status,
        remarks=remarks or f"Status updated by admin"
    )
    db.add(log)
    db.commit()
    db.refresh(complaint)
    
    return {
        "success": True,
        "message": f"Complaint status updated to {status}",
        "complaint": complaint_to_response_admin(complaint, db)
    }


@router.delete("/complaints/{complaint_id}")
async def admin_delete_complaint(
    complaint_id: int,
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    """Delete complaint (Super Admin only)"""
    complaint = db.query(Complaint).filter(Complaint.id == complaint_id).first()
    
    if not complaint:
        raise HTTPException(status_code=404, detail="Complaint not found")
    
    # Delete associated media files
    for media in complaint.media:
        if media.file_path:
            file_path = media.file_path.replace("/uploads/", f"{settings.UPLOAD_DIR}/")
            if os.path.exists(file_path):
                os.remove(file_path)
    
    db.delete(complaint)
    db.commit()
    
    return {"success": True, "message": "Complaint deleted successfully"}


@router.get("/complaints/stats/summary")
async def get_complaint_summary(
    current_user: User = Depends(require_role([UserRole.WARD_ADMIN, UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    """Get complaint statistics summary for admin dashboard"""
    query = db.query(Complaint)
    
    if current_user.role == UserRole.WARD_ADMIN:
        query = query.filter(Complaint.ward_id == current_user.ward_id)
    
    total = query.count()
    pending = query.filter(Complaint.status == STATUS_PENDING).count()
    assigned = query.filter(Complaint.status == STATUS_ASSIGNED).count()
    in_progress = query.filter(Complaint.status == STATUS_IN_PROGRESS).count()
    resolved = query.filter(Complaint.status == STATUS_RESOLVED).count()
    rejected = query.filter(Complaint.status == STATUS_REJECTED).count()
    closed = query.filter(Complaint.status == STATUS_CLOSED).count()
    
    # Resolution rate
    resolution_rate = (resolved / total * 100) if total > 0 else 0
    
    # Average resolution time (in hours)
    resolved_complaints = query.filter(Complaint.status == STATUS_RESOLVED, Complaint.resolved_at.isnot(None)).all()
    total_hours = 0
    for c in resolved_complaints:
        if c.resolved_at and c.created_at:
            hours = (c.resolved_at - c.created_at).total_seconds() / 3600
            total_hours += hours
    avg_resolution_hours = (total_hours / len(resolved_complaints)) if resolved_complaints else 0
    
    return {
        "total": total,
        "pending": pending,
        "assigned": assigned,
        "in_progress": in_progress,
        "resolved": resolved,
        "rejected": rejected,
        "closed": closed,
        "resolution_rate": round(resolution_rate, 2),
        "avg_resolution_hours": round(avg_resolution_hours, 2)
    }



