from fastapi import APIRouter, Depends, HTTPException, status, Query, UploadFile, File, Form
from fastapi.responses import Response
from sqlalchemy.orm import Session
from sqlalchemy import func, and_, or_
from typing import Optional, List
from datetime import datetime
import base64

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
from app.core.security import require_admin


router = APIRouter(prefix="/matrimonial", tags=["Matrimonial"])

# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────

ALLOWED_IMAGE_TYPES = {"image/jpeg", "image/png", "image/webp", "image/gif"}
ALLOWED_DOC_TYPES   = {"application/pdf", "image/jpeg", "image/png"}
MAX_IMAGE_SIZE      = 5 * 1024 * 1024   # 5 MB
MAX_DOC_SIZE        = 10 * 1024 * 1024  # 10 MB


def _validate_file(file: UploadFile, allowed: set, max_bytes: int, label: str) -> bytes:
    if file.content_type not in allowed:
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail=f"{label} must be one of: {', '.join(allowed)}"
        )
    data = file.file.read()
    if len(data) > max_bytes:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail=f"{label} exceeds {max_bytes // (1024*1024)} MB limit"
        )
    return data


def _user_to_dict(p: MatrimonialUser) -> dict:
    """Convert MatrimonialUser ORM object to response dict with base64 image."""
    has_image    = bool(p.profile_image_data)
    has_bio_data = bool(p.bio_data_document)
    has_kundali  = bool(p.kundali_document)

    age = None
    if p.date_of_birth:
        today = datetime.now()
        age   = today.year - p.date_of_birth.year
        if (today.month, today.day) < (p.date_of_birth.month, p.date_of_birth.day):
            age -= 1

    return {
        "id":             p.id,
        "first_name":     p.first_name,
        "last_name":      p.last_name,
        "name":           f"{p.first_name} {p.last_name}",
        "email":          p.email,
        "phone":          p.phone,
        "gender":         p.gender.value if hasattr(p.gender, "value") else str(p.gender),
        "marital_status": p.marital_status.value if hasattr(p.marital_status, "value") else str(p.marital_status),
        "occupation":     p.occupation,
        "profession":     p.occupation,
        "education":      p.education,
        "location":       p.location,
        "religion":       p.religion,
        "caste":          p.caste,
        "height":         p.height,
        "bio":            p.bio,
        "about":          p.bio,
        "age":            age,
        # Legacy URL (may be None)
        "profile_image":  p.profile_image,
        "photo_url":      p.profile_image,
        # Binary image as base64 data-URI so Flutter can decode without extra request
        "profile_image_base64": (
            f"data:{p.profile_image_mime};base64,"
            + base64.b64encode(p.profile_image_data).decode()
            if has_image else None
        ),
        "has_profile_image": has_image,
        "has_bio_data":      has_bio_data,
        "bio_data_filename": p.bio_data_filename,
        "has_kundali":       has_kundali,
        "kundali_filename":  p.kundali_filename,
        "status":            p.status.value if hasattr(p.status, "value") else str(p.status),
        "is_verified":       p.is_verified,
        "created_at":        p.created_at.isoformat() if p.created_at else None,
    }


def _agency_to_dict(a: MatrimonialAgency) -> dict:
    return {
        "id":                  a.id,
        "agency_name":         a.agency_name,
        "contact_email":       a.contact_email,
        "phone":               a.phone,
        "owner_name":          a.owner_name,
        "registration_number": a.registration_number,
        "location":            a.location,
        "about":               a.about,
        "logo":                a.logo,
        "logo_base64": (
            f"data:{a.logo_mime};base64,"
            + base64.b64encode(a.logo_data).decode()
            if a.logo_data else None
        ),
        "has_logo":    bool(a.logo_data),
        "is_verified": a.is_verified,
        "status":      a.status.value if hasattr(a.status, "value") else str(a.status),
        "created_at":  a.created_at.isoformat() if a.created_at else None,
    }


# ─────────────────────────────────────────────────────────────────────────────
# Pydantic models (text-only, used for JSON registration without files)
# ─────────────────────────────────────────────────────────────────────────────

