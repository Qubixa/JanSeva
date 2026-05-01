from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from app.models.user import UserRole


class RegisterRequest(BaseModel):
    name: str = Field(..., min_length=2, max_length=100)
    mobile: str = Field(..., min_length=10, max_length=15, pattern=r"^\d{10,15}$")
    email: Optional[str] = None
    password: str = Field(..., min_length=6)
    confirm_password: str = Field(..., min_length=6)
    ward_id: int = Field(..., gt=0)
    address: str = Field(..., min_length=10, max_length=500)


class LoginRequest(BaseModel):
    mobile: str = Field(..., min_length=10, max_length=15)
    password: str = Field(..., min_length=6)


class AdminLoginRequest(BaseModel):
    email: EmailStr
    password: str

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: "UserResponse"


class UserResponse(BaseModel):
    id: int
    name: str
    mobile: str
    email: Optional[str]
    role: UserRole
    ward_id: int
    ward_name: Optional[str] = None
    address: str
    profile_image: Optional[str]
    is_active: bool
    is_verified: bool

    class Config:
        from_attributes = True


class UserUpdateRequest(BaseModel):
    name: Optional[str] = Field(None, min_length=2, max_length=100)
    email: Optional[str] = None
    address: Optional[str] = Field(None, min_length=10, max_length=500)


class ChangePasswordRequest(BaseModel):
    old_password: str = Field(..., min_length=6)
    new_password: str = Field(..., min_length=6)


# Update forward reference
TokenResponse.model_rebuild()
