from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import func, and_, or_
from typing import Optional, List
from datetime import datetime

from app.core.database import get_db
from app.core.security import get_current_user, require_role, get_password_hash
from app.models.user import User, UserRole
from app.models.matrimonial import (
    MatrimonialUser, MatrimonialAgency, UserPreference, Match,
    MatrimonialMessage, Gender, MaritalStatus, MatrimonialUserStatus,
    MatchStatus, MessageStatus, AgencyProfile
)
from app.models.ward import Ward
from pydantic import BaseModel, Field, EmailStr
from typing import Optional, List


router = APIRouter(prefix="/matrimonial", tags=["Matrimonial"])


# Pydantic Models
class UserPreferenceRequest(BaseModel):
    min_age: Optional[int] = None
    max_age: Optional[int] = None
    preferred_height: Optional[str] = None
    preferred_religion: Optional[str] = None
    preferred_caste: Optional[str] = None
    preferred_education: Optional[str] = None
    preferred_occupation: Optional[str] = None
    preferred_location: Optional[str] = None


class MatrimonialUserRegisterRequest(BaseModel):
    first_name: str = Field(..., min_length=2, max_length=100)
    last_name: str = Field(..., min_length=2, max_length=100)
    email: EmailStr
    phone: str = Field(..., min_length=10, max_length=15)
    gender: Gender
    date_of_birth: datetime
    marital_status: MaritalStatus
    religion: Optional[str] = None
    caste: Optional[str] = None
    height: Optional[str] = None
    occupation: Optional[str] = None
    education: Optional[str] = None
    location: str
    ward_id: Optional[int] = None
    bio: Optional[str] = None
    preferences: Optional[UserPreferenceRequest] = None


class MatrimonialUserResponse(BaseModel):
    id: int
    first_name: str
    last_name: str
    email: str
    phone: str
    gender: Gender
    marital_status: MaritalStatus
    occupation: Optional[str]
    education: Optional[str]
    location: str
    profile_image: Optional[str]
    bio: Optional[str]
    status: MatrimonialUserStatus
    is_verified: bool
    created_at: datetime

    class Config:
        from_attributes = True


class MatrimonialAgencyRegisterRequest(BaseModel):
    agency_name: str = Field(..., min_length=2, max_length=255)
    contact_email: EmailStr
    phone: str = Field(..., min_length=10, max_length=15)
    owner_name: str = Field(..., min_length=2, max_length=100)
    registration_number: str = Field(..., min_length=1, max_length=100)
    location: str
    ward_id: Optional[int] = None
    about: Optional[str] = None


class MatrimonialAgencyResponse(BaseModel):
    id: int
    agency_name: str
    contact_email: str
    phone: str
    owner_name: str
    location: str
    about: Optional[str]
    is_verified: bool
    status: MatrimonialUserStatus
    created_at: datetime

    class Config:
        from_attributes = True


class MatchRequest(BaseModel):
    receiver_id: int
    message: Optional[str] = None


class MatchResponse(BaseModel):
    id: int
    sender_id: int
    receiver_id: int
    status: MatchStatus
    message: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True


class MessageRequest(BaseModel):
    receiver_id: Optional[int] = None
    agency_id: Optional[int] = None
    content: str = Field(..., min_length=1)


class MessageResponse(BaseModel):
    id: int
    sender_id: Optional[int]
    receiver_id: Optional[int]
    agency_id: Optional[int]
    content: str
    status: MessageStatus
    created_at: datetime

    class Config:
        from_attributes = True


# User Registration
@router.post("/users/register", response_model=MatrimonialUserResponse)
async def register_matrimonial_user(
    request: MatrimonialUserRegisterRequest,
    db: Session = Depends(get_db)
):
    """Register a new individual for matrimonial services"""
    # Check if email already exists
    existing = db.query(MatrimonialUser).filter(MatrimonialUser.email == request.email).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )

    user = MatrimonialUser(
        first_name=request.first_name,
        last_name=request.last_name,
        email=request.email,
        phone=request.phone,
        gender=request.gender,
        date_of_birth=request.date_of_birth,
        marital_status=request.marital_status,
        religion=request.religion,
        caste=request.caste,
        height=request.height,
        occupation=request.occupation,
        education=request.education,
        location=request.location,
        ward_id=request.ward_id,
        bio=request.bio,
        status=MatrimonialUserStatus.ACTIVE
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    # Add preferences if provided
    if request.preferences:
        pref = UserPreference(
            user_id=user.id,
            min_age=request.preferences.min_age,
            max_age=request.preferences.max_age,
            preferred_height=request.preferences.preferred_height,
            preferred_religion=request.preferences.preferred_religion,
            preferred_caste=request.preferences.preferred_caste,
            preferred_education=request.preferences.preferred_education,
            preferred_occupation=request.preferences.preferred_occupation,
            preferred_location=request.preferences.preferred_location
        )
        db.add(pref)
        db.commit()

    return MatrimonialUserResponse.from_attributes(user)


# Agency Registration
@router.post("/agencies/register", response_model=MatrimonialAgencyResponse)
async def register_matrimonial_agency(
    request: MatrimonialAgencyRegisterRequest,
    db: Session = Depends(get_db)
):
    """Register a new matrimonial agency"""
    # Check if email or registration number already exists
    existing_email = db.query(MatrimonialAgency).filter(MatrimonialAgency.contact_email == request.contact_email).first()
    if existing_email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )

    existing_reg = db.query(MatrimonialAgency).filter(MatrimonialAgency.registration_number == request.registration_number).first()
    if existing_reg:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Registration number already exists"
        )

    agency = MatrimonialAgency(
        agency_name=request.agency_name,
        contact_email=request.contact_email,
        phone=request.phone,
        owner_name=request.owner_name,
        registration_number=request.registration_number,
        location=request.location,
        ward_id=request.ward_id,
        about=request.about,
        status=MatrimonialUserStatus.ACTIVE
    )
    db.add(agency)
    db.commit()
    db.refresh(agency)

    return MatrimonialAgencyResponse.from_attributes(agency)


