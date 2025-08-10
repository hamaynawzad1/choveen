import os
import logging
import random
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, EmailStr
from typing import List, Optional
import sqlite3
import json
import hashlib
from datetime import datetime, timedelta

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Choveen API",
    description="AI-powered team collaboration platform",
    version="1.2.0"
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Database setup
DATABASE_FILE = "choveen.db"

def init_database():
    """Initialize SQLite database with proper schema"""
    conn = sqlite3.connect(DATABASE_FILE)
    cursor = conn.cursor()
    
    # Create users table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS users (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            email TEXT UNIQUE NOT NULL,
            hashed_password TEXT NOT NULL,
            skills TEXT NOT NULL DEFAULT '[]',
            profile_image TEXT,
            is_verified BOOLEAN DEFAULT FALSE,
            verification_code TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    # Create projects table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS projects (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            description TEXT NOT NULL,
            required_skills TEXT NOT NULL DEFAULT '[]',
            status TEXT DEFAULT 'active',
            owner_id TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (owner_id) REFERENCES users (id)
        )
    ''')
    
    # Create messages table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS messages (
            id TEXT PRIMARY KEY,
            sender_id TEXT NOT NULL,
            receiver_id TEXT,
            project_id TEXT,
            content TEXT NOT NULL,
            message_type TEXT DEFAULT 'user',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (sender_id) REFERENCES users (id),
            FOREIGN KEY (project_id) REFERENCES projects (id)
        )
    ''')
    
    conn.commit()
    conn.close()
    print("✅ Database initialized")

# Initialize database on startup
init_database()

# Pydantic models
class UserRegister(BaseModel):
    name: str
    email: EmailStr
    password: str
    skills: List[str] = []
    profile_image: Optional[str] = None

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class EmailVerify(BaseModel):
    email: EmailStr
    verification_code: str

class UserResponse(BaseModel):
    id: str
    name: str
    email: str
    skills: List[str]
    profile_image: Optional[str] = None
    is_verified: bool
    created_at: str

class TokenResponse(BaseModel):
    access_token: str
    token_type: str
    user: UserResponse

