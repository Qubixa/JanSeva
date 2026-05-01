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
    
    # Citizens and Field Officers can view all wards' services or filter by specific ward
    if current_user.role == UserRole.CITIZEN or current_user.role == UserRole.FIELD_OFFICER:
        # If ward_id is specified, show only that ward's services
        # Otherwise, show all services (citizen can select any ward)
        if ward_id:
            query = query.filter(
                or_(
                    EmergencyService.ward_id == ward_id,
                    EmergencyService.is_citywide == True
                )
            )
        # If no ward_id specified, show all active services (citywide + all wards)
    elif current_user.role == UserRole.WARD_ADMIN:
        # Ward admin sees only their ward services + citywide
        query = query.filter(
            or_(
                EmergencyService.ward_id == current_user.ward_id,
                EmergencyService.is_citywide == True
            )
        )
    # SUPER_ADMIN can filter by ward_id if provided, otherwise sees all
    elif current_user.role == UserRole.SUPER_ADMIN and ward_id:
        query = query.filter(EmergencyService.ward_id == ward_id)
    
    if type:
        query = query.filter(EmergencyService.type == type)
    
    if category:
        query = query.filter(EmergencyService.category == category)
    
    return query.all()


@router.post("/admin/emergency", response_model=EmergencyServiceResponse)
async def create_emergency_service(
    request: EmergencyServiceCreate,
    current_user: User = Depends(require_role([UserRole.WARD_ADMIN, UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    """Create emergency service"""
    # Ward admin can only create for their ward
    if current_user.role == UserRole.WARD_ADMIN:
        if request.ward_id and request.ward_id != current_user.ward_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You can only manage services for your ward"
            )
        ward_id = current_user.ward_id
    else:
        ward_id = request.ward_id
    
    service = EmergencyService(
        **request.model_dump(),
        ward_id=ward_id,
        created_by=current_user.id,
        is_citywide=request.is_citywide
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
    """List emergency services for admin management"""
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
    """Update emergency service"""
    service = db.query(EmergencyService).filter(EmergencyService.id == service_id).first()
    if not service:
        raise HTTPException(status_code=404, detail="Service not found")
    
    if current_user.role == UserRole.WARD_ADMIN and service.ward_id != current_user.ward_id:
        raise HTTPException(status_code=403, detail="Not authorized")
    
    update_data = request.model_dump(exclude_unset=True)
    for key, value in update_data.items():
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
    """Delete emergency service (soft delete)"""
    service = db.query(EmergencyService).filter(EmergencyService.id == service_id).first()
    if not service:
        raise HTTPException(status_code=404, detail="Service not found")
    
    if current_user.role == UserRole.WARD_ADMIN and service.ward_id != current_user.ward_id:
        raise HTTPException(status_code=403, detail="Not authorized")
    
    service.is_active = "N"
    db.commit()
    return MessageResponse(message="Service deleted successfully")


# ==================== SCHEMES ====================
@router.get("/schemes", response_model=List[SchemeResponse])
async def get_schemes(
    category: Optional[str] = None,
    search: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """Get government schemes (public)"""
    query = db.query(Scheme).filter(Scheme.is_active == "Y")
    
    if category:
        query = query.filter(Scheme.category == category)
    
    if search:
        query = query.filter(
            or_(
                Scheme.title.ilike(f"%{search}%"),
                Scheme.description.ilike(f"%{search}%")
            )
        )
    
    return query.order_by(Scheme.created_at.desc()).all()


@router.post("/admin/schemes", response_model=SchemeResponse)
async def create_scheme(
    request: SchemeCreate,
    current_user: User = Depends(require_role([UserRole.WARD_ADMIN, UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    """Create government scheme"""
    scheme = Scheme(**request.model_dump())
    db.add(scheme)
    db.commit()
    db.refresh(scheme)
    return scheme


@router.put("/admin/schemes/{scheme_id}", response_model=SchemeResponse)
async def update_scheme(
    scheme_id: int,
    request: SchemeUpdate,
    current_user: User = Depends(require_role([UserRole.WARD_ADMIN, UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    """Update scheme"""
    scheme = db.query(Scheme).filter(Scheme.id == scheme_id).first()
    if not scheme:
        raise HTTPException(status_code=404, detail="Scheme not found")
    
    update_data = request.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(scheme, key, value)
    
    db.commit()
    db.refresh(scheme)
    return scheme


# ==================== JOB VACANCIES ====================
@router.get("/jobs", response_model=List[JobVacancyResponse])
async def get_jobs(
    search: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """Get job vacancies (public)"""
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
    """Create job vacancy (Super Admin only)"""
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
    """Update job vacancy"""
    job = db.query(JobVacancy).filter(JobVacancy.id == job_id).first()
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
    
    update_data = request.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(job, key, value)
    
    db.commit()
    db.refresh(job)
    return job


# ==================== RTI ====================
@router.get("/rti", response_model=List[RTIInfoResponse])
async def get_rti_info(db: Session = Depends(get_db)):
    """Get RTI information (public)"""
    return db.query(RTIInfo).filter(
        RTIInfo.is_active == "Y"
    ).order_by(RTIInfo.display_order).all()


@router.post("/admin/rti", response_model=RTIInfoResponse)
async def create_rti_info(
    request: RTIInfoCreate,
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    """Create RTI information"""
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
    """Update RTI information"""
    rti = db.query(RTIInfo).filter(RTIInfo.id == rti_id).first()
    if not rti:
        raise HTTPException(status_code=404, detail="RTI info not found")
    
    update_data = request.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(rti, key, value)
    
    db.commit()
    db.refresh(rti)
    return rti


# ==================== NOTICES & ANNOUNCEMENTS ====================
@router.get("/notices", response_model=List[NoticeResponse])
async def get_notices(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get notices for current user"""
    query = db.query(Notification).filter(
        Notification.is_active == "Y",
        or_(
            Notification.ward_id == None,
            Notification.ward_id == current_user.ward_id
        ),
        or_(
            Notification.target_role == None,
            Notification.target_role == current_user.role
        ),
        or_(
            Notification.expires_at == None,
            Notification.expires_at > datetime.utcnow()
        )
    )
    
    results = []
    for notif in query.order_by(Notification.created_at.desc()).all():
        results.append(NoticeResponse(
            id=notif.id,
            title=notif.title,
            message=notif.message,
            notice_type=notif.notification_type,
            ward_id=notif.ward_id,
            target_role=notif.target_role,
            is_active=notif.is_active,
            created_at=notif.created_at,
            expires_at=notif.expires_at
        ))
    
    return results


@router.post("/admin/notices", response_model=NoticeResponse)
async def create_notice(
    request: NoticeCreate,
    current_user: User = Depends(require_role([UserRole.WARD_ADMIN, UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    """Create notice/announcement"""
    # Ward admin can only create for their ward
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
        id=notif.id,
        title=notif.title,
        message=notif.message,
        notice_type=notif.notification_type,
        ward_id=notif.ward_id,
        target_role=notif.target_role,
        is_active=notif.is_active,
        created_at=notif.created_at,
        expires_at=notif.expires_at
    )


@router.put("/admin/notices/{notice_id}", response_model=NoticeResponse)
async def update_notice(
    notice_id: int,
    request: NoticeUpdate,
    current_user: User = Depends(require_role([UserRole.WARD_ADMIN, UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    """Update notice"""
    notif = db.query(Notification).filter(Notification.id == notice_id).first()
    if not notif:
        raise HTTPException(status_code=404, detail="Notice not found")
    
    if current_user.role == UserRole.WARD_ADMIN and notif.ward_id != current_user.ward_id:
        raise HTTPException(status_code=403, detail="Not authorized")
    
    update_data = request.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        if key == "notice_type":
            setattr(notif, "notification_type", value)
        else:
            setattr(notif, key, value)
    
    db.commit()
    db.refresh(notif)
    
    return NoticeResponse(
        id=notif.id,
        title=notif.title,
        message=notif.message,
        notice_type=notif.notification_type,
        ward_id=notif.ward_id,
        target_role=notif.target_role,
        is_active=notif.is_active,
        created_at=notif.created_at,
        expires_at=notif.expires_at
    )


# ==================== TRANSPORT ====================
@router.get("/transport", response_model=List[TransportResponse])
async def get_transport(
    type: Optional[str] = None,
    search: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """Get transport information (public)"""
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
    """Create transport entry"""
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
    """Update transport"""
    transport = db.query(Transport).filter(Transport.id == transport_id).first()
    if not transport:
        raise HTTPException(status_code=404, detail="Transport not found")
    
    update_data = request.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(transport, key, value)
    
    db.commit()
    db.refresh(transport)
    return transport
