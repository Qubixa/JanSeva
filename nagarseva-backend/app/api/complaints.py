from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form, Query
from pydantic import BaseModel
from sqlalchemy.orm import Session
from sqlalchemy import or_, and_, func
from datetime import datetime
from typing import Optional, List
import os
import uuid
import random

from app.core.database import get_db
from app.core.security import get_current_user, require_role
from app.core.config import settings
from app.models.user import User, UserRole
from app.models.ward import Ward
from app.models.complaint import (
    Complaint, ComplaintMedia, ComplaintLog,
    ComplaintCategory
)
from app.schemas.complaint import (
    ComplaintResponse, ComplaintFeedback,
    ComplaintMediaResponse, ComplaintLogResponse,
    ComplaintCategorySchema
)
from app.schemas.common import MessageResponse

router = APIRouter(prefix="/complaints", tags=["Complaints"])


# Status constants
STATUS_PENDING = "PENDING"
STATUS_ASSIGNED = "ASSIGNED"
STATUS_IN_PROGRESS = "IN_PROGRESS"
STATUS_RESOLVED = "RESOLVED"
STATUS_REJECTED = "REJECTED"
STATUS_CLOSED = "CLOSED"

# Priority constants
PRIORITY_LOW = "LOW"
PRIORITY_MEDIUM = "MEDIUM"
PRIORITY_HIGH = "HIGH"
PRIORITY_URGENT = "URGENT"


# Add these classes before ComplaintResponse
class UserBrief(BaseModel):
    id: int
    name: str
    mobile: str

class WardBrief(BaseModel):
    id: int
    name: str

class OfficerBrief(BaseModel):
    id: int
    name: str

def generate_complaint_number() -> str:
    """Generate unique complaint number"""
    timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
    random_part = uuid.uuid4().hex[:4].upper()
    return f"CMP{timestamp}{random_part}"


def get_least_loaded_officer(officers: List[User], db: Session) -> Optional[User]:
    """
    Get the field officer with the least number of active complaints.
    Provides load balancing for complaint assignments.
    """
    if not officers:
        return None
    
    officer_loads = []
    for officer in officers:
        # Count active complaints for this officer
        active_count = db.query(Complaint).filter(
            Complaint.assigned_officer_id == officer.id,
            Complaint.status.in_([STATUS_PENDING, STATUS_ASSIGNED, STATUS_IN_PROGRESS])
        ).count()
        officer_loads.append((officer, active_count))
    
    # Sort by load (ascending) and return the least loaded
    officer_loads.sort(key=lambda x: x[1])
    return officer_loads[0][0]


def auto_assign_complaint(complaint: Complaint, db: Session, use_load_balancing: bool = True) -> Optional[User]:
    """
    Automatically assign a complaint to an available field officer.
    If use_load_balancing is True, assigns to least loaded officer.
    Otherwise, assigns randomly.
    """
    # Get all active field officers from the same ward
    officers = db.query(User).filter(
        User.role == UserRole.FIELD_OFFICER,
        User.is_active == True,
        User.ward_id == complaint.ward_id
    ).all()
    
    if not officers:
        # Try to get any active field officer from any ward as fallback
        officers = db.query(User).filter(
            User.role == UserRole.FIELD_OFFICER,
            User.is_active == True
        ).all()
    
    if not officers:
        return None
    
    # Select officer based on strategy
    if use_load_balancing:
        assigned_officer = get_least_loaded_officer(officers, db)
    else:
        assigned_officer = random.choice(officers)
    
    if not assigned_officer:
        return None
    
    # Update complaint with assigned officer
    complaint.assigned_officer_id = assigned_officer.id
    complaint.status = STATUS_ASSIGNED
    
    # Create assignment log
    log = ComplaintLog(
        complaint_id=complaint.id,
        action_by_id=complaint.user_id,
        action="AUTO_ASSIGNED",
        old_status=STATUS_PENDING,
        new_status=STATUS_ASSIGNED,
        remarks=f"Auto-assigned to {assigned_officer.name} (Ward {complaint.ward_id}) - {'Load balanced' if use_load_balancing else 'Random'}"
    )
    db.add(log)
    
    return assigned_officer


