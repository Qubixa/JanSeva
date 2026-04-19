from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import or_, func
from typing import Optional, List
from datetime import datetime

from app.core.database import get_db
from app.core.security import get_current_user, require_role
from app.models.user import User, UserRole
from app.models.emergency import EmergencyService, EmergencyServiceType
from app.models.scheme import Scheme, SchemeCategory
from app.models.contact import Contact, ContactType
from app.models.notification import Notification, UserNotification, NotificationType
from app.models.transport import Transport, TransportType, JobVacancy, RTIInfo
from app.models.ward import Ward
from app.schemas.services import (
    EmergencyServiceResponse, EmergencyServiceCreate, EmergencyServiceUpdate,
    SchemeResponse, SchemeCreate, SchemeUpdate,
    JobVacancyResponse, JobVacancyCreate, JobVacancyUpdate,
    RTIInfoResponse, RTIInfoCreate, RTIInfoUpdate,
    NoticeResponse, NoticeCreate, NoticeUpdate,
    TransportResponse, TransportCreate, TransportUpdate
)
from app.schemas.common import MessageResponse

router = APIRouter(tags=["Services"])


# ─── Helper ────────────────────────────────────────────────────────────────────
def to_yn(value) -> str:
    """Convert any truthy/boolean/string value to 'Y' or 'N'."""
    if value is None:
        return "N"
    if isinstance(value, bool):
        return "Y" if value else "N"
    if isinstance(value, str):
        return "Y" if value.upper() in ("Y", "YES", "TRUE", "1") else "N"
    return "Y" if value else "N"