# Get User Profiles (for agencies)
@router.get("/users", response_model=List[MatrimonialUserResponse])
async def get_matrimonial_users(
    location: Optional[str] = None,
    gender: Optional[Gender] = None,
    min_age: Optional[int] = None,
    max_age: Optional[int] = None,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db)
):
    """Get matrimonial users (filtered)"""
    query = db.query(MatrimonialUser).filter(
        MatrimonialUser.status == MatrimonialUserStatus.ACTIVE,
        MatrimonialUser.is_verified == True
    )

    if location:
        query = query.filter(MatrimonialUser.location.ilike(f"%{location}%"))
    
    if gender:
        query = query.filter(MatrimonialUser.gender == gender)

    users = query.offset((page - 1) * page_size).limit(page_size).all()
    return [MatrimonialUserResponse.from_attributes(u) for u in users]


# Get Agency Profiles (for individuals)
@router.get("/agencies", response_model=List[MatrimonialAgencyResponse])
async def get_matrimonial_agencies(
    location: Optional[str] = None,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db)
):
    """Get matrimonial agencies"""
    query = db.query(MatrimonialAgency).filter(
        MatrimonialAgency.status == MatrimonialUserStatus.ACTIVE,
        MatrimonialAgency.is_verified == True
    )

    if location:
        query = query.filter(MatrimonialAgency.location.ilike(f"%{location}%"))

    agencies = query.offset((page - 1) * page_size).limit(page_size).all()
    return [MatrimonialAgencyResponse.from_attributes(a) for a in agencies]


# Create Match Request
@router.post("/matches", response_model=MatchResponse)
async def create_match(
    request: MatchRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create a match request"""
    # Get matrimonial user
    mat_user = db.query(MatrimonialUser).filter(MatrimonialUser.user_id == current_user.id).first()
    if not mat_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Matrimonial profile not found"
        )

    # Check if match already exists
    existing = db.query(Match).filter(
        and_(
            Match.sender_id == mat_user.id,
            Match.receiver_id == request.receiver_id
        )
    ).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Match request already exists"
        )

    match = Match(
        sender_id=mat_user.id,
        receiver_id=request.receiver_id,
        message=request.message,
        status=MatchStatus.PENDING
    )
    db.add(match)
    db.commit()
    db.refresh(match)

    return MatchResponse.from_attributes(match)


# Get Matches
@router.get("/matches", response_model=List[MatchResponse])
async def get_matches(
    status_filter: Optional[MatchStatus] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get matches for current user"""
    mat_user = db.query(MatrimonialUser).filter(MatrimonialUser.user_id == current_user.id).first()
    if not mat_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Matrimonial profile not found"
        )

    query = db.query(Match).filter(
        or_(
            Match.sender_id == mat_user.id,
            Match.receiver_id == mat_user.id
        )
    )

    if status_filter:
        query = query.filter(Match.status == status_filter)

    matches = query.all()
    return [MatchResponse.from_attributes(m) for m in matches]


# Send Message
@router.post("/messages", response_model=MessageResponse)
async def send_message(
    request: MessageRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Send a message"""
    mat_user = db.query(MatrimonialUser).filter(MatrimonialUser.user_id == current_user.id).first()
    
    message = MatrimonialMessage(
        sender_id=mat_user.id if mat_user else None,
        receiver_id=request.receiver_id,
        agency_id=request.agency_id,
        content=request.content,
        status=MessageStatus.SENT
    )
    db.add(message)
    db.commit()
    db.refresh(message)

    return MessageResponse.from_attributes(message)


# Get Messages
@router.get("/messages", response_model=List[MessageResponse])
async def get_messages(
    conversation_id: Optional[int] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get messages for current user"""
    mat_user = db.query(MatrimonialUser).filter(MatrimonialUser.user_id == current_user.id).first()
    
    query = db.query(MatrimonialMessage).filter(
        or_(
            MatrimonialMessage.sender_id == mat_user.id,
            MatrimonialMessage.receiver_id == mat_user.id
        )
    )

    messages = query.order_by(MatrimonialMessage.created_at).all()
    return [MessageResponse.from_attributes(m) for m in messages]
