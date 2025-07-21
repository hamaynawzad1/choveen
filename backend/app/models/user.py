import uuid
import json
from sqlalchemy import Column, String, Boolean, Text
from sqlalchemy.orm import relationship
from .base import BaseModel

class User(BaseModel):
    __tablename__ = "users"

    name = Column(String(255), nullable=False)
    email = Column(String(255), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    profile_image = Column(String(500), nullable=True)
    skills = Column(Text, nullable=False, default='[]')  # Store as JSON string
    is_verified = Column(Boolean, default=False)
    verification_code = Column(String(10), nullable=True)

    # Relationships
    owned_projects = relationship("Project", back_populates="owner", foreign_keys="Project.owner_id")
    sent_messages = relationship("Message", back_populates="sender", foreign_keys="Message.sender_id")
    
    def __init__(self, **kwargs):
        # Convert skills list to JSON string for SQLite
        if 'skills' in kwargs and isinstance(kwargs['skills'], list):
            kwargs['skills'] = json.dumps(kwargs['skills'])
        elif 'skills' not in kwargs:
            kwargs['skills'] = '[]'
        
        super().__init__(**kwargs)
        if not self.id:
            self.id = str(uuid.uuid4())
    
    @property
    def skills_list(self):
        """Get skills as a list"""
        if not self.skills:
            return []
        try:
            if isinstance(self.skills, str):
                return json.loads(self.skills)
            elif isinstance(self.skills, list):
                return self.skills
            else:
                return []
        except (json.JSONDecodeError, TypeError):
            return []
    
    @skills_list.setter
    def skills_list(self, value):
        """Set skills from a list"""
        if isinstance(value, list):
            self.skills = json.dumps(value)
        elif isinstance(value, str):
            # Try to parse it as JSON first
            try:
                parsed = json.loads(value)
                if isinstance(parsed, list):
                    self.skills = value
                else:
                    self.skills = '[]'
            except:
                # If not valid JSON, treat as single item
                self.skills = json.dumps([value])
        else:
            self.skills = '[]'
    
    def to_dict(self):
        """Convert to dictionary with parsed skills"""
        return {
            'id': self.id,
            'name': self.name,
            'email': self.email,
            'profile_image': self.profile_image,
            'skills': self.skills_list,
            'is_verified': self.is_verified,
            'created_at': self.created_at,
            'updated_at': self.updated_at
        }