# app/api/ai_assistant.py - Updated with Local DeepSeek
from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
from datetime import datetime

from app.core.database import get_db
from app.models.user import User
from app.models.message import Message
from app.models.project import Project
from app.services.ai_service import get_local_ai_service, ChatMessage
from app.api.auth import get_current_user
from app.core.config import settings

router = APIRouter()

class AIChatRequest(BaseModel):
    project_id: str
    message: str
    project_title: Optional[str] = ""
    project_context: Optional[str] = ""
    conversation_history: Optional[List[Dict]] = []

class AIChatResponse(BaseModel):
    response: str
    project_id: str
    message_id: str
    ai_message_id: str
    processing_time: float
    model_used: str
    model_info: Dict[str, Any]

class ProjectSuggestionRequest(BaseModel):
    user_skills: List[str]
    interests: Optional[List[str]] = []
    difficulty_level: Optional[str] = "intermediate"
    force_refresh: Optional[bool] = False

class ProjectSuggestionResponse(BaseModel):
    suggestions: List[Dict[str, Any]]
    total_count: int
    user_skills: List[str]
    generated_by: str
    timestamp: str

@router.post("/chat", response_model=AIChatResponse)
async def ai_chat(
    request: AIChatRequest,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Enhanced AI Chat with Local DeepSeek Integration"""
    try:
        start_time = datetime.now()
        
        # Validate input
        if not request.message.strip():
            raise HTTPException(status_code=400, detail="Message cannot be empty")
        
        if not request.project_id.strip():
            raise HTTPException(status_code=400, detail="Project ID is required")
        
        # Get local AI service
        ai_service = get_local_ai_service()
        
        # Convert conversation history to ChatMessage objects
        conversation_history = []
        if request.conversation_history:
            for msg in request.conversation_history[-10:]:  # Last 10 messages
                conversation_history.append(ChatMessage(
                    role=msg.get('role', 'user'),
                    content=msg.get('content', ''),
                    timestamp=msg.get('timestamp'),
                    project_id=request.project_id
                ))
        
        # Get project context if available
        project_context = request.project_context
        if not project_context:
            project = db.query(Project).filter(Project.id == request.project_id).first()
            if project:
                project_context = f"Project: {project.title}. Description: {project.description}"
        
        # Generate AI response using local DeepSeek
        ai_response = await ai_service.generate_smart_response(
            message=request.message.strip(),
            project_title=request.project_title or "Current Project",
            project_context=project_context,
            conversation_history=conversation_history,
            max_tokens=settings.DEEPSEEK_MAX_TOKENS,
            temperature=settings.DEEPSEEK_TEMPERATURE
        )
        
        # Save user message to database
        user_message = Message(
            sender_id=current_user.id,
            project_id=request.project_id,
            content=request.message.strip(),
            message_type="user",
            created_at=datetime.utcnow()
        )
        db.add(user_message)
        db.flush()  # Get ID without committing
        
        # Save AI response to database
        ai_message = Message(
            sender_id="ai_assistant",
            project_id=request.project_id,
            content=ai_response,
            message_type="ai",
            created_at=datetime.utcnow()
        )
        db.add(ai_message)
        db.commit()
        db.refresh(user_message)
        db.refresh(ai_message)
        
        # Calculate processing time
        processing_time = (datetime.now() - start_time).total_seconds()
        
        # Determine model used and get model info
        model_used = "Local DeepSeek" if ai_service.local_deepseek.is_initialized else "Enhanced Fallback"
        model_info = settings.get_model_info()
        
        return AIChatResponse(
            response=ai_response,
            project_id=request.project_id,
            message_id=user_message.id,
            ai_message_id=ai_message.id,
            processing_time=processing_time,
            model_used=model_used,
            model_info=model_info
        )
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        print(f"Error in AI chat: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to process AI chat: {str(e)}")

@router.get("/model-status")
async def get_model_status():
    """Get current AI model status"""
    try:
        ai_service = get_local_ai_service()
        model_info = settings.get_model_info()
        
        return {
            "status": "initialized" if ai_service.local_deepseek.is_initialized else "fallback",
            "model_info": model_info,
            "deepseek_available": settings.deepseek_available,
            "is_loading": ai_service.local_deepseek.is_loading,
            "service_type": settings.AI_SERVICE_TYPE,
            "timestamp": datetime.now().isoformat()
        }
    except Exception as e:
        return {
            "status": "error",
            "error": str(e),
            "timestamp": datetime.now().isoformat()
        }

@router.post("/reload-model")
async def reload_model():
    """Reload the DeepSeek model"""
    try:
        ai_service = get_local_ai_service()
        
        # Reset the service
        ai_service.local_deepseek.is_initialized = False
        ai_service.local_deepseek.is_loading = False
        
        # Reinitialize
        ai_service.local_deepseek._initialize_model()
        
        return {
            "status": "success" if ai_service.local_deepseek.is_initialized else "failed",
            "message": "Model reload completed",
            "model_info": settings.get_model_info(),
            "timestamp": datetime.now().isoformat()
        }
    except Exception as e:
        return {
            "status": "error",
            "error": str(e),
            "timestamp": datetime.now().isoformat()
        }

@router.post("/test-generation")
async def test_ai_generation(
    test_message: str = "Hello, how can you help me with my project?",
    project_title: str = "Test Project"
):
    """Test AI generation without saving to database"""
    try:
        start_time = datetime.now()
        ai_service = get_local_ai_service()
        
        response = await ai_service.generate_smart_response(
            message=test_message,
            project_title=project_title,
            project_context="This is a test project for AI functionality",
            conversation_history=[],
            max_tokens=100,
            temperature=0.7
        )
        
        processing_time = (datetime.now() - start_time).total_seconds()
        
        return {
            "status": "success",
            "request": {
                "message": test_message,
                "project_title": project_title
            },
            "response": response,
            "processing_time": processing_time,
            "model_used": "Local DeepSeek" if ai_service.local_deepseek.is_initialized else "Fallback",
            "model_info": settings.get_model_info(),
            "timestamp": datetime.now().isoformat()
        }
    except Exception as e:
        return {
            "status": "error",
            "error": str(e),
            "timestamp": datetime.now().isoformat()
        }

@router.post("/suggestions", response_model=ProjectSuggestionResponse)
async def generate_ai_suggestions(
    request: ProjectSuggestionRequest,
    current_user: User = Depends(get_current_user)
):
    """Generate AI-powered project suggestions using local DeepSeek"""
    try:
        ai_service = get_local_ai_service()
        
        # Create suggestion prompt
        skills_text = ", ".join(request.user_skills)
        interests_text = ", ".join(request.interests) if request.interests else "general development"
        
        suggestion_prompt = f"""Generate 3 innovative project suggestions for a developer with these skills: {skills_text}.
        
Interests: {interests_text}
Difficulty Level: {request.difficulty_level}

For each project, provide:
1. Project title
2. Brief description (2-3 sentences)
3. Key technologies needed
4. Difficulty level
5. Estimated timeline

Format as a structured response."""

        # Generate suggestions using AI
        ai_response = await ai_service.generate_smart_response(
            message=suggestion_prompt,
            project_title="Project Suggestion Generator",
            project_context="Generating personalized project suggestions",
            conversation_history=[],
            max_tokens=400,
            temperature=0.8
        )
        
        # Parse AI response into structured suggestions (simplified)
        suggestions = [
            {
                "id": f"ai_suggestion_{i+1}",
                "title": f"AI-Generated Project {i+1}",
                "description": ai_response[:200] + "..." if len(ai_response) > 200 else ai_response,
                "skills": request.user_skills,
                "difficulty": request.difficulty_level,
                "estimated_timeline": "4-8 weeks",
                "match_score": 0.8 + (i * 0.05),
                "generated_by_ai": True
            }
            for i in range(3)
        ]
        
        return ProjectSuggestionResponse(
            suggestions=suggestions,
            total_count=len(suggestions),
            user_skills=request.user_skills,
            generated_by="Local DeepSeek AI",
            timestamp=datetime.now().isoformat()
        )
        
    except Exception as e:
        # Fallback to static suggestions on error
        fallback_suggestions = [
            {
                "id": "fallback_1",
                "title": "Personal Portfolio Website",
                "description": "Create a modern, responsive portfolio showcasing your skills and projects",
                "skills": request.user_skills[:3],
                "difficulty": request.difficulty_level,
                "estimated_timeline": "2-4 weeks",
                "match_score": 0.7,
                "generated_by_ai": False
            }
        ]
        
        return ProjectSuggestionResponse(
            suggestions=fallback_suggestions,
            total_count=1,
            user_skills=request.user_skills,
            generated_by="Fallback System",
            timestamp=datetime.now().isoformat()
        )