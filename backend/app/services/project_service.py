import uuid
import json
from sqlalchemy.orm import Session
from app.models.project import Project
from app.models.user import User
from app.schemas.project import ProjectCreate

class ProjectService:
    def __init__(self, db: Session):
        self.db = db

    def create_project(self, project_data: ProjectCreate, owner_id: str) -> Project:
        """Create a new project"""
        project = Project(
            title=project_data.title,
            description=project_data.description,
            required_skills=json.dumps(project_data.required_skills),  # Convert to JSON string
            owner_id=owner_id
        )

        self.db.add(project)
        self.db.commit()
        self.db.refresh(project)
        return project

    def get_projects(self, skip: int = 0, limit: int = 100) -> list:
        """Get all projects with pagination"""
        return self.db.query(Project).offset(skip).limit(limit).all()

    def get_project_by_id(self, project_id: str) -> Project:
        """Get a specific project by ID"""
        return self.db.query(Project).filter(Project.id == project_id).first()

    def join_project(self, project_id: str, user_id: str) -> bool:
        """Add a user to project team"""
        project = self.get_project_by_id(project_id)
        user = self.db.query(User).filter(User.id == user_id).first()
        
        if not project or not user:
            return False

        # Check if user is already a team member
        if user not in project.team_members:
            project.team_members.append(user)
            self.db.commit()
        
        return True

    def leave_project(self, project_id: str, user_id: str) -> bool:
        """Remove a user from project team"""
        project = self.get_project_by_id(project_id)
        user = self.db.query(User).filter(User.id == user_id).first()
        
        if not project or not user:
            return False

        if user in project.team_members:
            project.team_members.remove(user)
            self.db.commit()
        
        return True

    def update_project(self, project_id: str, project_data: dict) -> Project:
        """Update project information"""
        project = self.get_project_by_id(project_id)
        if not project:
            return None

        for key, value in project_data.items():
            if hasattr(project, key) and value is not None:
                if key == 'required_skills':
                    project.required_skills = json.dumps(value)
                else:
                    setattr(project, key, value)

        self.db.commit()
        self.db.refresh(project)
        return project

    def delete_project(self, project_id: str, user_id: str) -> bool:
        """Delete a project (only by owner)"""
        project = self.get_project_by_id(project_id)
        if not project or project.owner_id != user_id:
            return False

        self.db.delete(project)
        self.db.commit()
        return True

    def get_user_projects(self, user_id: str) -> list:
        """Get projects where user is owner or team member"""
        # Projects owned by user
        owned_projects = self.db.query(Project).filter(Project.owner_id == user_id).all()
        
        # Projects where user is team member
        user = self.db.query(User).filter(User.id == user_id).first()
        team_projects = user.projects if user else []
        
        # Combine and remove duplicates
        all_projects = list(set(owned_projects + team_projects))
        return all_projects
    def get_relevant_suggestions(user_id: int, db: Session):
        user = db.query(User).filter(User.id == user_id).first()
        
        if not user or not user.skills:
            return []
        
        # گەڕان بەپێی سکیڵەکان + پلەی یەکسانی
        return db.query(Project).filter(
            Project.required_skills.any(Skill.name.in_([s.name for s in user.skills]))).order_by(
            Project.team_size.desc(),  # پڕۆژەی گەورەتری تیم
            Project.created_at.desc()   # نوێترین
            ).limit(5).all()