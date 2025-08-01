from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
from datetime import datetime

from app.core.database import get_db
from app.models.user import User
from app.models.message import Message
from app.models.project import Project
from app.services.ai_service import get_enhanced_ai_service, ChatMessage
from app.api.auth import get_current_user

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
    """Enhanced AI Chat with DeepSeek Integration"""
    try:
        start_time = datetime.now()
        
        # Validate input
        if not request.message.strip():
            raise HTTPException(status_code=400, detail="Message cannot be empty")
        
        if not request.project_id.strip():
            raise HTTPException(status_code=400, detail="Project ID is required")
        
        # Get AI service
        ai_service = get_enhanced_ai_service()
        
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
        
        # Generate AI response
        ai_response = ai_service.generate_smart_response(
            message=request.message.strip(),
            project_title=request.project_title or "Current Project",
            project_context=project_context,
            conversation_history=conversation_history,
            max_tokens=200,
            temperature=0.7
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
        
        # Determine model used
        model_used = "DeepSeek" if ai_service.is_initialized and not ai_service.fallback_mode else "Enhanced Fallback"
        
        return AIChatResponse(
            response=ai_response,
            project_id=request.project_id,
            message_id=user_message.id,
            ai_message_id=ai_message.id,
            processing_time=processing_time,
            model_used=model_used
        )
        
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        print(f"Error in AI chat: {e}")
        raise HTTPException(status_code=500, detail="Failed to process AI chat")

@router.post("/suggestions", response_model=ProjectSuggestionResponse)
async def generate_ai_suggestions(
    request: ProjectSuggestionRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Generate intelligent project suggestions using AI"""
    try:
        ai_service = get_enhanced_ai_service()
        
        # Generate suggestions based on user skills and interests
        suggestions_prompt = f"""
        Generate 3-5 project suggestions for a user with these skills: {', '.join(request.user_skills)}
        Interests: {', '.join(request.interests) if request.interests else 'General development'}
        Difficulty level: {request.difficulty_level}
        
        For each project, provide:
        - Title and brief description
        - Required skills (matching user's skills)
        - Estimated duration
        - Key features to implement
        - Learning outcomes
        """
        
        if ai_service.is_initialized and not ai_service.fallback_mode:
            ai_suggestions = ai_service.generate_smart_response(
                message=suggestions_prompt,
                project_title="Project Suggestions",
                project_context="Skill-based project recommendations",
                max_tokens=500,
                temperature=0.8
            )
            
            # Parse AI response into structured suggestions
            suggestions = _parse_ai_suggestions(ai_suggestions, request.user_skills, request.difficulty_level)
            generated_by = "DeepSeek AI"
            
        else:
            # Fallback to predefined suggestions
            suggestions = _generate_fallback_suggestions(request.user_skills, request.difficulty_level)
            generated_by = "Fallback System"
        
        return ProjectSuggestionResponse(
            suggestions=suggestions,
            total_count=len(suggestions),
            user_skills=request.user_skills,
            generated_by=generated_by,
            timestamp=datetime.now().isoformat()
        )
        
    except Exception as e:
        print(f"Error generating suggestions: {e}")
        # Emergency fallback
        fallback_suggestions = [{
            "id": f"proj_fallback_{hash(str(request.user_skills)) % 10000}",
            "project": {
                "id": f"proj_fallback_{hash(str(request.user_skills)) % 10000}",
                "title": "Skill-Based Portfolio Project",
                "description": f"Create a comprehensive portfolio showcasing your {', '.join(request.user_skills[:3])} skills",
                "required_skills": request.user_skills[:3] if request.user_skills else ["Programming", "Design"],
                "category": "Portfolio",
                "estimated_duration": "4-6 weeks"
            },
            "description": "Perfect project to demonstrate your abilities",
            "match_score": 0.85,
            "timeline": "4-6 weeks",
            "difficulty": request.difficulty_level.title(),
            "ai_generated": True,
            "fallback": True
        }]
        
        return ProjectSuggestionResponse(
            suggestions=fallback_suggestions,
            total_count=1,
            user_skills=request.user_skills,
            generated_by="Emergency Fallback System",
            timestamp=datetime.now().isoformat()
        )

@router.get("/chat/{project_id}/messages")
async def get_ai_chat_messages(
    project_id: str,
    skip: int = 0,
    limit: int = 50,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get AI chat messages for a project with enhanced formatting"""
    try:
        messages = db.query(Message).filter(
            Message.project_id == project_id
        ).order_by(Message.created_at.asc()).offset(skip).limit(limit).all()
        
        # Enhanced message formatting
        formatted_messages = []
        for msg in messages:
            formatted_msg = {
                "id": msg.id,
                "sender_id": msg.sender_id,
                "content": msg.content,
                "message_type": msg.message_type,
                "created_at": msg.created_at.isoformat(),
                "project_id": msg.project_id,
                "is_ai": msg.sender_id == "ai_assistant",
                "formatted_time": _format_message_time(msg.created_at),
                "word_count": len(msg.content.split()),
                "char_count": len(msg.content)
            }
            formatted_messages.append(formatted_msg)
        
        return {
            "messages": formatted_messages,
            "total": len(formatted_messages),
            "project_id": project_id,
            "pagination": {
                "skip": skip,
                "limit": limit,
                "has_more": len(formatted_messages) == limit
            }
        }
        
    except Exception as e:
        print(f"Error fetching messages: {e}")
        return {"messages": [], "total": 0, "project_id": project_id}

def _parse_ai_suggestions(ai_response: str, user_skills: List[str], difficulty: str) -> List[Dict]:
    """Parse AI response into structured project suggestions"""
    suggestions = []
    
    # Simple parsing - in production, use more sophisticated NLP
    sections = ai_response.split('\n\n')
    
    for i, section in enumerate(sections[:5]):  # Max 5 suggestions
        if len(section.strip()) > 50:  # Valid suggestion
            lines = section.strip().split('\n')
            title = lines[0].strip('**').strip('#').strip()
            
            suggestion = {
                "id": f"ai_proj_{hash(title) % 10000}",
                "project": {
                    "id": f"ai_proj_{hash(title) % 10000}",
                    "title": title,
                    "description": section,
                    "required_skills": user_skills[:3],
                    "category": "AI Generated",
                    "estimated_duration": "3-6 weeks"
                },
                "description": section[:200] + "..." if len(section) > 200 else section,
                "match_score": 0.9 - (i * 0.1),
                "timeline": "3-6 weeks",
                "difficulty": difficulty.title(),
                "ai_generated": True,
                "fallback": False
            }
            suggestions.append(suggestion)
    
    return suggestions if suggestions else _generate_fallback_suggestions(user_skills, difficulty)

def _generate_fallback_suggestions(user_skills: List[str], difficulty: str) -> List[Dict]:
    """Generate fallback suggestions when AI is unavailable"""
    base_suggestions = [
        {
            "title": "Personal Portfolio Website",
            "description": "Build a professional portfolio showcasing your skills and projects",
            "category": "Web Development",
            "duration": "2-3 weeks"
        },
        {
            "title": "Task Management App",
            "description": "Create a full-featured task management application with user authentication",
            "category": "Full Stack",
            "duration": "4-6 weeks"
        },
        {
            "title": "E-commerce Platform",
            "description": "Develop a complete e-commerce solution with payment integration",
            "category": "Business Application",
            "duration": "6-8 weeks"
        }
    ]
    
    suggestions = []
    for i, base in enumerate(base_suggestions):
        suggestion = {
            "id": f"fallback_proj_{i}",
            "project": {
                "id": f"fallback_proj_{i}",
                "title": base["title"],
                "description": base["description"],
                "required_skills": user_skills[:3] if user_skills else ["Programming"],
                "category": base["category"],
                "estimated_duration": base["duration"]
            },
            "description": base["description"],
            "match_score": 0.8 - (i * 0.1),
            "timeline": base["duration"],
            "difficulty": difficulty.title(),
            "ai_generated": False,
            "fallback": True
        }
        suggestions.append(suggestion)
    
    return suggestions

def _format_message_time(created_at: datetime) -> str:
    """Format message timestamp for display"""
    now = datetime.utcnow()
    diff = now - created_at
    
    if diff.days > 0:
        return f"{diff.days} days ago"
    elif diff.seconds > 3600:
        hours = diff.seconds // 3600
        return f"{hours} hours ago"
    elif diff.seconds > 60:
        minutes = diff.seconds // 60
        return f"{minutes} minutes ago"
    else:
        return "Just now"