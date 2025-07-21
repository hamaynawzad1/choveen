from pydantic import BaseModel
from .user import UserResponse

class Token(BaseModel):
    access_token: str
    token_type: str
    user: UserResponse

class VerifyEmail(BaseModel):
    email: str
    verification_code: str