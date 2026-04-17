from app.api.auth import router as auth_router
from app.api.complaints import router as complaints_router
from app.api.services import router as services_router
from app.api.admin import router as admin_router

__all__ = ["auth_router", "complaints_router", "services_router", "admin_router"]
