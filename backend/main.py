import os
import logging
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Import your existing routes
from app.api import auth, users, projects, chat as chat_api, ai_assistant
from app.services.ai_service import AIService

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Choveen API",
    description="Team collaboration platform with AI assistance",
    version="1.0.0"
)

# CORS for production
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure properly for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize database
try:
    logger.info("Creating database tables...")
    # Your existing database initialization code here
    logger.info("Database tables created successfully!")
except Exception as e:
    logger.error(f"Database initialization failed: {e}")

# Health check
@app.get("/")
async def root():
    return {"message": "Choveen API is running!", "status": "online"}

@app.get("/health")
async def health():
    return {"status": "healthy", "service": "choveen-api"}

# Include routers
app.include_router(auth.router, prefix="/api/v1/auth", tags=["auth"])
app.include_router(users.router, prefix="/api/v1/users", tags=["users"])
app.include_router(projects.router, prefix="/api/v1/projects", tags=["projects"])
app.include_router(chat_api.router, prefix="/api/v1/chat", tags=["chat"])

# AI endpoints
@app.post("/api/v1/ai/chat")
async def ai_chat(message: str, project_title: str = "Current Project"):
    try:
        ai_service = AIService()
        response = ai_service.get_project_chat_response(message, project_title)
        return {"response": response, "project_title": project_title}
    except Exception as e:
        return {"response": f"AI service error: {str(e)}", "project_title": project_title}

if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run("main:app", host="0.0.0.0", port=port, log_level="info")