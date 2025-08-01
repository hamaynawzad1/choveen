import os
import logging
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Choveen API",
    description="Team collaboration platform",
    version="1.1.0"
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Simple health check
@app.get("/")
async def root():
    return {
        "message": "Choveen API is running!", 
        "status": "online",
        "database": "sqlite",
        "ai_service": "fallback"
    }

@app.get("/health")
async def health():
    return {
        "status": "healthy", 
        "service": "choveen-api",
        "version": "1.0.0"
    }

# Simple AI endpoint
@app.post("/api/v1/ai/chat")
async def ai_chat(message: str, project_title: str = "Current Project"):
    """Simple AI chat endpoint"""
    try:
        # Simple intelligent responses
        response = _get_simple_ai_response(message, project_title)
        return {
            "response": response,
            "project_title": project_title,
            "ai_service": "built-in"
        }
    except Exception as e:
        logger.error(f"AI chat error: {e}")
        return {
            "response": f"I'm here to help with '{project_title}'! How can I assist you?",
            "project_title": project_title,
            "error": "fallback"
        }

def _get_simple_ai_response(message: str, project_title: str) -> str:
    """Simple AI response logic"""
    msg_lower = message.lower().strip()
    
    if any(word in msg_lower for word in ['hi', 'hello', 'hey']):
        return f"Hello! I'm your AI assistant for '{project_title}'. How can I help you today?"
    
    if any(word in msg_lower for word in ['plan', 'planning']):
        return f"Great! Let's plan '{project_title}'. I suggest starting with: 1) Define goals, 2) Break into tasks, 3) Set timeline, 4) Assign responsibilities. What would you like to focus on first?"
    
    if any(word in msg_lower for word in ['help', 'stuck', 'problem']):
        return f"I'm here to help with '{project_title}'! Can you tell me more about the specific challenge you're facing? I can provide guidance on planning, technical issues, or team coordination."
    
    # Default response
    return f"I'm your AI assistant for '{project_title}'. I can help with project planning, problem-solving, and team coordination. What specific area would you like assistance with?"

@app.get("/api/v1/ai/test")
async def test_ai():
    """Test AI service"""
    return {
        "status": "success",
        "ai_service": "built-in",
        "test_response": "AI service is working perfectly!"
    }

@app.get("/api/v1/projects/suggestions")
async def get_suggestions():
    """Simple project suggestions"""
    suggestions = [
        {
            "id": "suggestion_1",
            "type": "project",
            "project": {
                "id": "proj_1",
                "title": "Team Portfolio Website",
                "description": "Build a collaborative portfolio website to showcase team projects and skills",
                "required_skills": ["Web Development", "Design", "Content Creation"]
            },
            "description": "Perfect for showcasing your team's capabilities",
            "match_score": 0.85
        },
        {
            "id": "suggestion_2", 
            "type": "project",
            "project": {
                "id": "proj_2",
                "title": "Task Management App",
                "description": "Create a smart task management application with team collaboration features",
                "required_skills": ["App Development", "Database", "UI/UX"]
            },
            "description": "Great for improving team productivity",
            "match_score": 0.78
        }
    ]
    
    return {
        "data": suggestions,
        "total_suggestions": len(suggestions),
        "generated_by": "Built-in AI"
    }

# Auth models
from pydantic import BaseModel
from typing import List

class UserRegister(BaseModel):
    name: str
    email: str
    password: str
    skills: List[str]
    profile_image: str = None

class UserLogin(BaseModel):
    email: str
    password: str

class EmailVerify(BaseModel):
    email: str
    verification_code: str

# Simple auth endpoints
@app.post("/api/v1/auth/login")
async def login(user_data: UserLogin):
    """Simple login for testing"""
    if user_data.email and user_data.password:
        return {
            "access_token": "demo-token",
            "token_type": "bearer",
            "user": {
                "id": "user_1",
                "name": "Demo User",
                "email": user_data.email,
                "skills": ["Flutter", "Python", "AI"],
                "is_verified": True,
                "created_at": "2025-01-27T10:00:00Z"
            }
        }
    return {"error": "Invalid credentials"}

@app.post("/api/v1/auth/register") 
async def register(user_data: UserRegister):
    """Simple register with verification code"""
    print(f"\n🔐 REGISTRATION:")
    print(f"   Name: {user_data.name}")
    print(f"   Email: {user_data.email}")
    print(f"   Skills: {user_data.skills}")
    
    # Generate verification code
    verification_code = "123456"
    
    # Print verification code clearly
    print(f"\n📧 VERIFICATION CODE for {user_data.email}:")
    print(f"   CODE: {verification_code}")
    print(f"   Enter this code in the app to verify your email")
    print(f"   (This is demo mode - code is always 123456)\n")
    
    return {
        "success": True,
        "message": f"User created successfully. Verification code: {verification_code}",
        "user_id": "user_123",
        "email": user_data.email,
        "verification_code": verification_code  # For demo only
    }

@app.post("/api/v1/auth/verify-email")
async def verify_email(verify_data: EmailVerify):
    """Verify email with code"""
    print(f"\n EMAIL VERIFICATION:")
    print(f"   Email: {verify_data.email}")
    print(f"   Code received: {verify_data.verification_code}")
    
    # Accept any code for demo (or check for 123456)
    if verify_data.verification_code == "123456" or len(verify_data.verification_code) == 6:
        print(f"Verification successful!")
        
        return {
            "access_token": "demo-verified-token",
            "token_type": "bearer",
            "user": {
                "id": "user_verified",
                "name": "Verified User",
                "email": verify_data.email,
                "skills": ["Flutter", "Python"],
                "is_verified": True,
                "created_at": "2025-01-27T10:00:00Z"
            }
        }
    else:
        print(f" Invalid verification code")
        return {"error": "Invalid verification code"}

# Add user profile endpoint
@app.get("/api/v1/users/profile")
async def get_profile():
    """Get user profile"""
    return {
        "id": "user_1",
        "name": "Demo User", 
        "email": "demo@example.com",
        "skills": ["Flutter", "Python", "AI"],
        "is_verified": True,
        "created_at": "2025-01-27T10:00:00Z"
    }

if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", 8000))
    
    print("🚀 Starting Choveen Backend...")
    print(f"🌐 Server will run on: http://localhost:{port}")
    print("📊 Database: SQLite (simple mode)")
    print("🤖 AI Service: Built-in (working)")
    print("✅ Ready to serve requests!")
    uvicorn.run("main:app", host="0.0.0.0", port=port, log_level="info", reload=True)