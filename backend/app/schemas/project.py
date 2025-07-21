# backend/app/schemas/project.py - Fixed Version
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

class ProjectCreate(BaseModel):
    title: str
    description: str
    required_skills: List[str]

class ProjectUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    required_skills: Optional[List[str]] = None
    status: Optional[str] = None

class ProjectResponse(BaseModel):
    id: str
    title: str
    description: str
    required_skills: List[str]
    creator: Optional[str] = "Unknown"  # Fixed - Made Optional with default
    member_count: Optional[int] = 1     # Fixed - Made Optional with default
    status: str
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True

    @classmethod
    def from_orm(cls, obj):
        """Custom from_orm to handle missing fields"""
        data = obj.__dict__.copy()
        
        # Handle None updated_at
        if data.get('updated_at') is None:
            data['updated_at'] = data.get('created_at')
        
        # Handle missing creator
        if not data.get('creator'):
            data['creator'] = "Unknown"
            
        # Handle missing member_count
        if data.get('member_count') is None:
            data['member_count'] = 1
        
        # Handle required_skills if it's a string
        if isinstance(data.get('required_skills'), str):
            try:
                import json
                data['required_skills'] = json.loads(data['required_skills'])
            except:
                data['required_skills'] = data['required_skills'].split(',') if data['required_skills'] else []
        
        # Ensure required_skills is a list
        if not isinstance(data.get('required_skills'), list):
            data['required_skills'] = []
        
        return cls(**data)

class ProjectMember(BaseModel):
    user_id: str
    project_id: str
    role: str = "member"
    joined_at: datetime

class ProjectMemberResponse(BaseModel):
    id: str
    user_id: str
    project_id: str
    role: str
    joined_at: datetime
    user_name: Optional[str] = None
    user_email: Optional[str] = None

    class Config:
        from_attributes = True