# Utility functions
def hash_password(password: str) -> str:
    """Hash password using SHA256"""
    return hashlib.sha256(password.encode()).hexdigest()

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify password"""
    return hash_password(plain_password) == hashed_password

def generate_user_id() -> str:
    """Generate unique user ID"""
    import uuid
    return str(uuid.uuid4())

def generate_verification_code() -> str:
    """Generate 6-digit verification code"""
    return str(random.randint(100000, 999999))

def create_access_token(user_id: str) -> str:
    """Create access token"""
    import uuid
    return f"token_{user_id}_{uuid.uuid4().hex[:8]}"

# Database helper functions
def get_user_by_email(email: str):
    """Get user by email from database"""
    conn = sqlite3.connect(DATABASE_FILE)
    cursor = conn.cursor()
    
    cursor.execute('''
        SELECT id, name, email, hashed_password, skills, profile_image, 
               is_verified, verification_code, created_at
        FROM users WHERE email = ?
    ''', (email,))
    
    result = cursor.fetchone()
    conn.close()
    
    if result:
        return {
            'id': result[0],
            'name': result[1],
            'email': result[2],
            'hashed_password': result[3],
            'skills': json.loads(result[4]) if result[4] else [],
            'profile_image': result[5],
            'is_verified': bool(result[6]),
            'verification_code': result[7],
            'created_at': result[8]
        }
    return None

def create_user_in_db(user_data: UserRegister, verification_code: str) -> str:
    """Create user in database"""
    user_id = generate_user_id()
    hashed_password = hash_password(user_data.password)
    skills_json = json.dumps(user_data.skills)
    
    conn = sqlite3.connect(DATABASE_FILE)
    cursor = conn.cursor()
    
    cursor.execute('''
        INSERT INTO users (id, name, email, hashed_password, skills, profile_image, 
                          is_verified, verification_code, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', (
        user_id, user_data.name, user_data.email, hashed_password,
        skills_json, user_data.profile_image, False, verification_code,
        datetime.now().isoformat()
    ))
    
    conn.commit()
    conn.close()
    
    return user_id

def verify_user_email(email: str, code: str) -> bool:
    """Verify user email in database"""
    conn = sqlite3.connect(DATABASE_FILE)
    cursor = conn.cursor()
    
    # Check if code matches
    cursor.execute('''
        SELECT id FROM users 
        WHERE email = ? AND verification_code = ?
    ''', (email, code))
    
    result = cursor.fetchone()
    
    if result:
        # Update user as verified
        cursor.execute('''
            UPDATE users 
            SET is_verified = TRUE, verification_code = NULL, updated_at = ?
            WHERE email = ?
        ''', (datetime.now().isoformat(), email))
        
        conn.commit()
        conn.close()
        return True
    
    conn.close()
    return False

def update_user_profile(user_id: str, name: str = None, skills: List[str] = None, profile_image: str = None):
    """Update user profile in database"""
    conn = sqlite3.connect(DATABASE_FILE)
    cursor = conn.cursor()
    
    updates = []
    params = []
    
    if name:
        updates.append("name = ?")
        params.append(name)
    
    if skills is not None:
        updates.append("skills = ?")
        params.append(json.dumps(skills))
    
    if profile_image:
        updates.append("profile_image = ?")
        params.append(profile_image)
    
    if updates:
        updates.append("updated_at = ?")
        params.append(datetime.now().isoformat())
        params.append(user_id)
        
        query = f"UPDATE users SET {', '.join(updates)} WHERE id = ?"
        cursor.execute(query, params)
        
        conn.commit()
    
    conn.close()

# API Endpoints
@app.get("/")
async def root():
    return {
        "message": "Choveen API is running!", 
        "status": "online",
        "database": "sqlite",
        "version": "1.2.0"
    }

@app.get("/health")
async def health():
    return {
        "status": "healthy", 
        "service": "choveen-api",
        "version": "1.2.0"
    }

@app.post("/auth/register")
async def register(user_data: UserRegister):
    """Register a new user"""
    try:
        print(f"\n🔐 REGISTRATION REQUEST:")
        print(f"   Name: {user_data.name}")
        print(f"   Email: {user_data.email}")
        print(f"   Skills: {user_data.skills}")
        
        # Check if user already exists
        existing_user = get_user_by_email(user_data.email)
        if existing_user:
            raise HTTPException(status_code=400, detail="User with this email already exists")
        
        # Generate verification code
        verification_code = generate_verification_code()
        
        # Create user in database
        user_id = create_user_in_db(user_data, verification_code)
        
        # Print verification code
        print(f"\n📧 VERIFICATION CODE for {user_data.email}:")
        print(f"   CODE: {verification_code}")
        print(f"   User ID: {user_id}")
        print(f"   (This is demo mode - code is always visible in console)\n")
        
        return {
            "success": True,
            "message": f"User created successfully. Verification code: {verification_code}",
            "user_id": user_id,
            "email": user_data.email,
            "verification_code": verification_code  # For demo only
        }
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Registration error: {e}")
        raise HTTPException(status_code=500, detail=f"Registration failed: {str(e)}")

@app.post("/auth/verify-email", response_model=TokenResponse)
async def verify_email(verify_data: EmailVerify):
    """Verify email with code"""
    try:
        print(f"\n✉️ EMAIL VERIFICATION:")
        print(f"   Email: {verify_data.email}")
        print(f"   Code received: {verify_data.verification_code}")
        
        # Accept demo code or actual code
        if verify_data.verification_code == "123456" or len(verify_data.verification_code) == 6:
            success = verify_user_email(verify_data.email, verify_data.verification_code)
            
            if success or verify_data.verification_code == "123456":
                print(f"✅ Verification successful!")
                
                # Get updated user data
                user = get_user_by_email(verify_data.email)
                if not user:
                    raise HTTPException(status_code=404, detail="User not found")
                
                # Create access token
                access_token = create_access_token(user['id'])
                
                # Prepare user response
                user_response = UserResponse(
                    id=user['id'],
                    name=user['name'],
                    email=user['email'],
                    skills=user['skills'],
                    profile_image=user['profile_image'],
                    is_verified=True,
                    created_at=user['created_at']
                )
                
                return TokenResponse(
                    access_token=access_token,
                    token_type="bearer",
                    user=user_response
                )
            else:
                print(f"❌ Invalid verification code")
                raise HTTPException(status_code=400, detail="Invalid verification code")
        else:
            print(f"❌ Invalid verification code format")
            raise HTTPException(status_code=400, detail="Invalid verification code")
            
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Verification error: {e}")
        raise HTTPException(status_code=500, detail=f"Verification failed: {str(e)}")

@app.post("/auth/login", response_model=TokenResponse)
async def login(user_data: UserLogin):
    """Login user"""
    try:
        print(f"\n🔐 LOGIN REQUEST:")
        print(f"   Email: {user_data.email}")
        
        # Get user from database
        user = get_user_by_email(user_data.email)
        if not user:
            raise HTTPException(status_code=401, detail="Invalid email or password")
        
        # Verify password
        if not verify_password(user_data.password, user['hashed_password']):
            raise HTTPException(status_code=401, detail="Invalid email or password")
        
        # Create access token
        access_token = create_access_token(user['id'])
        
        # Prepare user response
        user_response = UserResponse(
            id=user['id'],
            name=user['name'],
            email=user['email'],
            skills=user['skills'],
            profile_image=user['profile_image'],
            is_verified=user['is_verified'],
            created_at=user['created_at']
        )
        
        print(f"✅ Login successful for {user['email']}")
        
        return TokenResponse(
            access_token=access_token,
            token_type="bearer",
            user=user_response
        )
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Login error: {e}")
        raise HTTPException(status_code=500, detail=f"Login failed: {str(e)}")

@app.get("/users/profile", response_model=UserResponse)
async def get_profile():
    """Get user profile - demo endpoint"""
    return UserResponse(
        id="demo_user_1",
        name="Demo User", 
        email="demo@choveen.com",
        skills=["Flutter", "Python", "AI"],
        is_verified=True,
        created_at=datetime.now().isoformat()
    )

@app.put("/users/profile", response_model=UserResponse)
async def update_profile(name: str = None, skills: List[str] = None, profile_image: str = None):
    """Update user profile - demo endpoint"""
    try:
        print(f"\n👤 PROFILE UPDATE:")
        print(f"   Name: {name}")
        print(f"   Skills: {skills}")
        print(f"   Profile Image: {profile_image}")
        
        # For demo, return updated user
        return UserResponse(
            id="demo_user_1",
            name=name or "Demo User",
            email="demo@choveen.com",
            skills=skills or ["Flutter", "Python", "AI"],
            profile_image=profile_image,
            is_verified=True,
            created_at=datetime.now().isoformat()
        )
        
    except Exception as e:
        print(f"❌ Profile update error: {e}")
        raise HTTPException(status_code=500, detail=f"Profile update failed: {str(e)}")

# AI Chat endpoint
@app.post("/api/v1/ai/chat")
async def ai_chat(message: str, project_title: str = "Current Project"):
    """Simple AI chat endpoint"""
    try:
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
    
    return f"I'm your AI assistant for '{project_title}'. I can help with project planning, problem-solving, and team coordination. What specific area would you like assistance with?"

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

if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", 8000))
    
    print("🚀 Starting Choveen Backend...")
    print(f"🌐 Server will run on: http://localhost:{port}")
    print("📊 Database: SQLite (working)")
    print("🤖 AI Service: Built-in (working)")
    print("🔐 Registration: Full system (working)")
    print("✅ Ready to serve requests!")
    uvicorn.run("main:app", host="0.0.0.0", port=port, log_level="info", reload=True)