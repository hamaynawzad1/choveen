import datetime
from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import List, Optional
from app.core.database import get_db
from app.models.user import User
from app.api.auth import get_current_user
from app.services.ai_service import get_ai_service

router = APIRouter(prefix="/interest-groups", tags=["interest-groups"])

class CreateInterestGroupRequest(BaseModel):
    project_title: str
    project_description: str
    ai_suggestion_data: Optional[dict] = None

class InterestGroupResponse(BaseModel):
    id: str
    project_title: str
    member_count: int
    ai_chat_id: str
    group_chat_id: str
    created_at: str

class JoinInterestGroupRequest(BaseModel):
    group_id: str

@router.post("/create", response_model=InterestGroupResponse)
async def create_interest_group(
    request: CreateInterestGroupRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Create interest group for AI-suggested project
    """
    try:
        import uuid
        from datetime import datetime
        
        # Generate unique IDs
        group_id = f"ig_{uuid.uuid4().hex[:8]}"
        ai_chat_id = f"ai_{uuid.uuid4().hex[:8]}"
        group_chat_id = f"gc_{uuid.uuid4().hex[:8]}"
        
        # Here you would:
        # 1. Create interest group in database
        # 2. Create AI chat with project context
        # 3. Create group chat for members
        # 4. Add current user as first member
        
        # For demo purposes, return mock data
        return InterestGroupResponse(
            id=group_id,
            project_title=request.project_title,
            member_count=1,
            ai_chat_id=ai_chat_id,
            group_chat_id=group_chat_id,
            created_at=datetime.now().isoformat()
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create interest group: {str(e)}")

@router.post("/join")
async def join_interest_group(
    request: JoinInterestGroupRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Join existing interest group
    """
    try:
        # Here you would:
        # 1. Check if group exists
        # 2. Add user to group
        # 3. Add user to group chat
        # 4. Send notification to other members
        # 5. Check if enough members to form team
        
        return {
            "message": "Successfully joined interest group",
            "group_id": request.group_id,
            "member_count": 2  # Demo data
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to join interest group: {str(e)}")

@router.get("/my-groups")
async def get_my_interest_groups(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get user's interest groups
    """
    try:
        # Here you would fetch user's interest groups from database
        
        # Demo data
        return {
            "groups": [
                {
                    "id": "ig_12345678",
                    "project_title": "Mobile App Development",
                    "member_count": 3,
                    "ai_chat_id": "ai_12345678",
                    "group_chat_id": "gc_12345678",
                    "status": "active",
                    "created_at": "2025-01-01T10:00:00Z"
                }
            ]
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch interest groups: {str(e)}")

@router.post("/ai-chat/{chat_id}/message")
async def send_ai_message(
    chat_id: str,
    message: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Send message to AI chat in interest group
    """
    try:
        # Get project context for this chat
        # For demo, we'll use a generic context
        project_title = "Interest Group Project"
        project_description = "AI-suggested project from interest group"
        
        ai_service = get_ai_service(db)
        
        # Get AI response with project context
        ai_response = ai_service.get_project_chat_response(
            message=message,
            project_title=project_title,
            project_description=project_description
        )
        
        # Here you would:
        # 1. Save user message to database
        # 2. Save AI response to database
        # 3. Update chat history
        
        return {
            "user_message": message,
            "ai_response": ai_response,
            "chat_id": chat_id,
            "timestamp": datetime.now().isoformat()
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to send AI message: {str(e)}")

@router.get("/ai-chat/{chat_id}/messages")
async def get_ai_chat_messages(
    chat_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get AI chat messages for interest group
    """
    try:
        # Here you would fetch chat messages from database
        
        # Demo data
        return {
            "messages": [
                {
                    "id": "msg_1",
                    "sender": "ai",
                    "content": "Hello! I'm here to help you plan this project. What would you like to discuss?",
                    "timestamp": "2025-01-01T10:00:00Z"
                },
                {
                    "id": "msg_2", 
                    "sender": "user",
                    "content": "What are the main tasks we should focus on?",
                    "timestamp": "2025-01-01T10:01:00Z"
                }
            ],
            "chat_id": chat_id
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch AI chat messages: {str(e)}")

@router.post("/check-team-formation/{group_id}")
async def check_team_formation(
    group_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Check if interest group is ready to form a real team/project
    """
    try:
        # Here you would:
        # 1. Check member count
        # 2. Check skill coverage
        # 3. Check member activity
        # 4. Suggest team formation if ready
        
        # Demo logic
        member_count = 3  # Mock data
        min_members = 2
        
        if member_count >= min_members:
            return {
                "ready_for_team": True,
                "member_count": member_count,
                "message": "Your interest group is ready to form a real project team!",
                "next_steps": [
                    "Create official project",
                    "Assign roles to team members", 
                    "Set project timeline",
                    "Start development"
                ]
            }
        else:
            return {
                "ready_for_team": False,
                "member_count": member_count,
                "members_needed": min_members - member_count,
                "message": f"Need {min_members - member_count} more member(s) to form a team"
            }
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to check team formation: {str(e)}")