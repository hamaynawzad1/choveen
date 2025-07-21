# backend/app/api/ai_assistant.py - Complete AI Assistant with Database Saving
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from app.core.database import get_db
from app.models.user import User
from app.models.message import Message
from app.services.ai_service import get_ai_service
from app.api.auth import get_current_user
from datetime import datetime

router = APIRouter()

class AIChatRequest(BaseModel):
    project_id: str
    message: str
    project_title: str = ""

class AIChatResponse(BaseModel):
    response: str
    project_id: str
    message_id: str
    ai_message_id: str

@router.post("/chat", response_model=AIChatResponse)
async def ai_chat(
    request: AIChatRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Chat with AI assistant and save messages to database
    """
    try:
        # Validate input
        if not request.message.strip():
            raise HTTPException(status_code=400, detail="Message cannot be empty")
        
        if not request.project_id.strip():
            raise HTTPException(status_code=400, detail="Project ID is required")
        
        # Save user message to database
        user_message = Message(
            sender_id=current_user.id,
            project_id=request.project_id,
            content=request.message.strip(),
            message_type="user",
            created_at=datetime.utcnow()
        )
        db.add(user_message)
        db.commit()
        db.refresh(user_message)
        
        # Get AI response
        ai_service = get_ai_service(db)
        ai_response = ai_service.get_project_chat_response(
            request.message.strip(), 
            request.project_title,
            ""  # project description if needed
        )
        
        # Save AI response to database
        ai_message = Message(
            sender_id="ai_assistant",  # Special sender ID for AI
            project_id=request.project_id,
            content=ai_response,
            message_type="ai",
            created_at=datetime.utcnow()
        )
        db.add(ai_message)
        db.commit()
        db.refresh(ai_message)
        
        return AIChatResponse(
            response=ai_response,
            project_id=request.project_id,
            message_id=user_message.id,
            ai_message_id=ai_message.id
        )
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        print(f"Error in AI chat: {e}")
        raise HTTPException(status_code=500, detail="Failed to process AI chat")

@router.get("/chat/{project_id}/messages")
async def get_ai_chat_messages(
    project_id: str,
    skip: int = 0,
    limit: int = 50,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get AI chat messages for a project
    """
    try:
        messages = db.query(Message).filter(
            Message.project_id == project_id
        ).order_by(Message.created_at.asc()).offset(skip).limit(limit).all()
        
        # Convert to response format
        response_messages = []
        for msg in messages:
            response_messages.append({
                "id": msg.id,
                "sender_id": msg.sender_id,
                "content": msg.content,
                "message_type": msg.message_type,
                "created_at": msg.created_at.isoformat(),
                "project_id": msg.project_id
            })
        
        return {"data": response_messages}
        
    except Exception as e:
        print(f"Error getting AI chat messages: {e}")
        return {"data": []}

@router.delete("/chat/{project_id}/messages")
async def clear_ai_chat_messages(
    project_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Clear AI chat messages for a project
    """
    try:
        db.query(Message).filter(
            Message.project_id == project_id
        ).delete()
        db.commit()
        
        return {"message": "Chat history cleared successfully"}
        
    except Exception as e:
        db.rollback()
        print(f"Error clearing AI chat: {e}")
        raise HTTPException(status_code=500, detail="Failed to clear chat history")

# Legacy endpoint for compatibility
@router.post("/chat-legacy")
async def ai_chat_legacy(
    message: str,
    project_title: str = "Current Project",
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Legacy AI chat endpoint for backward compatibility
    """
    try:
        ai_service = get_ai_service(db)
        response = ai_service.get_project_chat_response(message, project_title)
        return {"response": response, "project_title": project_title}
    except Exception as e:
        return {"response": f"AI service error: {str(e)}", "project_title": project_title}