# ==================== EMERGENCY SERVICES ====================
@router.get("/emergency", response_model=List[EmergencyServiceResponse])
async def get_emergency_services(
    type: Optional[str] = None,
    category: Optional[str] = None,
    ward_id: Optional[int] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get emergency services. Citizens can view any ward's services. Ward admins see only their ward."""
    query = db.query(EmergencyService).filter(EmergencyService.is_active == "Y")

    if current_user.role == UserRole.CITIZEN or current_user.role == UserRole.FIELD_OFFICER:
        if ward_id:
            query = query.filter(
                or_(
                    EmergencyService.ward_id == ward_id,
                    EmergencyService.is_citywide == "Y"
                )
            )
    elif current_user.role == UserRole.WARD_ADMIN:
        query = query.filter(
            or_(
                EmergencyService.ward_id == current_user.ward_id,
                EmergencyService.is_citywide == "Y"
            )
        )
    elif current_user.role == UserRole.SUPER_ADMIN and ward_id:
        query = query.filter(EmergencyService.ward_id == ward_id)

    if type:
        query = query.filter(EmergencyService.type == type)
    if category:
        query = query.filter(EmergencyService.category == category)

    return query.all()


@router.get("/contacts", response_model=List[dict])
async def get_contacts(
    department: Optional[str] = None,
    search: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """Get important contacts (public)"""
    query = db.query(Contact).filter(Contact.is_active == "Y")

    if department:
        query = query.filter(Contact.department == department)
    if search:
        query = query.filter(
            or_(
                Contact.name.ilike(f"%{search}%"),
                Contact.department.ilike(f"%{search}%"),
                Contact.designation.ilike(f"%{search}%")
            )
        )

    contacts = query.order_by(Contact.department, Contact.name).all()
    return [{
        "id": c.id,
        "name": c.name,
        "department": c.department,
        "designation": c.designation,
        "phone": c.phone,
        "email": c.email,
        "office_address": c.office_address,
        "is_active": c.is_active
    } for c in contacts]


# ==================== WARDS ====================
@router.get("/wards", response_model=List[dict])
async def get_wards(db: Session = Depends(get_db)):
    """Get all wards (public)"""
    wards = db.query(Ward).order_by(Ward.name).all()
    return [{"id": w.id, "name": w.name} for w in wards]


# ==================== EMERGENCY ADMIN ====================
@router.post("/admin/emergency", response_model=EmergencyServiceResponse)
async def create_emergency_service(
    request: EmergencyServiceCreate,
    current_user: User = Depends(require_role([UserRole.WARD_ADMIN, UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    if current_user.role == UserRole.WARD_ADMIN:
        if request.ward_id and request.ward_id != current_user.ward_id:
            raise HTTPException(status_code=403, detail="You can only manage services for your ward")
        ward_id = current_user.ward_id
    else:
        ward_id = request.ward_id

    service = EmergencyService(
        **{k: v for k, v in request.model_dump().items() if k not in ("is_citywide", "is_24x7", "ward_id")},
        ward_id=ward_id,
        is_citywide=to_yn(request.is_citywide),
        is_24x7=to_yn(request.is_24x7),
        created_by=current_user.id,
    )
    db.add(service)
    db.commit()
    db.refresh(service)
    return service


@router.get("/admin/emergency", response_model=List[EmergencyServiceResponse])
async def list_emergency_services_admin(
    ward_id: Optional[int] = None,
    category: Optional[str] = None,
    current_user: User = Depends(require_role([UserRole.WARD_ADMIN, UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    query = db.query(EmergencyService)
    if current_user.role == UserRole.WARD_ADMIN:
        query = query.filter(EmergencyService.ward_id == current_user.ward_id)
    elif ward_id:
        query = query.filter(EmergencyService.ward_id == ward_id)
    if category:
        query = query.filter(EmergencyService.category == category)
    return query.all()


@router.put("/admin/emergency/{service_id}", response_model=EmergencyServiceResponse)
async def update_emergency_service(
    service_id: int,
    request: EmergencyServiceUpdate,
    current_user: User = Depends(require_role([UserRole.WARD_ADMIN, UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    service = db.query(EmergencyService).filter(EmergencyService.id == service_id).first()
    if not service:
        raise HTTPException(status_code=404, detail="Service not found")
    if current_user.role == UserRole.WARD_ADMIN and service.ward_id != current_user.ward_id:
        raise HTTPException(status_code=403, detail="Not authorized")

    update_data = request.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        if key in ("is_citywide", "is_24x7", "is_active"):
            setattr(service, key, to_yn(value))
        else:
            setattr(service, key, value)

    service.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(service)
    return service


@router.delete("/admin/emergency/{service_id}", response_model=MessageResponse)
async def delete_emergency_service(
    service_id: int,
    current_user: User = Depends(require_role([UserRole.WARD_ADMIN, UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    service = db.query(EmergencyService).filter(EmergencyService.id == service_id).first()
    if not service:
        raise HTTPException(status_code=404, detail="Service not found")
    if current_user.role == UserRole.WARD_ADMIN and service.ward_id != current_user.ward_id:
        raise HTTPException(status_code=403, detail="Not authorized")
    service.is_active = "N"
    db.commit()
    return MessageResponse(message="Service deleted successfully")


# ==================== SCHEMES ====================
@router.get("/schemes")
async def get_schemes(
    category: Optional[str] = None,
    search: Optional[str] = None,
    db: Session = Depends(get_db)
):
    query = db.query(Scheme).filter(Scheme.is_active == "Y")
    if category:
        query = query.filter(Scheme.category == category)
    if search:
        query = query.filter(
            or_(
                Scheme.name.ilike(f"%{search}%"),
                Scheme.description.ilike(f"%{search}%")
            )
        )
    schemes = query.order_by(Scheme.created_at.desc()).all()
    return [
        {
            "id": s.id,
            "name": s.name,
            "description": s.description,
            "category": s.category,
            "eligibility": s.eligibility,
            "benefits_description": s.benefits,
            "application_process": getattr(s, 'application_process', None),
            "contact_info": getattr(s, 'contact_info', None),
            "last_updated": s.created_at,
        }
        for s in schemes
    ]


# @router.post("/admin/schemes", response_model=SchemeResponse)
# async def create_scheme(
#     request: SchemeCreate,
#     current_user: User = Depends(require_role([UserRole.WARD_ADMIN, UserRole.SUPER_ADMIN])),
#     db: Session = Depends(get_db)
# ):
#     scheme = Scheme(**request.model_dump())
#     db.add(scheme)
#     db.commit()
#     db.refresh(scheme)
#     return scheme


# @router.put("/admin/schemes/{scheme_id}", response_model=SchemeResponse)
# async def update_scheme(
#     scheme_id: int,
#     request: SchemeUpdate,
#     current_user: User = Depends(require_role([UserRole.WARD_ADMIN, UserRole.SUPER_ADMIN])),
#     db: Session = Depends(get_db)
# ):
#     scheme = db.query(Scheme).filter(Scheme.id == scheme_id).first()
#     if not scheme:
#         raise HTTPException(status_code=404, detail="Scheme not found")
#     update_data = request.model_dump(exclude_unset=True)
#     for key, value in update_data.items():
#         if key == "is_active":
#             setattr(scheme, key, to_yn(value))
#         else:
#             setattr(scheme, key, value)
#     db.commit()
#     db.refresh(scheme)
#     return scheme


# ==================== JOB VACANCIES ====================
@router.get("/jobs", response_model=List[JobVacancyResponse])
async def get_jobs(
    search: Optional[str] = None,
    db: Session = Depends(get_db)
):
    query = db.query(JobVacancy).filter(JobVacancy.is_active == "Y")
    if search:
        query = query.filter(
            or_(
                JobVacancy.title.ilike(f"%{search}%"),
                JobVacancy.organization.ilike(f"%{search}%")
            )
        )
    return query.order_by(JobVacancy.created_at.desc()).all()


@router.post("/admin/jobs", response_model=JobVacancyResponse)
async def create_job(
    request: JobVacancyCreate,
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    job = JobVacancy(**request.model_dump())
    db.add(job)
    db.commit()
    db.refresh(job)
    return job


@router.put("/admin/jobs/{job_id}", response_model=JobVacancyResponse)
async def update_job(
    job_id: int,
    request: JobVacancyUpdate,
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    job = db.query(JobVacancy).filter(JobVacancy.id == job_id).first()
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
    update_data = request.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        if key == "is_active":
            setattr(job, key, to_yn(value))
        else:
            setattr(job, key, value)
    db.commit()
    db.refresh(job)
    return job


# ==================== RTI ====================
@router.get("/rti", response_model=List[RTIInfoResponse])
async def get_rti_info(db: Session = Depends(get_db)):
    return db.query(RTIInfo).filter(RTIInfo.is_active == "Y").order_by(RTIInfo.display_order).all()


@router.post("/admin/rti", response_model=RTIInfoResponse)
async def create_rti_info(
    request: RTIInfoCreate,
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    rti = RTIInfo(**request.model_dump())
    db.add(rti)
    db.commit()
    db.refresh(rti)
    return rti


@router.put("/admin/rti/{rti_id}", response_model=RTIInfoResponse)
async def update_rti_info(
    rti_id: int,
    request: RTIInfoUpdate,
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    rti = db.query(RTIInfo).filter(RTIInfo.id == rti_id).first()
    if not rti:
        raise HTTPException(status_code=404, detail="RTI info not found")
    update_data = request.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        if key == "is_active":
            setattr(rti, key, to_yn(value))
        else:
            setattr(rti, key, value)
    db.commit()
    db.refresh(rti)
    return rti


# ==================== NOTICES ====================
@router.post("/admin/notices", response_model=NoticeResponse)
async def create_notice(
    request: NoticeCreate,
    current_user: User = Depends(require_role([UserRole.WARD_ADMIN, UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    ward_id = request.ward_id
    if current_user.role == UserRole.WARD_ADMIN:
        ward_id = current_user.ward_id

    notif = Notification(
        title=request.title,
        message=request.message,
        notification_type=request.notice_type,
        ward_id=ward_id,
        target_role=request.target_role,
        expires_at=request.expires_at
    )
    db.add(notif)
    db.commit()
    db.refresh(notif)

    return NoticeResponse(
        id=notif.id, title=notif.title, message=notif.message,
        notice_type=notif.notification_type, ward_id=notif.ward_id,
        target_role=notif.target_role, is_active=notif.is_active,
        created_at=notif.created_at, expires_at=notif.expires_at
    )


@router.put("/admin/notices/{notice_id}", response_model=NoticeResponse)
async def update_notice(
    notice_id: int,
    request: NoticeUpdate,
    current_user: User = Depends(require_role([UserRole.WARD_ADMIN, UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    notif = db.query(Notification).filter(Notification.id == notice_id).first()
    if not notif:
        raise HTTPException(status_code=404, detail="Notice not found")
    if current_user.role == UserRole.WARD_ADMIN and notif.ward_id != current_user.ward_id:
        raise HTTPException(status_code=403, detail="Not authorized")

    update_data = request.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        if key == "notice_type":
            setattr(notif, "notification_type", value)
        elif key == "is_active":
            notif.is_active = to_yn(value)
        else:
            setattr(notif, key, value)

    db.commit()
    db.refresh(notif)

    return NoticeResponse(
        id=notif.id, title=notif.title, message=notif.message,
        notice_type=notif.notification_type, ward_id=notif.ward_id,
        target_role=notif.target_role, is_active=notif.is_active,
        created_at=notif.created_at, expires_at=notif.expires_at
    )


# ==================== TRANSPORT ====================
@router.get("/transport", response_model=List[TransportResponse])
async def get_transport(
    type: Optional[str] = None,
    search: Optional[str] = None,
    db: Session = Depends(get_db)
):
    query = db.query(Transport).filter(Transport.is_active == "Y")
    if type:
        query = query.filter(Transport.transport_type == type)
    if search:
        query = query.filter(
            or_(
                Transport.name.ilike(f"%{search}%"),
                Transport.source.ilike(f"%{search}%"),
                Transport.destination.ilike(f"%{search}%")
            )
        )
    return query.all()


@router.post("/admin/transport", response_model=TransportResponse)
async def create_transport(
    request: TransportCreate,
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    transport = Transport(**request.model_dump())
    db.add(transport)
    db.commit()
    db.refresh(transport)
    return transport


@router.put("/admin/transport/{transport_id}", response_model=TransportResponse)
async def update_transport(
    transport_id: int,
    request: TransportUpdate,
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    transport = db.query(Transport).filter(Transport.id == transport_id).first()
    if not transport:
        raise HTTPException(status_code=404, detail="Transport not found")
    update_data = request.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        if key == "is_active":
            setattr(transport, key, to_yn(value))
        else:
            setattr(transport, key, value)
    db.commit()
    db.refresh(transport)
    return transport


# ==================== ADMIN EMERGENCY SERVICES ====================
@router.get("/admin/emergency/services", response_model=List[EmergencyServiceResponse])
async def admin_get_emergency_services(
    ward_id: Optional[int] = None,
    type: Optional[str] = None,
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN, UserRole.WARD_ADMIN])),
    db: Session = Depends(get_db)
):
    query = db.query(EmergencyService)
    if current_user.role == UserRole.WARD_ADMIN:
        query = query.filter(EmergencyService.ward_id == current_user.ward_id)
    elif ward_id:
        query = query.filter(EmergencyService.ward_id == ward_id)
    if type:
        query = query.filter(EmergencyService.type == type)
    return query.order_by(EmergencyService.created_at.desc()).all()


@router.post("/admin/emergency/services", response_model=EmergencyServiceResponse)
async def admin_create_emergency_service(
    request: EmergencyServiceCreate,
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN, UserRole.WARD_ADMIN])),
    db: Session = Depends(get_db)
):
    ward_id = request.ward_id
    if current_user.role == UserRole.WARD_ADMIN:
        if request.ward_id and request.ward_id != current_user.ward_id:
            raise HTTPException(status_code=403, detail="Cannot create for other wards")
        ward_id = current_user.ward_id

    service = EmergencyService(
        name=request.name,
        type=request.type,
        phone=request.phone,
        alternate_phone=request.alternate_phone,
        email=request.email,
        address=request.address,
        google_maps_link=request.google_maps_link,
        latitude=request.latitude,
        longitude=request.longitude,
        ward_id=ward_id,
        category=request.category,
        is_citywide=to_yn(request.is_citywide),
        is_24x7=to_yn(request.is_24x7),
        created_by=current_user.id
    )
    db.add(service)
    db.commit()
    db.refresh(service)
    return service


@router.put("/admin/emergency/services/{service_id}", response_model=EmergencyServiceResponse)
async def admin_update_emergency_service(
    service_id: int,
    request: EmergencyServiceUpdate,
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN, UserRole.WARD_ADMIN])),
    db: Session = Depends(get_db)
):
    service = db.query(EmergencyService).filter(EmergencyService.id == service_id).first()
    if not service:
        raise HTTPException(status_code=404, detail="Service not found")
    if current_user.role == UserRole.WARD_ADMIN and service.ward_id != current_user.ward_id:
        raise HTTPException(status_code=403, detail="Not authorized")

    update_data = request.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        if key in ("is_citywide", "is_24x7", "is_active"):
            setattr(service, key, to_yn(value))
        else:
            setattr(service, key, value)

    service.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(service)
    return service


@router.delete("/admin/emergency/services/{service_id}", response_model=MessageResponse)
async def admin_delete_emergency_service(
    service_id: int,
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN, UserRole.WARD_ADMIN])),
    db: Session = Depends(get_db)
):
    service = db.query(EmergencyService).filter(EmergencyService.id == service_id).first()
    if not service:
        raise HTTPException(status_code=404, detail="Service not found")
    if current_user.role == UserRole.WARD_ADMIN and service.ward_id != current_user.ward_id:
        raise HTTPException(status_code=403, detail="Not authorized")
    service.is_active = "N"
    db.commit()
    return MessageResponse(message="Service deleted successfully")


# ==================== ADMIN SCHEMES ====================
@router.get("/admin/schemes", response_model=List[SchemeResponse])
async def admin_get_schemes(
    category: Optional[str] = None,
    is_active: Optional[bool] = None,
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    query = db.query(Scheme)
    if category:
        query = query.filter(Scheme.category == category)
    if is_active is not None:
        query = query.filter(Scheme.is_active == to_yn(is_active))

    schemes = query.order_by(Scheme.created_at.desc()).all()
    return [
        SchemeResponse(
            id=s.id,
            title=s.name,
            description=s.description,
            category=s.category,
            eligibility=s.eligibility,
            benefits=s.benefits,
            required_documents=s.documents,
            application_steps=None,
            official_link=s.application_url,
            is_active=s.is_active == "Y",
            created_at=s.created_at
        )
        for s in schemes
    ]


@router.post("/admin/schemes", response_model=SchemeResponse)
async def admin_create_scheme(
    request: SchemeCreate,
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    scheme = Scheme(
        name=request.title,
        description=request.description,
        category=request.category,
        eligibility=request.eligibility,
        benefits=request.benefits,
        documents=request.required_documents,
        application_url=request.official_link,
        deadline=request.deadline,
        is_active="Y"
    )
    db.add(scheme)
    db.commit()
    db.refresh(scheme)
    return SchemeResponse(
        id=scheme.id, title=scheme.name, description=scheme.description,
        category=scheme.category, eligibility=scheme.eligibility,
        benefits=scheme.benefits, required_documents=scheme.documents,
        application_steps=request.application_steps,
        official_link=scheme.application_url,
        is_active=scheme.is_active == "Y", created_at=scheme.created_at
    )


@router.put("/admin/schemes/{scheme_id}", response_model=SchemeResponse)
async def admin_update_scheme(
    scheme_id: int,
    request: SchemeUpdate,
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    scheme = db.query(Scheme).filter(Scheme.id == scheme_id).first()
    if not scheme:
        raise HTTPException(status_code=404, detail="Scheme not found")

    if request.title is not None:         scheme.name = request.title
    if request.description is not None:   scheme.description = request.description
    if request.category is not None:      scheme.category = request.category
    if request.eligibility is not None:   scheme.eligibility = request.eligibility
    if request.benefits is not None:      scheme.benefits = request.benefits
    if request.required_documents is not None: scheme.documents = request.required_documents
    if request.official_link is not None: scheme.application_url = request.official_link
    if request.is_active is not None:     scheme.is_active = to_yn(request.is_active)  # ← THE FIX

    db.commit()
    db.refresh(scheme)
    return SchemeResponse(
        id=scheme.id, title=scheme.name, description=scheme.description,
        category=scheme.category, eligibility=scheme.eligibility,
        benefits=scheme.benefits, required_documents=scheme.documents,
        application_steps=None, official_link=scheme.application_url,
        is_active=scheme.is_active == "Y", created_at=scheme.created_at
    )


@router.delete("/admin/schemes/{scheme_id}", response_model=MessageResponse)
async def admin_delete_scheme(
    scheme_id: int,
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    scheme = db.query(Scheme).filter(Scheme.id == scheme_id).first()
    if not scheme:
        raise HTTPException(status_code=404, detail="Scheme not found")
    scheme.is_active = "N"
    db.commit()
    return MessageResponse(message="Scheme deleted successfully")


# ==================== ADMIN JOBS ====================
@router.get("/admin/jobs", response_model=List[JobVacancyResponse])
async def admin_get_jobs(
    is_active: Optional[bool] = None,
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    query = db.query(JobVacancy)
    if is_active is not None:
        query = query.filter(JobVacancy.is_active == to_yn(is_active))
    return query.order_by(JobVacancy.created_at.desc()).all()


@router.post("/admin/jobs", response_model=JobVacancyResponse)
async def admin_create_job(
    request: JobVacancyCreate,
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    job = JobVacancy(**request.model_dump())
    db.add(job)
    db.commit()
    db.refresh(job)
    return job


@router.put("/admin/jobs/{job_id}", response_model=JobVacancyResponse)
async def admin_update_job(
    job_id: int,
    request: JobVacancyUpdate,
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    job = db.query(JobVacancy).filter(JobVacancy.id == job_id).first()
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
    update_data = request.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        if key == "is_active":
            setattr(job, key, to_yn(value))
        else:
            setattr(job, key, value)
    db.commit()
    db.refresh(job)
    return job


@router.delete("/admin/jobs/{job_id}", response_model=MessageResponse)
async def admin_delete_job(
    job_id: int,
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    job = db.query(JobVacancy).filter(JobVacancy.id == job_id).first()
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
    job.is_active = "N"
    db.commit()
    return MessageResponse(message="Job deleted successfully")


# ==================== ADMIN RTI ====================
@router.get("/admin/rti", response_model=List[RTIInfoResponse])
async def admin_get_rti(
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    return db.query(RTIInfo).order_by(RTIInfo.display_order).all()


@router.post("/admin/rti", response_model=RTIInfoResponse)
async def admin_create_rti(
    request: RTIInfoCreate,
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    rti = RTIInfo(**request.model_dump())
    db.add(rti)
    db.commit()
    db.refresh(rti)
    return rti


@router.put("/admin/rti/{rti_id}", response_model=RTIInfoResponse)
async def admin_update_rti(
    rti_id: int,
    request: RTIInfoUpdate,
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    rti = db.query(RTIInfo).filter(RTIInfo.id == rti_id).first()
    if not rti:
        raise HTTPException(status_code=404, detail="RTI info not found")
    update_data = request.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        if key == "is_active":
            setattr(rti, key, to_yn(value))
        else:
            setattr(rti, key, value)
    db.commit()
    db.refresh(rti)
    return rti


@router.delete("/admin/rti/{rti_id}", response_model=MessageResponse)
async def admin_delete_rti(
    rti_id: int,
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    rti = db.query(RTIInfo).filter(RTIInfo.id == rti_id).first()
    if not rti:
        raise HTTPException(status_code=404, detail="RTI info not found")
    rti.is_active = "N"
    db.commit()
    return MessageResponse(message="RTI info deleted successfully")


# ==================== ADMIN TRANSPORT ====================
@router.get("/admin/transport", response_model=List[TransportResponse])
async def admin_get_transport(
    transport_type: Optional[str] = None,
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    query = db.query(Transport)
    if transport_type:
        query = query.filter(Transport.transport_type == transport_type)
    return query.order_by(Transport.created_at.desc()).all()


@router.post("/admin/transport", response_model=TransportResponse)
async def admin_create_transport(
    request: TransportCreate,
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    transport = Transport(**request.model_dump())
    db.add(transport)
    db.commit()
    db.refresh(transport)
    return transport


@router.put("/admin/transport/{transport_id}", response_model=TransportResponse)
async def admin_update_transport(
    transport_id: int,
    request: TransportUpdate,
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    transport = db.query(Transport).filter(Transport.id == transport_id).first()
    if not transport:
        raise HTTPException(status_code=404, detail="Transport not found")
    update_data = request.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        if key == "is_active":
            setattr(transport, key, to_yn(value))
        else:
            setattr(transport, key, value)
    db.commit()
    db.refresh(transport)
    return transport


@router.delete("/admin/transport/{transport_id}", response_model=MessageResponse)
async def admin_delete_transport(
    transport_id: int,
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    transport = db.query(Transport).filter(Transport.id == transport_id).first()
    if not transport:
        raise HTTPException(status_code=404, detail="Transport not found")
    transport.is_active = "N"
    db.commit()
    return MessageResponse(message="Transport deleted successfully")


# ==================== ADMIN NOTICES ====================
@router.get("/admin/notices", response_model=List[NoticeResponse])
async def admin_get_notices(
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN, UserRole.WARD_ADMIN])),
    db: Session = Depends(get_db)
):
    query = db.query(Notification)
    if current_user.role == UserRole.WARD_ADMIN:
        query = query.filter(
            or_(
                Notification.ward_id == current_user.ward_id,
                Notification.ward_id == None
            )
        )
    notices = query.order_by(Notification.created_at.desc()).all()
    return [
        NoticeResponse(
            id=n.id, title=n.title, message=n.message,
            notice_type=n.notification_type, ward_id=n.ward_id,
            target_role=n.target_role, is_active=n.is_active == "Y",
            created_at=n.created_at, expires_at=n.expires_at
        )
        for n in notices
    ]

@router.post("/admin/notices", response_model=NoticeResponse)
async def admin_create_notice(
    request: NoticeCreate,
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN, UserRole.WARD_ADMIN])),
    db: Session = Depends(get_db)
):
    ward_id = request.ward_id
    if current_user.role == UserRole.WARD_ADMIN:
        if request.ward_id and request.ward_id != current_user.ward_id:
            raise HTTPException(status_code=403, detail="Cannot create for other wards")
        ward_id = current_user.ward_id

    # Strip empty string → None so SQLEnum column doesn't receive an invalid value
    target_role = request.target_role if request.target_role else None

    notice = Notification(
        title=request.title,
        message=request.message,
        notification_type=request.notice_type,
        ward_id=ward_id,
        target_role=target_role,
        expires_at=request.expires_at,
        is_active="Y"
    )
    db.add(notice)
    db.commit()
    db.refresh(notice)
    return NoticeResponse(
        id=notice.id, title=notice.title, message=notice.message,
        notice_type=notice.notification_type, ward_id=notice.ward_id,
        target_role=notice.target_role, is_active=notice.is_active == "Y",
        created_at=notice.created_at, expires_at=notice.expires_at
    )


@router.put("/admin/notices/{notice_id}", response_model=NoticeResponse)
async def admin_update_notice(
    notice_id: int,
    request: NoticeUpdate,
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN, UserRole.WARD_ADMIN])),
    db: Session = Depends(get_db)
):
    notice = db.query(Notification).filter(Notification.id == notice_id).first()
    if not notice:
        raise HTTPException(status_code=404, detail="Notice not found")
    if current_user.role == UserRole.WARD_ADMIN and notice.ward_id != current_user.ward_id:
        raise HTTPException(status_code=403, detail="Not authorized")

    update_data = request.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        if key == "notice_type":
            notice.notification_type = value
        elif key == "is_active":
            notice.is_active = to_yn(value)
        elif key == "target_role":
            # Strip empty string → None so SQLEnum column stays valid
            notice.target_role = value if value else None
        else:
            setattr(notice, key, value)

    db.commit()
    db.refresh(notice)
    return NoticeResponse(
        id=notice.id, title=notice.title, message=notice.message,
        notice_type=notice.notification_type, ward_id=notice.ward_id,
        target_role=notice.target_role, is_active=notice.is_active == "Y",
        created_at=notice.created_at, expires_at=notice.expires_at
    )

@router.delete("/admin/notices/{notice_id}", response_model=MessageResponse)
async def admin_delete_notice(
    notice_id: int,
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN, UserRole.WARD_ADMIN])),
    db: Session = Depends(get_db)
):
    notice = db.query(Notification).filter(Notification.id == notice_id).first()
    if not notice:
        raise HTTPException(status_code=404, detail="Notice not found")
    if current_user.role == UserRole.WARD_ADMIN and notice.ward_id != current_user.ward_id:
        raise HTTPException(status_code=403, detail="Not authorized")
    notice.is_active = "N"
    db.commit()
    return MessageResponse(message="Notice deleted successfully")


# ==================== MATRIMONIAL DASHBOARD ====================
from app.models.matrimonial import MatrimonialUser, MatrimonialAgency


@router.get("/matrimonial/dashboard-stats")
async def get_matrimonial_dashboard_stats(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    total_individuals = db.query(MatrimonialUser).filter(
        MatrimonialUser.status == "ACTIVE", MatrimonialUser.is_verified == True
    ).count()
    total_agencies = db.query(MatrimonialAgency).filter(
        MatrimonialAgency.status == "ACTIVE", MatrimonialAgency.is_verified == True
    ).count()
    total_profiles = total_individuals + total_agencies

    recent_individuals = db.query(MatrimonialUser).filter(
        MatrimonialUser.status == "ACTIVE", MatrimonialUser.is_verified == True
    ).order_by(MatrimonialUser.created_at.desc()).limit(5).all()

    recent_agencies = db.query(MatrimonialAgency).filter(
        MatrimonialAgency.status == "ACTIVE", MatrimonialAgency.is_verified == True
    ).order_by(MatrimonialAgency.created_at.desc()).limit(3).all()

    user_profile = db.query(MatrimonialUser).filter(
        MatrimonialUser.user_id == current_user.id,
        MatrimonialUser.status == "ACTIVE"
    ).first()

    recent_profiles = []
    for p in recent_individuals:
        recent_profiles.append({
            "id": p.id,
            "name": f"{p.first_name} {p.last_name}",
            "profession": p.occupation,
            "location": p.location,
            "photo_url": p.profile_image,
            "age": (datetime.now().date() - p.date_of_birth).days // 365 if p.date_of_birth else None,
            "gender": p.gender.value if hasattr(p.gender, 'value') else str(p.gender),
            "type": "individual",
            "is_verified": p.is_verified,
            "created_at": p.created_at.isoformat()
        })
    for a in recent_agencies:
        recent_profiles.append({
            "id": a.id,
            "name": a.agency_name,
            "profession": "Matrimonial Agency",
            "location": a.location,
            "photo_url": None,
            "age": None,
            "gender": None,
            "type": "agency",
            "is_verified": a.is_verified,
            "created_at": a.created_at.isoformat()
        })

    recent_profiles.sort(key=lambda x: x['created_at'], reverse=True)
    recent_profiles = recent_profiles[:5]

    return {
        "success": True,
        "total_profiles": total_profiles,
        "total_individuals": total_individuals,
        "total_agencies": total_agencies,
        "is_registered": user_profile is not None,
        "recent_profiles": recent_profiles
    }


# ==================== PUBLIC NOTICES ====================
@router.get("/services/notices")
async def get_notices(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    from sqlalchemy import or_
    now = datetime.utcnow()

    query = db.query(Notification).filter(
        Notification.is_active == 'Y',
        or_(Notification.expires_at == None, Notification.expires_at > now),
    )
    query = query.filter(
        or_(Notification.target_role == None, Notification.target_role == current_user.role.value)
    )
    query = query.filter(
        or_(Notification.ward_id == None, Notification.ward_id == current_user.ward_id)
    )

    notices = query.order_by(Notification.created_at.desc()).all()
    return [
        {
            "id": n.id, "title": n.title, "message": n.message,
            "notice_type": n.notification_type.value, "ward_id": n.ward_id,
            "target_role": n.target_role.value if n.target_role else None,
            "is_active": n.is_active == 'Y',
            "expires_at": n.expires_at.isoformat() if n.expires_at else None,
            "created_at": n.created_at.isoformat(),
        }
        for n in notices
    ]


@router.get("/services/notices/{notice_id}")
async def get_notice_by_id(
    notice_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    now = datetime.utcnow()
    notice = db.query(Notification).filter(
        Notification.id == notice_id,
        Notification.is_active == 'Y',
        or_(Notification.expires_at == None, Notification.expires_at > now),
    ).first()

    if not notice:
        raise HTTPException(status_code=404, detail="Notice not found")
    if notice.target_role and notice.target_role != current_user.role:
        raise HTTPException(status_code=403, detail="Not authorized")
    if notice.ward_id and notice.ward_id != current_user.ward_id:
        raise HTTPException(status_code=403, detail="Not authorized")

    return {
        "id": notice.id, "title": notice.title, "message": notice.message,
        "notice_type": notice.notification_type.value, "ward_id": notice.ward_id,
        "target_role": notice.target_role.value if notice.target_role else None,
        "is_active": notice.is_active == 'Y',
        "expires_at": notice.expires_at.isoformat() if notice.expires_at else None,
        "created_at": notice.created_at.isoformat(),
    }