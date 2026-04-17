from app.api.auth import router as auth_router
from app.api.complaints import router as complaints_router
from app.api.services import router as services_router
from app.api.admin import router as admin_router
from app.api.matrimonial import router as matrimonial_router
from app.api.admin_extended import router as admin_extended_router

__all__ = ["auth_router", "complaints_router", "services_router", "admin_router", "matrimonial_router", "admin_extended_router"]
