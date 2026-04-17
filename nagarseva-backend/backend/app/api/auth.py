from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from typing import Optional
import os
import uuid

from app.core.database import get_db
from app.core.security import (
    get_password_hash, verify_password, create_access_token,
    get_current_user
)
from app.core.config import settings
from app.models.user import User, UserRole
from app.models.ward import Ward
from app.schemas.auth import (
    RegisterRequest, LoginRequest,
    TokenResponse, UserResponse, UserUpdateRequest, ChangePasswordRequest
)
from app.schemas.common import MessageResponse

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/register", response_model=TokenResponse)
async def register(
    name: str = Form(...),
    mobile: str = Form(...),
    password: str = Form(...),
    confirm_password: str = Form(...),
    ward_id: int = Form(...),
    address: str = Form(...),
    email: Optional[str] = Form(None),
    profile_image: Optional[UploadFile] = File(None),
    db: Session = Depends(get_db)
):
    """Register a new citizen with password-based authentication"""
    # Validate password match
    if password != confirm_password:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Passwords do not match"
        )
    
    # Check if user already exists
    existing_user = db.query(User).filter(User.mobile == mobile).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Mobile number already registered"
        )
    
    # Verify ward exists
    ward = db.query(Ward).filter(Ward.id == ward_id).first()
    if not ward:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid ward selected"
        )
    
    # Handle profile image upload
    profile_image_path = None
    if profile_image:
        file_ext = profile_image.filename.split(".")[-1].lower()
        if file_ext not in ["jpg", "jpeg", "png", "gif", "webp"]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid image format. Allowed: jpg, jpeg, png, gif, webp"
            )
        
        filename = f"{uuid.uuid4()}.{file_ext}"
        file_path = f"{settings.UPLOAD_DIR}/profiles/{filename}"
        
        with open(file_path, "wb") as f:
            content = await profile_image.read()
            f.write(content)
        
        profile_image_path = f"/uploads/profiles/{filename}"
    
    # Create user
    user = User(
        name=name,
        mobile=mobile,
        email=email,
        password_hash=get_password_hash(password),
        role=UserRole.CITIZEN,
        ward_id=ward_id,
        address=address,
        profile_image=profile_image_path,
        is_verified=True
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    
    # Generate token
    access_token = create_access_token(data={"sub": str(user.id)})
    
    return TokenResponse(
        access_token=access_token,
        user=UserResponse(
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
    )


@router.post("/login", response_model=TokenResponse)
async def login(request: LoginRequest, db: Session = Depends(get_db)):
    """Login with mobile and password"""
    user = db.query(User).filter(User.mobile == request.mobile).first()
    
    if not user or not verify_password(request.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid mobile number or password"
        )
    
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account is deactivated"
        )
    
    ward = db.query(Ward).filter(Ward.id == user.ward_id).first()
    access_token = create_access_token(data={"sub": str(user.id)})
    
    return TokenResponse(
        access_token=access_token,
        user=UserResponse(
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
        )
    )


@router.get("/me", response_model=UserResponse)
async def get_current_user_info(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get current user information"""
    ward = db.query(Ward).filter(Ward.id == current_user.ward_id).first()
    
    return UserResponse(
        id=current_user.id,
        name=current_user.name,
        mobile=current_user.mobile,
        email=current_user.email,
        role=current_user.role,
        ward_id=current_user.ward_id,
        ward_name=ward.name if ward else None,
        address=current_user.address,
        profile_image=current_user.profile_image,
        is_active=current_user.is_active,
        is_verified=current_user.is_verified
    )


@router.put("/profile", response_model=UserResponse)
async def update_profile(
    name: Optional[str] = Form(None),
    email: Optional[str] = Form(None),
    address: Optional[str] = Form(None),
    profile_image: Optional[UploadFile] = File(None),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update user profile with optional new profile image"""
    if name:
        current_user.name = name
    if email:
        current_user.email = email
    if address:
        current_user.address = address
    
    if profile_image:
        file_ext = profile_image.filename.split(".")[-1].lower()
        if file_ext not in ["jpg", "jpeg", "png", "gif", "webp"]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid image format"
            )
        
        filename = f"{uuid.uuid4()}.{file_ext}"
        file_path = f"{settings.UPLOAD_DIR}/profiles/{filename}"
        
        with open(file_path, "wb") as f:
            content = await profile_image.read()
            f.write(content)
        
        # Delete old profile image if exists
        if current_user.profile_image:
            old_path = current_user.profile_image.replace("/uploads/", f"{settings.UPLOAD_DIR}/")
            if os.path.exists(old_path):
                os.remove(old_path)
        
        current_user.profile_image = f"/uploads/profiles/{filename}"
    
    db.commit()
    db.refresh(current_user)
    
    ward = db.query(Ward).filter(Ward.id == current_user.ward_id).first()
    
    return UserResponse(
        id=current_user.id,
        name=current_user.name,
        mobile=current_user.mobile,
        email=current_user.email,
        role=current_user.role,
        ward_id=current_user.ward_id,
        ward_name=ward.name if ward else None,
        address=current_user.address,
        profile_image=current_user.profile_image,
        is_active=current_user.is_active,
        is_verified=current_user.is_verified
    )


@router.post("/change-password", response_model=MessageResponse)
async def change_password(
    request: ChangePasswordRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Change user password"""
    if not verify_password(request.old_password, current_user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Current password is incorrect"
        )
    
    current_user.password_hash = get_password_hash(request.new_password)
    db.commit()
    
    return MessageResponse(message="Password changed successfully")