class UserPreferenceRequest(BaseModel):
    min_age: Optional[int] = None
    max_age: Optional[int] = None
    preferred_height: Optional[str] = None
    preferred_religion: Optional[str] = None
    preferred_caste: Optional[str] = None
    preferred_education: Optional[str] = None
    preferred_occupation: Optional[str] = None
    preferred_location: Optional[str] = None


class MatchRequest(BaseModel):
    receiver_id: int
    message: Optional[str] = None


class MessageRequest(BaseModel):
    receiver_id: Optional[int] = None
    agency_id: Optional[int] = None
    content: str = Field(..., min_length=1)


# ─────────────────────────────────────────────────────────────────────────────
# Individual registration  (multipart/form-data to accept files)
# ─────────────────────────────────────────────────────────────────────────────

@router.post("/users/register")
async def register_matrimonial_user(
    # ── Required text fields ──────────────────────────────────────────────
    first_name:     str = Form(..., min_length=2, max_length=100),
    last_name:      str = Form(..., min_length=2, max_length=100),
    email:          str = Form(...),
    phone:          str = Form(..., min_length=10, max_length=15),
    gender:         str = Form(...),
    date_of_birth:  str = Form(...),   # ISO string: "1995-06-15"
    marital_status: str = Form(...),
    location:       str = Form(...),
    # ── Optional text fields ──────────────────────────────────────────────
    religion:   Optional[str] = Form(None),
    caste:      Optional[str] = Form(None),
    height:     Optional[str] = Form(None),
    occupation: Optional[str] = Form(None),
    education:  Optional[str] = Form(None),
    ward_id:    Optional[int] = Form(None),
    bio:        Optional[str] = Form(None),
    # ── Optional file uploads ─────────────────────────────────────────────
    profile_image: Optional[UploadFile] = File(None),
    bio_data:      Optional[UploadFile] = File(None),   # PDF preferred
    kundali:       Optional[UploadFile] = File(None),   # PDF / image, optional
    db: Session = Depends(get_db),
):
    """Register a new individual for matrimonial services.
    Accepts multipart/form-data so profile photo, bio-data PDF, and kundali
    can be uploaded together with text fields in one request.
    """
    # Duplicate check
    existing = db.query(MatrimonialUser).filter(MatrimonialUser.email == email).first()
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")

    # Parse enums
    try:
        gender_enum         = Gender(gender.upper())
        marital_status_enum = MaritalStatus(marital_status.upper())
    except ValueError as exc:
        raise HTTPException(status_code=422, detail=str(exc))

    # Parse date
    try:
        dob = datetime.fromisoformat(date_of_birth)
    except ValueError:
        raise HTTPException(status_code=422, detail="date_of_birth must be ISO format: YYYY-MM-DD")

    user = MatrimonialUser(
        first_name=first_name,
        last_name=last_name,
        email=email,
        phone=phone,
        gender=gender_enum,
        date_of_birth=dob,
        marital_status=marital_status_enum,
        religion=religion,
        caste=caste,
        height=height,
        occupation=occupation,
        education=education,
        location=location,
        ward_id=ward_id,
        bio=bio,
        status=MatrimonialUserStatus.ACTIVE,
    )

    # ── Profile image ──────────────────────────────────────────────────────
    if profile_image and profile_image.filename:
        data = _validate_file(profile_image, ALLOWED_IMAGE_TYPES, MAX_IMAGE_SIZE, "Profile image")
        user.profile_image_data = data
        user.profile_image_mime = profile_image.content_type

    # ── Bio data document ──────────────────────────────────────────────────
    if bio_data and bio_data.filename:
        data = _validate_file(bio_data, ALLOWED_DOC_TYPES, MAX_DOC_SIZE, "Bio data document")
        user.bio_data_document = data
        user.bio_data_mime     = bio_data.content_type
        user.bio_data_filename = bio_data.filename

    # ── Kundali document (optional) ────────────────────────────────────────
    if kundali and kundali.filename:
        data = _validate_file(kundali, ALLOWED_DOC_TYPES, MAX_DOC_SIZE, "Kundali document")
        user.kundali_document = data
        user.kundali_mime     = kundali.content_type
        user.kundali_filename = kundali.filename

    db.add(user)
    db.commit()
    db.refresh(user)
    return _user_to_dict(user)