def complaint_to_response(complaint: Complaint, db: Session) -> ComplaintResponse:
    """Convert complaint model to response"""
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
    
    # Create nested objects as dictionaries (not Pydantic models)
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
        user=user_dict,  # Pass dictionary instead of model
        ward_id=complaint.ward_id,
        ward=ward_dict,  # Pass dictionary instead of model
        assigned_officer_id=complaint.assigned_officer_id,
        assigned_officer=officer_dict,  # Pass dictionary instead of model
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


class ComplaintListResponse(BaseModel):
    """Response for list of complaints"""
    complaints: List[ComplaintResponse]
    total: int
    page: int
    page_size: int
    total_pages: int
    
    class Config:
        from_attributes = True


class ComplaintAssignRequest(BaseModel):
    """Request to assign complaint"""
    officer_id: int
    priority: Optional[str] = None
    remarks: Optional[str] = None


class ComplaintStatusUpdateRequest(BaseModel):
    """Request to update complaint status"""
    status: str
    remarks: Optional[str] = None


class MyComplaintStats(BaseModel):
    """Stats for the current citizen's complaints."""
    total: int
    pending: int
    assigned: int
    in_progress: int
    resolved: int
    rejected: int
    closed: int


class BulkAssignResponse(BaseModel):
    message: str
    assigned_count: int
    failed_count: int
    errors: List[dict] = []


# ============================================================================
# STATIC ROUTES (no path parameters) - MUST come first
# ============================================================================

@router.get("/categories", response_model=List[ComplaintCategorySchema])
def get_complaint_categories(
    db: Session = Depends(get_db)
):
    """Get all active complaint categories"""
    categories = db.query(ComplaintCategory)\
        .filter(ComplaintCategory.is_active == 'Y')\
        .order_by(ComplaintCategory.name)\
        .all()
    return categories


