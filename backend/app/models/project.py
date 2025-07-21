import uuid
import json
from sqlalchemy import Column, String, ForeignKey, Text, Table
from sqlalchemy.orm import relationship
from .base import BaseModel

# Association table for project team members
project_members = Table(
    'project_members',
    BaseModel.metadata,
    Column('project_id', String(36), ForeignKey('projects.id')),
    Column('user_id', String(36), ForeignKey('users.id'))
)

class Project(BaseModel):
    __tablename__ = "projects"

    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=False)
    required_skills = Column(Text, nullable=False, default='[]')  # Store as JSON string
    status = Column(String(50), default="active")  # active, completed, on_hold
    owner_id = Column(String(36), ForeignKey("users.id"), nullable=False)

    # Relationships
    owner = relationship("User", back_populates="owned_projects", foreign_keys=[owner_id])
    team_members = relationship("User", secondary=project_members, backref="projects")
    messages = relationship("Message", back_populates="project")
    
    def __init__(self, **kwargs):
        # Convert required_skills list to JSON string for SQLite
        if 'required_skills' in kwargs and isinstance(kwargs['required_skills'], list):
            kwargs['required_skills'] = json.dumps(kwargs['required_skills'])
        elif 'required_skills' not in kwargs:
            kwargs['required_skills'] = '[]'
        
        super().__init__(**kwargs)
        if not self.id:
            self.id = str(uuid.uuid4())
    
    @property
    def required_skills_list(self):
        """Get required_skills as a list"""
        if not self.required_skills:
            return []
        try:
            if isinstance(self.required_skills, str):
                return json.loads(self.required_skills)
            elif isinstance(self.required_skills, list):
                return self.required_skills
            else:
                return []
        except (json.JSONDecodeError, TypeError):
            return []
    
    @required_skills_list.setter
    def required_skills_list(self, value):
        """Set required_skills from a list"""
        if isinstance(value, list):
            self.required_skills = json.dumps(value)
        elif isinstance(value, str):
            # Try to parse it as JSON first
            try:
                parsed = json.loads(value)
                if isinstance(parsed, list):
                    self.required_skills = value
                else:
                    self.required_skills = '[]'
            except:
                # If not valid JSON, treat as single item
                self.required_skills = json.dumps([value])
        else:
            self.required_skills = '[]'
    
    def to_dict(self):
        """Convert to dictionary with parsed skills"""
        return {
            'id': self.id,
            'title': self.title,
            'description': self.description,
            'required_skills': self.required_skills_list,
            'status': self.status,
            'owner_id': self.owner_id,
            'created_at': self.created_at,
            'updated_at': self.updated_at
        }