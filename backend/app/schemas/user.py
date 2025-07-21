from pydantic import BaseModel, EmailStr, validator
from typing import List, Optional
from datetime import datetime
import json

class UserBase(BaseModel):
    name: str
    email: EmailStr
    skills: List[str] = []

class UserCreate(UserBase):
    password: str
    profile_image: Optional[str] = None

class UserResponse(UserBase):
    id: str
    profile_image: Optional[str] = None
    is_verified: bool
    created_at: datetime

    class Config:
        from_attributes = True
    
    @validator('skills', pre=True)
    def parse_skills(cls, v):
        """Parse skills from JSON string to list"""
        if isinstance(v, str):
            try:
                return json.loads(v)
            except (json.JSONDecodeError, TypeError):
                return []
        elif isinstance(v, list):
            return v
        else:
            return []
    
    @classmethod
    def from_orm(cls, obj):
        """Create UserResponse from database object"""
        # Parse skills properly
        skills = obj.skills_list if hasattr(obj, 'skills_list') else []
        
        data = {
            'id': obj.id,
            'name': obj.name,
            'email': obj.email,
            'profile_image': obj.profile_image,
            'skills': skills,
            'is_verified': obj.is_verified,
            'created_at': obj.created_at
        }
        return cls(**data)

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserUpdate(BaseModel):
    name: Optional[str] = None
    skills: Optional[List[str]] = None
    profile_image: Optional[str] = None