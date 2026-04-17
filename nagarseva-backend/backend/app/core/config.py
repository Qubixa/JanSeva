from pydantic_settings import BaseSettings
from typing import Optional
import os


class Settings(BaseSettings):
    # Application
    APP_NAME: str = "LOKSeva API"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = True
    
    # Database
    DATABASE_URL: str = "postgresql://postgres:Rootdmin%401234@localhost:5432/LOKseva"
    
    # JWT
    SECRET_KEY: str = "your-super-secret-key-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days
    
    # OTP (For production, integrate with SMS gateway)
    OTP_EXPIRE_MINUTES: int = 5
    
    # File Upload
    UPLOAD_DIR: str = "uploads"
    MAX_FILE_SIZE: int = 50 * 1024 * 1024  # 50MB for videos
    ALLOWED_IMAGE_TYPES: list = ["image/jpeg", "image/png", "image/gif", "image/webp"]
    ALLOWED_VIDEO_TYPES: list = ["video/mp4", "video/mpeg", "video/quicktime", "video/webm"]
    
    class Config:
        env_file = ".env"


settings = Settings()

# Create upload directories
os.makedirs(settings.UPLOAD_DIR, exist_ok=True)
os.makedirs(f"{settings.UPLOAD_DIR}/complaints", exist_ok=True)
os.makedirs(f"{settings.UPLOAD_DIR}/profiles", exist_ok=True)
os.makedirs(f"{settings.UPLOAD_DIR}/contacts", exist_ok=True)