@router.get("/my/stats", response_model=MyComplaintStats)
async def get_my_complaint_stats(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Return aggregated status counts for the authenticated citizen."""
    base = db.query(Complaint).filter(Complaint.user_id == current_user.id)
 
    return MyComplaintStats(
        total=base.count(),
        pending=base.filter(Complaint.status == STATUS_PENDING).count(),
        assigned=base.filter(Complaint.status == STATUS_ASSIGNED).count(),
        in_progress=base.filter(Complaint.status == STATUS_IN_PROGRESS).count(),
        resolved=base.filter(Complaint.status == STATUS_RESOLVED).count(),
        rejected=base.filter(Complaint.status == STATUS_REJECTED).count(),
        closed=base.filter(Complaint.status == STATUS_CLOSED).count(),
    )
 
 
@router.get("/my", response_model=ComplaintListResponse)
async def get_my_complaints(
    page: int = Query(1, ge=1),
    page_size: int = Query(10, ge=1, le=50),
    status: Optional[str] = Query(None),
    category: Optional[str] = Query(None),
    search: Optional[str] = Query(None),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Fetch only the authenticated citizen's own complaints.
 
    - Supports pagination via `page` / `page_size`
    - Optional `status` filter (PENDING | ASSIGNED | IN_PROGRESS | RESOLVED | REJECTED | CLOSED)
    - Optional `category` filter (complaint category code)
    - Optional full-text `search` across complaint_number, title, description
    """
    query = db.query(Complaint).filter(Complaint.user_id == current_user.id)
 
    if status:
        query = query.filter(Complaint.status == status.upper())
 
    if category:
        query = query.filter(Complaint.category == category)
 
    if search:
        query = query.filter(
            or_(
                Complaint.complaint_number.ilike(f"%{search}%"),
                Complaint.title.ilike(f"%{search}%"),
                Complaint.description.ilike(f"%{search}%"),
            )
        )
 
    total = query.count()
    total_pages = (total + page_size - 1) // page_size
    
    complaints = (
        query.order_by(Complaint.created_at.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
        .all()
    )
 
    return ComplaintListResponse(
        complaints=[complaint_to_response(c, db) for c in complaints],
        total=total,
        page=page,
        page_size=page_size,
        total_pages=total_pages
    )


# ============================================================================
# AUTO-ASSIGNMENT ENDPOINTS
# ============================================================================

@router.get("/available-officers/{ward_id}")
async def get_available_officers(
    ward_id: int,
    current_user: User = Depends(require_role([UserRole.WARD_ADMIN, UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    """Get available field officers for a specific ward with their current load"""
    officers = db.query(User).filter(
        User.role == UserRole.FIELD_OFFICER,
        User.is_active == True,
        User.ward_id == ward_id
    ).all()
    
    result = []
    for officer in officers:
        active_count = db.query(Complaint).filter(
            Complaint.assigned_officer_id == officer.id,
            Complaint.status.in_([STATUS_PENDING, STATUS_ASSIGNED, STATUS_IN_PROGRESS])
        ).count()
        
        result.append({
            "id": officer.id,
            "name": officer.name,
            "mobile": officer.mobile,
            "email": officer.email,
            "active_complaints": active_count,
            "status": "available" if active_count < 10 else "busy",
            "max_capacity": 10
        })
    
    return {
        "ward_id": ward_id,
        "total_officers": len(result),
        "available_officers": [o for o in result if o["status"] == "available"],
        "officers": result
    }


@router.get("/assignment-stats")
async def get_assignment_stats(
    current_user: User = Depends(require_role([UserRole.WARD_ADMIN, UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    """Get statistics about complaint assignments"""
    query = db.query(Complaint)
    
    if current_user.role == UserRole.WARD_ADMIN:
        query = query.filter(Complaint.ward_id == current_user.ward_id)
    
    total_complaints = query.count()
    
    # Count auto-assigned complaints
    auto_assigned = query.filter(
        ComplaintLog.complaint_id == Complaint.id,
        ComplaintLog.action == "AUTO_ASSIGNED"
    ).count()
    
    manually_assigned = query.filter(
        Complaint.assigned_officer_id.isnot(None),
        ~Complaint.id.in_(
            db.query(ComplaintLog.complaint_id).filter(ComplaintLog.action == "AUTO_ASSIGNED")
        )
    ).count()
    
    unassigned = query.filter(Complaint.assigned_officer_id.is_(None)).count()
    
    # Get officer load distribution
    officers = db.query(User).filter(User.role == UserRole.FIELD_OFFICER, User.is_active == True).all()
    officer_loads = []
    for officer in officers:
        active_count = db.query(Complaint).filter(
            Complaint.assigned_officer_id == officer.id,
            Complaint.status.in_([STATUS_PENDING, STATUS_ASSIGNED, STATUS_IN_PROGRESS])
        ).count()
        officer_loads.append({
            "officer_id": officer.id,
            "officer_name": officer.name,
            "active_complaints": active_count,
            "ward_id": officer.ward_id
        })
    
    return {
        "total_complaints": total_complaints,
        "auto_assigned": auto_assigned,
        "manually_assigned": manually_assigned,
        "unassigned": unassigned,
        "officer_loads": officer_loads,
        "auto_assignment_enabled": True
    }


@router.post("/bulk-auto-assign", response_model=BulkAssignResponse)
async def bulk_auto_assign_complaints(
    use_load_balancing: bool = Query(True, description="Use load balancing or random assignment"),
    current_user: User = Depends(require_role([UserRole.WARD_ADMIN, UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    """Auto-assign all unassigned complaints in bulk"""
    query = db.query(Complaint).filter(
        Complaint.assigned_officer_id.is_(None),
        Complaint.status == STATUS_PENDING
    )
    
    if current_user.role == UserRole.WARD_ADMIN:
        query = query.filter(Complaint.ward_id == current_user.ward_id)
    
    unassigned_complaints = query.all()
    
    assigned_count = 0
    failed_count = 0
    errors = []
    
    for complaint in unassigned_complaints:
        try:
            assigned_officer = auto_assign_complaint(complaint, db, use_load_balancing)
            if assigned_officer:
                assigned_count += 1
            else:
                failed_count += 1
                errors.append({
                    "complaint_id": complaint.id,
                    "complaint_number": complaint.complaint_number,
                    "error": "No available officers"
                })
        except Exception as e:
            failed_count += 1
            errors.append({
                "complaint_id": complaint.id,
                "complaint_number": complaint.complaint_number,
                "error": str(e)
            })
    
    db.commit()
    
    return BulkAssignResponse(
        message=f"Auto-assigned {assigned_count} complaints, failed {failed_count}",
        assigned_count=assigned_count,
        failed_count=failed_count,
        errors=errors[:50]
    )


# ============================================================================
# BASE ROUTES
# ============================================================================

@router.post("/", response_model=ComplaintResponse)
async def create_complaint(
    category: str = Form(...),
    title: str = Form(...),
    description: str = Form(...),
    address: str = Form(...),
    latitude: Optional[str] = Form(None),
    longitude: Optional[str] = Form(None),
    media_files: List[UploadFile] = File(default=[]),
    auto_assign: bool = Form(True, description="Automatically assign to a field officer"),
    use_load_balancing: bool = Form(True, description="Use load balancing for assignment"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create a new complaint with optional auto-assignment to field officer"""
    # Validate category exists
    category_obj = db.query(ComplaintCategory)\
        .filter(ComplaintCategory.code == category, ComplaintCategory.is_active == 'Y')\
        .first()

    if not category_obj:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid complaint category"
        )

    complaint = Complaint(
        complaint_number=generate_complaint_number(),
        user_id=current_user.id,
        ward_id=current_user.ward_id,
        category=category,
        title=title,
        description=description,
        address=address,
        latitude=latitude,
        longitude=longitude,
        status=STATUS_PENDING,
        priority=PRIORITY_MEDIUM
    )
    db.add(complaint)
    db.commit()
    db.refresh(complaint)
    
    # Handle media uploads
    for media_file in media_files:
        if media_file.filename:
            content_type = media_file.content_type
            file_ext = media_file.filename.split(".")[-1].lower()
            
            if content_type in settings.ALLOWED_IMAGE_TYPES:
                file_type = "IMAGE"
            elif content_type in settings.ALLOWED_VIDEO_TYPES:
                file_type = "VIDEO"
            else:
                continue
            
            content = await media_file.read()
            if len(content) > settings.MAX_FILE_SIZE:
                continue
            
            os.makedirs(f"{settings.UPLOAD_DIR}/complaints", exist_ok=True)
            
            filename = f"{uuid.uuid4()}.{file_ext}"
            file_path = f"{settings.UPLOAD_DIR}/complaints/{filename}"
            
            with open(file_path, "wb") as f:
                f.write(content)
            
            media = ComplaintMedia(
                complaint_id=complaint.id,
                file_path=f"/uploads/complaints/{filename}",
                file_type=file_type,
                file_name=media_file.filename,
                file_size=len(content)
            )
            db.add(media)
    
    # Create initial log
    log = ComplaintLog(
        complaint_id=complaint.id,
        action_by_id=current_user.id,
        action="CREATED",
        new_status=STATUS_PENDING,
        remarks="Complaint registered"
    )
    db.add(log)
    
    # Auto-assign if enabled
    assigned_officer = None
    if auto_assign:
        assigned_officer = auto_assign_complaint(complaint, db, use_load_balancing)
    
    db.commit()
    db.refresh(complaint)
    
    response = complaint_to_response(complaint, db)
    
    # Add assignment info to response if needed
    if assigned_officer:
        # You can extend response or just return as is
        pass
    
    return response


@router.get("/", response_model=ComplaintListResponse)
async def get_complaints(
    page: int = Query(1, ge=1),
    page_size: int = Query(10, ge=1, le=50),
    status: Optional[str] = None,
    category: Optional[str] = None,
    priority: Optional[str] = None,
    search: Optional[str] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get complaints based on user role"""
    query = db.query(Complaint)
    
    # Filter based on role
    if current_user.role == UserRole.CITIZEN:
        query = query.filter(Complaint.user_id == current_user.id)
    elif current_user.role == UserRole.FIELD_OFFICER:
        query = query.filter(Complaint.assigned_officer_id == current_user.id)
    elif current_user.role == UserRole.WARD_ADMIN:
        query = query.filter(Complaint.ward_id == current_user.ward_id)
    # SUPER_ADMIN can see all
    
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
    
    total = query.count()
    total_pages = (total + page_size - 1) // page_size
    
    complaints = query.order_by(Complaint.created_at.desc()).offset(
        (page - 1) * page_size
    ).limit(page_size).all()
    
    return ComplaintListResponse(
        complaints=[complaint_to_response(c, db) for c in complaints],
        total=total,
        page=page,
        page_size=page_size,
        total_pages=total_pages
    )


# ============================================================================
# DYNAMIC ROUTES (with path parameters) - MUST come last
# ============================================================================

@router.get("/{complaint_id}", response_model=ComplaintResponse)
async def get_complaint(
    complaint_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get complaint details"""
    complaint = db.query(Complaint).filter(Complaint.id == complaint_id).first()
    
    if not complaint:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Complaint not found"
        )
    
    # Check access
    if current_user.role == UserRole.CITIZEN and complaint.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have access to this complaint"
        )
    
    return complaint_to_response(complaint, db)


@router.get("/{complaint_id}/logs", response_model=List[ComplaintLogResponse])
async def get_complaint_logs(
    complaint_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get complaint history/logs"""
    complaint = db.query(Complaint).filter(Complaint.id == complaint_id).first()
    
    if not complaint:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Complaint not found"
        )
    
    logs = db.query(ComplaintLog).filter(
        ComplaintLog.complaint_id == complaint_id
    ).order_by(ComplaintLog.created_at.desc()).all()
    
    result = []
    for log in logs:
        user = db.query(User).filter(User.id == log.action_by_id).first()
        result.append(ComplaintLogResponse(
            id=log.id,
            action=log.action,
            old_status=log.old_status,
            new_status=log.new_status,
            remarks=log.remarks,
            action_by_name=user.name if user else None,
            created_at=log.created_at
        ))
    
    return result


@router.post("/{complaint_id}/assign", response_model=ComplaintResponse)
async def assign_complaint(
    complaint_id: int,
    request: ComplaintAssignRequest,
    current_user: User = Depends(require_role([UserRole.WARD_ADMIN, UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    """Assign complaint to a field officer (manual assignment)"""
    complaint = db.query(Complaint).filter(Complaint.id == complaint_id).first()
    
    if not complaint:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Complaint not found"
        )
    
    # Verify officer exists and is a field officer
    officer = db.query(User).filter(
        User.id == request.officer_id,
        User.role == UserRole.FIELD_OFFICER
    ).first()
    
    if not officer:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid field officer"
        )
    
    old_status = complaint.status
    complaint.assigned_officer_id = request.officer_id
    complaint.status = STATUS_ASSIGNED
    if request.priority:
        complaint.priority = request.priority
    
    # Create log
    log = ComplaintLog(
        complaint_id=complaint.id,
        action_by_id=current_user.id,
        action="MANUALLY_ASSIGNED",
        old_status=old_status,
        new_status=STATUS_ASSIGNED,
        remarks=request.remarks or f"Manually assigned to {officer.name}"
    )
    db.add(log)
    db.commit()
    db.refresh(complaint)
    
    return complaint_to_response(complaint, db)


@router.post("/{complaint_id}/auto-assign", response_model=ComplaintResponse)
async def auto_assign_existing_complaint(
    complaint_id: int,
    use_load_balancing: bool = Query(True, description="Use load balancing or random assignment"),
    current_user: User = Depends(require_role([UserRole.WARD_ADMIN, UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    """Manually trigger auto-assignment for an existing unassigned complaint"""
    complaint = db.query(Complaint).filter(Complaint.id == complaint_id).first()
    
    if not complaint:
        raise HTTPException(status_code=404, detail="Complaint not found")
    
    if complaint.assigned_officer_id:
        raise HTTPException(
            status_code=400, 
            detail="Complaint is already assigned to an officer"
        )
    
    if complaint.status != STATUS_PENDING:
        raise HTTPException(
            status_code=400,
            detail=f"Cannot assign complaint with status: {complaint.status}"
        )
    
    # Auto-assign the complaint
    assigned_officer = auto_assign_complaint(complaint, db, use_load_balancing)
    
    if not assigned_officer:
        raise HTTPException(
            status_code=404,
            detail="No available field officers found for assignment"
        )
    
    db.commit()
    db.refresh(complaint)
    
    return complaint_to_response(complaint, db)


@router.put("/{complaint_id}/status", response_model=ComplaintResponse)
async def update_complaint_status(
    complaint_id: int,
    request: ComplaintStatusUpdateRequest,
    current_user: User = Depends(require_role([
        UserRole.FIELD_OFFICER, UserRole.WARD_ADMIN, UserRole.SUPER_ADMIN
    ])),
    db: Session = Depends(get_db)
):
    """Update complaint status"""
    complaint = db.query(Complaint).filter(Complaint.id == complaint_id).first()
    
    if not complaint:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Complaint not found"
        )
    
    # Field officer can only update their assigned complaints
    if current_user.role == UserRole.FIELD_OFFICER:
        if complaint.assigned_officer_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You can only update complaints assigned to you"
            )
    
    # Validate status
    valid_statuses = [STATUS_PENDING, STATUS_ASSIGNED, STATUS_IN_PROGRESS, 
                     STATUS_RESOLVED, STATUS_REJECTED, STATUS_CLOSED]
    if request.status not in valid_statuses:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid status. Must be one of: {', '.join(valid_statuses)}"
        )
    
    old_status = complaint.status
    complaint.status = request.status
    
    if request.status == STATUS_RESOLVED:
        complaint.resolved_at = datetime.utcnow()
    
    # Create log
    log = ComplaintLog(
        complaint_id=complaint.id,
        action_by_id=current_user.id,
        action="STATUS_UPDATED",
        old_status=old_status,
        new_status=request.status,
        remarks=request.remarks
    )
    db.add(log)
    db.commit()
    db.refresh(complaint)
    
    return complaint_to_response(complaint, db)


@router.post("/{complaint_id}/resolve", response_model=ComplaintResponse)
async def resolve_complaint(
    complaint_id: int,
    resolution_remarks: str = Form(...),
    proof_images: List[UploadFile] = File(default=[]),
    current_user: User = Depends(require_role([
        UserRole.FIELD_OFFICER, UserRole.WARD_ADMIN, UserRole.SUPER_ADMIN
    ])),
    db: Session = Depends(get_db)
):
    """Resolve complaint with proof images"""
    complaint = db.query(Complaint).filter(Complaint.id == complaint_id).first()
    
    if not complaint:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Complaint not found"
        )
    
    # Field officer can only resolve their assigned complaints
    if current_user.role == UserRole.FIELD_OFFICER:
        if complaint.assigned_officer_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You can only resolve complaints assigned to you"
            )
    
    old_status = complaint.status
    complaint.status = STATUS_RESOLVED
    complaint.resolution_remarks = resolution_remarks
    complaint.resolved_at = datetime.utcnow()
    
    # Create upload directory if not exists
    os.makedirs(f"{settings.UPLOAD_DIR}/complaints", exist_ok=True)
    
    # Handle proof images
    for proof_image in proof_images:
        if proof_image.filename:
            file_ext = proof_image.filename.split(".")[-1].lower()
            if file_ext in ["jpg", "jpeg", "png", "gif", "webp"]:
                content = await proof_image.read()
                if len(content) > settings.MAX_FILE_SIZE:
                    continue
                
                filename = f"proof_{uuid.uuid4()}.{file_ext}"
                file_path = f"{settings.UPLOAD_DIR}/complaints/{filename}"
                
                with open(file_path, "wb") as f:
                    f.write(content)
                
                media = ComplaintMedia(
                    complaint_id=complaint.id,
                    file_path=f"/uploads/complaints/{filename}",
                    file_type="PROOF_IMAGE",
                    file_name=proof_image.filename,
                    file_size=len(content)
                )
                db.add(media)
    
    # Create log
    log = ComplaintLog(
        complaint_id=complaint.id,
        action_by_id=current_user.id,
        action="RESOLVED",
        old_status=old_status,
        new_status=STATUS_RESOLVED,
        remarks=resolution_remarks
    )
    db.add(log)
    db.commit()
    db.refresh(complaint)
    
    return complaint_to_response(complaint, db)


@router.post("/{complaint_id}/feedback", response_model=MessageResponse)
async def submit_feedback(
    complaint_id: int,
    feedback_data: ComplaintFeedback,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Submit feedback for a resolved complaint"""
    complaint = db.query(Complaint)\
        .filter(Complaint.id == complaint_id)\
        .first()
    
    if not complaint:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Complaint not found"
        )
    
    if complaint.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to provide feedback for this complaint"
        )
    
    if complaint.status != STATUS_RESOLVED:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Can only provide feedback for resolved complaints"
        )
    
    # Validate rating
    if feedback_data.rating < 1 or feedback_data.rating > 5:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Rating must be between 1 and 5"
        )
    
    complaint.rating = feedback_data.rating
    complaint.feedback = feedback_data.feedback
    
    # Create log for feedback
    log = ComplaintLog(
        complaint_id=complaint.id,
        action_by_id=current_user.id,
        action="FEEDBACK_SUBMITTED",
        new_status=complaint.status,
        remarks=f"User provided {feedback_data.rating} star rating"
    )
    db.add(log)
    
    db.commit()
    db.refresh(complaint)
    
    return MessageResponse(message="Feedback submitted successfully")


@router.post("/{complaint_id}/media", response_model=MessageResponse)
async def add_complaint_media(
    complaint_id: int,
    media_files: List[UploadFile] = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Add additional media to existing complaint"""
    complaint = db.query(Complaint).filter(Complaint.id == complaint_id).first()
    
    if not complaint:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Complaint not found"
        )
    
    if complaint.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can only add media to your own complaints"
        )
    
    # Create upload directory if not exists
    os.makedirs(f"{settings.UPLOAD_DIR}/complaints", exist_ok=True)
    
    count = 0
    for media_file in media_files:
        if media_file.filename:
            content_type = media_file.content_type
            file_ext = media_file.filename.split(".")[-1].lower()
            
            if content_type in settings.ALLOWED_IMAGE_TYPES:
                file_type = "IMAGE"
            elif content_type in settings.ALLOWED_VIDEO_TYPES:
                file_type = "VIDEO"
            else:
                continue
            
            content = await media_file.read()
            if len(content) > settings.MAX_FILE_SIZE:
                continue
            
            filename = f"{uuid.uuid4()}.{file_ext}"
            file_path = f"{settings.UPLOAD_DIR}/complaints/{filename}"
            
            with open(file_path, "wb") as f:
                f.write(content)
            
            media = ComplaintMedia(
                complaint_id=complaint.id,
                file_path=f"/uploads/complaints/{filename}",
                file_type=file_type,
                file_name=media_file.filename,
                file_size=len(content)
            )
            db.add(media)
            count += 1
    
    db.commit()
    
    return MessageResponse(message=f"{count} file(s) uploaded successfully")


@router.delete("/{complaint_id}", response_model=MessageResponse)
async def delete_complaint(
    complaint_id: int,
    current_user: User = Depends(require_role([UserRole.SUPER_ADMIN])),
    db: Session = Depends(get_db)
):
    """Delete a complaint (Super Admin only)"""
    complaint = db.query(Complaint).filter(Complaint.id == complaint_id).first()
    
    if not complaint:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Complaint not found"
        )
    
    # Delete associated media files
    for media in complaint.media:
        if os.path.exists(media.file_path.replace("/uploads/", f"{settings.UPLOAD_DIR}/")):
            os.remove(media.file_path.replace("/uploads/", f"{settings.UPLOAD_DIR}/"))
    
    db.delete(complaint)
    db.commit()
    
    return MessageResponse(message="Complaint deleted successfully")