# ─────────────────────────────────────────────────────────────────────────────
# Upload / replace documents after registration
# ─────────────────────────────────────────────────────────────────────────────

@router.put("/users/{user_id}/profile-image")
async def upload_profile_image(
    user_id: int,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
):
    """Upload or replace the profile photo for an existing individual."""
    user = db.query(MatrimonialUser).filter(MatrimonialUser.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    data = _validate_file(file, ALLOWED_IMAGE_TYPES, MAX_IMAGE_SIZE, "Profile image")
    user.profile_image_data = data
    user.profile_image_mime = file.content_type
    db.commit()
    return {"success": True, "message": "Profile image updated"}


@router.put("/users/{user_id}/bio-data")
async def upload_bio_data(
    user_id: int,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
):
    """Upload or replace the bio data document (PDF recommended)."""
    user = db.query(MatrimonialUser).filter(MatrimonialUser.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    data = _validate_file(file, ALLOWED_DOC_TYPES, MAX_DOC_SIZE, "Bio data")
    user.bio_data_document = data
    user.bio_data_mime     = file.content_type
    user.bio_data_filename = file.filename
    db.commit()
    return {"success": True, "message": "Bio data document updated"}


@router.put("/users/{user_id}/kundali")
async def upload_kundali(
    user_id: int,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
):
    """Upload or replace the kundali document (optional)."""
    user = db.query(MatrimonialUser).filter(MatrimonialUser.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    data = _validate_file(file, ALLOWED_DOC_TYPES, MAX_DOC_SIZE, "Kundali")
    user.kundali_document = data
    user.kundali_mime     = file.content_type
    user.kundali_filename = file.filename
    db.commit()
    return {"success": True, "message": "Kundali document updated"}


# ─────────────────────────────────────────────────────────────────────────────
# Serve binary files (so Flutter can load via URL if needed)
# ─────────────────────────────────────────────────────────────────────────────

@router.get("/users/{user_id}/profile-image")
async def get_profile_image(user_id: int, db: Session = Depends(get_db)):
    user = db.query(MatrimonialUser).filter(MatrimonialUser.id == user_id).first()
    if not user or not user.profile_image_data:
        raise HTTPException(status_code=404, detail="No profile image found")
    return Response(content=user.profile_image_data, media_type=user.profile_image_mime or "image/jpeg")


@router.get("/users/{user_id}/bio-data")
async def get_bio_data(user_id: int, db: Session = Depends(get_db)):
    user = db.query(MatrimonialUser).filter(MatrimonialUser.id == user_id).first()
    if not user or not user.bio_data_document:
        raise HTTPException(status_code=404, detail="No bio data document found")
    headers = {}
    if user.bio_data_filename:
        headers["Content-Disposition"] = f'attachment; filename="{user.bio_data_filename}"'
    return Response(content=user.bio_data_document, media_type=user.bio_data_mime or "application/pdf", headers=headers)


@router.get("/users/{user_id}/kundali")
async def get_kundali(user_id: int, db: Session = Depends(get_db)):
    user = db.query(MatrimonialUser).filter(MatrimonialUser.id == user_id).first()
    if not user or not user.kundali_document:
        raise HTTPException(status_code=404, detail="No kundali document found")
    headers = {}
    if user.kundali_filename:
        headers["Content-Disposition"] = f'attachment; filename="{user.kundali_filename}"'
    return Response(content=user.kundali_document, media_type=user.kundali_mime or "application/pdf", headers=headers)


# ─────────────────────────────────────────────────────────────────────────────
# Agency registration (with binary logo)
# ─────────────────────────────────────────────────────────────────────────────

@router.post("/agencies/register")
async def register_matrimonial_agency(
    agency_name:         str = Form(..., min_length=2, max_length=255),
    contact_email:       str = Form(...),
    phone:               str = Form(..., min_length=10, max_length=15),
    owner_name:          str = Form(..., min_length=2, max_length=100),
    registration_number: str = Form(..., min_length=1, max_length=100),
    location:            str = Form(...),
    ward_id:             Optional[int] = Form(None),
    about:               Optional[str] = Form(None),
    # Agency logo stored directly as binary
    logo: Optional[UploadFile] = File(None),
    db: Session = Depends(get_db),
):
    """Register a new matrimonial agency.
    Accepts multipart/form-data; logo image is stored as binary in the database.
    """
    if db.query(MatrimonialAgency).filter(MatrimonialAgency.contact_email == contact_email).first():
        raise HTTPException(status_code=400, detail="Email already registered")
    if db.query(MatrimonialAgency).filter(MatrimonialAgency.registration_number == registration_number).first():
        raise HTTPException(status_code=400, detail="Registration number already exists")

    agency = MatrimonialAgency(
        agency_name=agency_name,
        contact_email=contact_email,
        phone=phone,
        owner_name=owner_name,
        registration_number=registration_number,
        location=location,
        ward_id=ward_id,
        about=about,
        status=MatrimonialUserStatus.ACTIVE,
    )

    if logo and logo.filename:
        data = _validate_file(logo, ALLOWED_IMAGE_TYPES, MAX_IMAGE_SIZE, "Agency logo")
        agency.logo_data = data
        agency.logo_mime = logo.content_type

    db.add(agency)
    db.commit()
    db.refresh(agency)
    return _agency_to_dict(agency)


@router.put("/agencies/{agency_id}/logo")
async def upload_agency_logo(
    agency_id: int,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
):
    agency = db.query(MatrimonialAgency).filter(MatrimonialAgency.id == agency_id).first()
    if not agency:
        raise HTTPException(status_code=404, detail="Agency not found")

    data = _validate_file(file, ALLOWED_IMAGE_TYPES, MAX_IMAGE_SIZE, "Agency logo")
    agency.logo_data = data
    agency.logo_mime = file.content_type
    db.commit()
    return {"success": True, "message": "Agency logo updated"}


@router.get("/agencies/{agency_id}/logo")
async def get_agency_logo(agency_id: int, db: Session = Depends(get_db)):
    agency = db.query(MatrimonialAgency).filter(MatrimonialAgency.id == agency_id).first()
    if not agency or not agency.logo_data:
        raise HTTPException(status_code=404, detail="No logo found")
    return Response(content=agency.logo_data, media_type=agency.logo_mime or "image/png")


# ─────────────────────────────────────────────────────────────────────────────
# Browse profiles
# ─────────────────────────────────────────────────────────────────────────────

@router.get("/users")
async def get_matrimonial_users(
    location:   Optional[str]    = None,
    gender:     Optional[Gender] = None,
    min_age:    Optional[int]    = None,
    max_age:    Optional[int]    = None,
    page:       int              = Query(1, ge=1),
    page_size:  int              = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
):
    query = db.query(MatrimonialUser).filter(
        MatrimonialUser.status == MatrimonialUserStatus.ACTIVE,
        MatrimonialUser.is_verified == True,
    )
    if location:
        query = query.filter(MatrimonialUser.location.ilike(f"%{location}%"))
    if gender:
        query = query.filter(MatrimonialUser.gender == gender)

    users = query.offset((page - 1) * page_size).limit(page_size).all()
    return [_user_to_dict(u) for u in users]


@router.get("/users/{user_id}")
async def get_matrimonial_user(user_id: int, db: Session = Depends(get_db)):
    user = db.query(MatrimonialUser).filter(MatrimonialUser.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return {"success": True, "profile": _user_to_dict(user)}


@router.get("/agencies")
async def get_matrimonial_agencies(
    location:  Optional[str] = None,
    page:      int           = Query(1, ge=1),
    page_size: int           = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
):
    query = db.query(MatrimonialAgency).filter(
        MatrimonialAgency.status == MatrimonialUserStatus.ACTIVE,
        MatrimonialAgency.is_verified == True,
    )
    if location:
        query = query.filter(MatrimonialAgency.location.ilike(f"%{location}%"))
    agencies = query.offset((page - 1) * page_size).limit(page_size).all()
    return [_agency_to_dict(a) for a in agencies]


# ─────────────────────────────────────────────────────────────────────────────
# Matches
# ─────────────────────────────────────────────────────────────────────────────

@router.post("/matches")
async def create_match(
    request: MatchRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    mat_user = db.query(MatrimonialUser).filter(MatrimonialUser.user_id == current_user.id).first()
    if not mat_user:
        raise HTTPException(status_code=404, detail="Matrimonial profile not found")

    existing = db.query(Match).filter(
        and_(Match.sender_id == mat_user.id, Match.receiver_id == request.receiver_id)
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="Match request already exists")

    match = Match(
        sender_id=mat_user.id,
        receiver_id=request.receiver_id,
        message=request.message,
        status=MatchStatus.PENDING,
    )
    db.add(match)
    db.commit()
    db.refresh(match)
    return {"id": match.id, "sender_id": match.sender_id, "receiver_id": match.receiver_id,
            "status": match.status.value, "message": match.message,
            "created_at": match.created_at.isoformat()}


@router.get("/matches")
async def get_matches(
    status_filter: Optional[MatchStatus] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    mat_user = db.query(MatrimonialUser).filter(MatrimonialUser.user_id == current_user.id).first()
    if not mat_user:
        raise HTTPException(status_code=404, detail="Matrimonial profile not found")

    query = db.query(Match).filter(
        or_(Match.sender_id == mat_user.id, Match.receiver_id == mat_user.id)
    )
    if status_filter:
        query = query.filter(Match.status == status_filter)

    matches = query.all()
    return [{"id": m.id, "sender_id": m.sender_id, "receiver_id": m.receiver_id,
             "status": m.status.value, "message": m.message,
             "created_at": m.created_at.isoformat()} for m in matches]


# ─────────────────────────────────────────────────────────────────────────────
# Dashboard stats
# ─────────────────────────────────────────────────────────────────────────────

@router.get("/dashboard-stats")
async def get_matrimonial_dashboard_stats(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    total_individuals = db.query(MatrimonialUser).filter(
        MatrimonialUser.status == MatrimonialUserStatus.ACTIVE,
        MatrimonialUser.is_verified == True,
    ).count()

    total_agencies = db.query(MatrimonialAgency).filter(
        MatrimonialAgency.status == MatrimonialUserStatus.ACTIVE,
        MatrimonialAgency.is_verified == True,
    ).count()

    recent_individuals = db.query(MatrimonialUser).filter(
        MatrimonialUser.status == MatrimonialUserStatus.ACTIVE,
        MatrimonialUser.is_verified == True,
    ).order_by(MatrimonialUser.created_at.desc()).limit(5).all()

    recent_agencies = db.query(MatrimonialAgency).filter(
        MatrimonialAgency.status == MatrimonialUserStatus.ACTIVE,
        MatrimonialAgency.is_verified == True,
    ).order_by(MatrimonialAgency.created_at.desc()).limit(3).all()

    user_profile = db.query(MatrimonialUser).filter(
        MatrimonialUser.user_id == current_user.id,
        MatrimonialUser.status == MatrimonialUserStatus.ACTIVE,
    ).first()

    recent_profiles = [_user_to_dict(p) for p in recent_individuals]
    for a in recent_agencies:
        d = _agency_to_dict(a)
        d["type"] = "agency"
        recent_profiles.append(d)

    recent_profiles.sort(key=lambda x: x.get("created_at", ""), reverse=True)

    return {
        "success":          True,
        "total_profiles":   total_individuals + total_agencies,
        "total_individuals": total_individuals,
        "total_agencies":   total_agencies,
        "is_registered":    user_profile is not None,
        "recent_profiles":  recent_profiles[:5],
    }
    
    
@router.put("/agencies/{agency_id}/verify")
async def verify_agency(
    agency_id: int,
    is_verified: bool = Query(..., description="Set to true to verify, false to reject"),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),  # Use as dependency
):
    """Admin endpoint to verify or reject an agency."""
    agency = db.query(MatrimonialAgency).filter(MatrimonialAgency.id == agency_id).first()
    if not agency:
        raise HTTPException(status_code=404, detail="Agency not found")
    
    agency.is_verified = is_verified
    if is_verified:
        agency.status = MatrimonialUserStatus.ACTIVE
    else:
        agency.status = MatrimonialUserStatus.INACTIVE
    
    db.commit()
    db.refresh(agency)
    
    return {
        "success": True,
        "message": f"Agency {'verified' if is_verified else 'rejected'} successfully",
        "agency": _agency_to_dict(agency)
    }


@router.get("/agencies/pending")
async def get_pending_agencies(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),  # Use as dependency
):
    """Get all pending agencies awaiting verification (admin only)."""
    query = db.query(MatrimonialAgency).filter(
        MatrimonialAgency.is_verified == False,
        MatrimonialAgency.status == MatrimonialUserStatus.ACTIVE
    )
    
    total = query.count()
    agencies = query.offset((page - 1) * page_size).limit(page_size).all()
    
    return {
        "success": True,
        "total": total,
        "agencies": [_agency_to_dict(a) for a in agencies]
    }
    
    
# Add to matrimonial.py

@router.get("/my-profile")
async def get_my_matrimonial_profile(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get the matrimonial profile for the currently logged-in user."""
    # Check individual profile first
    user_profile = db.query(MatrimonialUser).filter(
        MatrimonialUser.user_id == current_user.id
    ).first()
    
    if user_profile:
        return {
            "success": True,
            "type": "individual",
            "profile": _user_to_dict(user_profile)
        }
    
    # Check agency profile
    agency_profile = db.query(MatrimonialAgency).filter(
        MatrimonialAgency.user_id == current_user.id
    ).first()
    
    if agency_profile:
        return {
            "success": True,
            "type": "agency",
            "profile": _agency_to_dict(agency_profile)
        }
    
    return {
        "success": True,
        "type": None,
        "profile": None
    }
    
    
    
# Update the get_matrimonial_users endpoint to exclude the current user

@router.get("/users")
async def get_matrimonial_users(
    location:   Optional[str]    = None,
    gender:     Optional[Gender] = None,
    min_age:    Optional[int]    = None,
    max_age:    Optional[int]    = None,
    page:       int              = Query(1, ge=1),
    page_size:  int              = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),  # Add this
    db: Session = Depends(get_db),
):
    # Get current user's matrimonial profile ID
    current_mat_user = db.query(MatrimonialUser).filter(
        MatrimonialUser.user_id == current_user.id
    ).first()
    
    query = db.query(MatrimonialUser).filter(
        MatrimonialUser.status == MatrimonialUserStatus.ACTIVE,
        MatrimonialUser.is_verified == True,
    )
    
    # Exclude current user
    if current_mat_user:
        query = query.filter(MatrimonialUser.id != current_mat_user.id)
    
    # For individuals, only show opposite gender
    if current_mat_user:
        opposite_gender = Gender.FEMALE if current_mat_user.gender == Gender.MALE else Gender.MALE
        query = query.filter(MatrimonialUser.gender == opposite_gender)
    elif gender:
        query = query.filter(MatrimonialUser.gender == gender)
    
    if location:
        query = query.filter(MatrimonialUser.location.ilike(f"%{location}%"))
    
    # Age filtering using date_of_birth
    if min_age is not None or max_age is not None:
        today = datetime.now().date()
        if min_age is not None:
            max_dob = today.replace(year=today.year - min_age)
            query = query.filter(MatrimonialUser.date_of_birth <= max_dob)
        if max_age is not None:
            min_dob = today.replace(year=today.year - max_age - 1)
            query = query.filter(MatrimonialUser.date_of_birth >= min_dob)

    users = query.offset((page - 1) * page_size).limit(page_size).all()
    return [_user_to_dict(u) for u in users]




# Add to matrimonial.py

@router.get("/agencies/available-users")
async def get_agency_available_users(
    location:   Optional[str] = None,
    gender:     Optional[Gender] = None,
    min_age:    Optional[int] = None,
    max_age:    Optional[int] = None,
    page:       int = Query(1, ge=1),
    page_size:  int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get individual users for agencies to browse (agencies only)."""
    # Check if current user has an agency profile
    agency = db.query(MatrimonialAgency).filter(
        MatrimonialAgency.user_id == current_user.id,
        MatrimonialAgency.is_verified == True,
        MatrimonialAgency.status == MatrimonialUserStatus.ACTIVE
    ).first()
    
    if not agency:
        raise HTTPException(status_code=403, detail="Only verified agencies can access this endpoint")
    
    query = db.query(MatrimonialUser).filter(
        MatrimonialUser.status == MatrimonialUserStatus.ACTIVE,
        MatrimonialUser.is_verified == True,
    )
    
    if location:
        query = query.filter(MatrimonialUser.location.ilike(f"%{location}%"))
    if gender:
        query = query.filter(MatrimonialUser.gender == gender)
    
    # Age filtering
    if min_age is not None or max_age is not None:
        today = datetime.now().date()
        if min_age is not None:
            max_dob = today.replace(year=today.year - min_age)
            query = query.filter(MatrimonialUser.date_of_birth <= max_dob)
        if max_age is not None:
            min_dob = today.replace(year=today.year - max_age - 1)
            query = query.filter(MatrimonialUser.date_of_birth >= min_dob)
    
    total = query.count()
    users = query.offset((page - 1) * page_size).limit(page_size).all()
    
    return {
        "success": True,
        "total": total,
        "users": [_user_to_dict(u) for u in users]
    }
    


# Add to matrimonial.py

@router.put("/matches/{match_id}/status")
async def update_match_status(
    match_id: int,
    status: MatchStatus,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Accept or reject a match request."""
    match = db.query(Match).filter(Match.id == match_id).first()
    if not match:
        raise HTTPException(status_code=404, detail="Match not found")
    
    # Get current user's matrimonial profile
    current_mat_user = db.query(MatrimonialUser).filter(
        MatrimonialUser.user_id == current_user.id
    ).first()
    
    if not current_mat_user:
        raise HTTPException(status_code=404, detail="Matrimonial profile not found")
    
    # Only the receiver can update the status
    if match.receiver_id != current_mat_user.id:
        raise HTTPException(status_code=403, detail="You cannot update this match")
    
    match.status = status
    match.responded_at = datetime.now()
    
    db.commit()
    db.refresh(match)
    
    return {
        "success": True,
        "match": {
            "id": match.id,
            "status": match.status.value,
            "responded_at": match.responded_at.isoformat()
        }
    }
    


# Add to matrimonial.py

@router.get("/my-matches")
async def get_my_matches_detailed(
    status_filter: Optional[MatchStatus] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get all matches for the current user with profile details."""
    mat_user = db.query(MatrimonialUser).filter(
        MatrimonialUser.user_id == current_user.id
    ).first()
    
    if not mat_user:
        raise HTTPException(status_code=404, detail="Matrimonial profile not found")
    
    query = db.query(Match).filter(
        or_(Match.sender_id == mat_user.id, Match.receiver_id == mat_user.id)
    )
    
    if status_filter:
        query = query.filter(Match.status == status_filter)
    
    matches = query.order_by(Match.created_at.desc()).all()
    
    result = []
    for match in matches:
        # Get the other party's profile
        other_user_id = match.receiver_id if match.sender_id == mat_user.id else match.sender_id
        other_user = db.query(MatrimonialUser).filter(MatrimonialUser.id == other_user_id).first()
        
        result.append({
            "id": match.id,
            "status": match.status.value,
            "message": match.message,
            "created_at": match.created_at.isoformat(),
            "responded_at": match.responded_at.isoformat() if match.responded_at else None,
            "is_sender": match.sender_id == mat_user.id,
            "other_party": _user_to_dict(other_user) if other_user else None
        })
    
    return {
        "success": True,
        "matches": result
    }