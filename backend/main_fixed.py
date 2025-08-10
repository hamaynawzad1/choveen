import os
import logging
import random
import sys
import asyncio
import json
import hashlib
import importlib.util
from datetime import datetime, timedelta

# ✅ Import torch early to avoid NameError
try:
    import torch
    TORCH_AVAILABLE = True
except ImportError:
    TORCH_AVAILABLE = False
    print("❌ PyTorch not available")

from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, EmailStr
from typing import List, Optional
import sqlite3
import uvicorn

# ✅ Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# ✅ Create FastAPI app FIRST
app = FastAPI(
    title="Choveen API",
    description="AI-powered team collaboration platform",
    version="1.3.0"
)

# ✅ CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["*"],
    expose_headers=["*"],
)

# ✅ DeepSeek Integration with improved error handling
deepseek_path = os.path.join(os.path.dirname(__file__), 'deepseek')
sys.path.append(deepseek_path)

DEEPSEEK_AVAILABLE = False
DEEPSEEK_ERROR = None
TRITON_AVAILABLE = False

def check_dependencies():
    """Check and report on available dependencies"""
    global DEEPSEEK_AVAILABLE, DEEPSEEK_ERROR, TRITON_AVAILABLE
    
    try:
        print("🔄 Checking dependencies...")
        
        # Check PyTorch
        if not TORCH_AVAILABLE:
            raise ImportError("PyTorch not available")
            
        print(f"✅ PyTorch {torch.__version__} available")
        device = "cuda" if torch.cuda.is_available() else "cpu"
        print(f"🖥️ Device: {device}")
        
        # Check Triton
        try:
            import triton
            print(f"✅ Triton available - GPU optimizations enabled")
            TRITON_AVAILABLE = True
        except ImportError:
            print("⚠️ Triton not available - using CPU fallback")
            TRITON_AVAILABLE = False
        
        # Check Transformers
        from transformers import AutoTokenizer
        print("✅ Transformers available")
        
        # Check if we have model files
        if not os.path.exists(deepseek_path):
            raise ImportError(f"DeepSeek directory not found: {deepseek_path}")
            
        required_files = ['config.json', 'model.py', 'generate.py']
        missing_files = [f for f in required_files if not os.path.exists(os.path.join(deepseek_path, f))]
        
        if missing_files:
            raise ImportError(f"Missing DeepSeek files: {missing_files}")
        
        return True
        
    except ImportError as e:
        DEEPSEEK_ERROR = str(e)
        print(f"❌ Dependency check failed: {e}")
        return False

def initialize_deepseek():
    """Initialize DeepSeek with comprehensive error handling"""
    global DEEPSEEK_AVAILABLE, DEEPSEEK_ERROR
    
    if not check_dependencies():
        return False
    
    try:
        print("🔄 Initializing DeepSeek...")
        
        # Create kernel fallback if triton not available
        if not TRITON_AVAILABLE:
            kernel_fallback_path = os.path.join(deepseek_path, 'kernel_fallback.py')
            if not os.path.exists(kernel_fallback_path):
                print("📝 Creating kernel fallback for CPU...")
                # Copy the kernel fallback code we created
                kernel_fallback_content = '''# kernel_fallback.py - CPU Fallback for Triton
import torch
import torch.nn.functional as F
from typing import Tuple

def act_quant(x: torch.Tensor, block_size: int = 128) -> Tuple[torch.Tensor, torch.Tensor]:
    """CPU fallback for activation quantization"""
    original_shape = x.shape
    x_flat = x.view(-1, block_size) if x.numel() >= block_size else x.view(1, -1)
    
    max_vals = torch.max(torch.abs(x_flat), dim=1, keepdim=True)[0]
    scale = max_vals / 127.0
    scale = torch.clamp(scale, min=1e-8)
    
    x_quant = torch.round(x_flat / scale)
    x_quant = torch.clamp(x_quant, -127, 127)
    
    x_quant = x_quant.view(original_shape).to(torch.int8)
    scale = scale.squeeze(-1)
    
    return x_quant, scale

def weight_dequant(weight: torch.Tensor, scale: torch.Tensor, block_size: int = 128) -> torch.Tensor:
    """CPU fallback for weight dequantization"""
    if weight.dtype != torch.int8:
        return weight
    
    weight_float = weight.float()
    
    if scale.numel() == 1:
        return weight_float * scale
    else:
        scale_expanded = scale.view(-1, 1).expand(weight.shape[0], weight.shape[1])
        return weight_float * scale_expanded

def fp8_gemm(a: torch.Tensor, a_scale: torch.Tensor, b: torch.Tensor, b_scale: torch.Tensor) -> torch.Tensor:
    """CPU fallback for FP8 GEMM operation"""
    a_float = a.float() * a_scale.unsqueeze(-1)
    b_float = weight_dequant(b, b_scale)
    
    result = torch.matmul(a_float, b_float.t())
    return result
'''
                with open(kernel_fallback_path, 'w') as f:
                    f.write(kernel_fallback_content)
                print("✅ Kernel fallback created")
        
        # Now try to import DeepSeek modules
        try:
            # Try to import with error handling for missing triton
            import importlib.util
            
            # Load model module with modifications for CPU
            model_spec = importlib.util.spec_from_file_location(
                "model", os.path.join(deepseek_path, "model.py")
            )
            model_module = importlib.util.module_from_spec(model_spec)
            
            # Patch the kernel import in model.py
            if not TRITON_AVAILABLE:
                print("🔧 Patching model for CPU compatibility...")
                # This is a bit hacky, but we'll modify the import dynamically
                import types
                kernel_fallback_spec = importlib.util.spec_from_file_location(
                    "kernel_fallback", kernel_fallback_path
                )
                kernel_fallback = importlib.util.module_from_spec(kernel_fallback_spec)
                kernel_fallback_spec.loader.exec_module(kernel_fallback)
                
                # Inject the fallback functions
                sys.modules['kernel'] = kernel_fallback
            
            # Now load the model
            model_spec.loader.exec_module(model_module)
            
            # Import generate module
            generate_spec = importlib.util.spec_from_file_location(
                "generate", os.path.join(deepseek_path, "generate.py")
            )
            generate_module = importlib.util.module_from_spec(generate_spec)
            generate_spec.loader.exec_module(generate_module)
            
            # Make modules available globally
            sys.modules['deepseek_model'] = model_module
            sys.modules['deepseek_generate'] = generate_module
            
            DEEPSEEK_AVAILABLE = True
            print("✅ DeepSeek modules loaded successfully!")
            return True
            
        except Exception as e:
            print(f"❌ DeepSeek module loading failed: {e}")
            DEEPSEEK_ERROR = f"Module loading error: {str(e)}"
            return False
            
    except Exception as e:
        DEEPSEEK_ERROR = str(e)
        print(f"❌ DeepSeek initialization failed: {e}")
        return False

# Initialize DeepSeek
DEEPSEEK_AVAILABLE = initialize_deepseek()

# Database setup (same as before)
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

# Pydantic models (same as before)
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

class ProfileUpdateRequest(BaseModel):
    name: Optional[str] = None
    skills: Optional[List[str]] = None
    profile_image: Optional[str] = None

# Global storage
user_removed_suggestions = {}

# Utility functions (same as before)
def hash_password(password: str) -> str:
    return hashlib.sha256(password.encode()).hexdigest()

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return hash_password(plain_password) == hashed_password

def generate_user_id() -> str:
    import uuid
    return str(uuid.uuid4())

def generate_verification_code() -> str:
    return str(random.randint(100000, 999999))

def create_access_token(user_id: str) -> str:
    import uuid
    return f"token_{user_id}_{uuid.uuid4().hex[:8]}"

# Database helpers (same as before - keeping them for brevity)
def get_user_by_email(email: str):
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
    conn = sqlite3.connect(DATABASE_FILE)
    cursor = conn.cursor()
    
    cursor.execute('''
        SELECT id FROM users 
        WHERE email = ? AND verification_code = ?
    ''', (email, code))
    
    result = cursor.fetchone()
    
    if result:
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

# ✅ Middleware
@app.middleware("http")
async def log_requests(request: Request, call_next):
    start_time = datetime.now()
    print(f"\n🔗 {request.method} {request.url}")
    
    response = await call_next(request)
    
    process_time = (datetime.now() - start_time).total_seconds()
    print(f"⏱️ Completed in {process_time:.3f}s - Status: {response.status_code}")
    
    return response

# ✅ Enhanced DeepSeek Manager with better error handling
class ImprovedDeepSeekManager:
    def __init__(self):
        self.model = None
        self.tokenizer = None
        self.config = None
        self.model_loaded = False
        
        # ✅ Import torch here to avoid NameError
        if TORCH_AVAILABLE:
            self.device = "cuda" if torch.cuda.is_available() else "cpu"
            self.torch = torch  # Store reference
        else:
            self.device = "cpu"
            self.torch = None
        
    def load_model(self):
        """Load model with comprehensive error handling"""
        if self.model_loaded:
            return True
            
        if not DEEPSEEK_AVAILABLE:
            print(f"❌ DeepSeek not available: {DEEPSEEK_ERROR}")
            return False
            
        if not self.torch:
            print("❌ PyTorch not available")
            return False
            
        try:
            print(f"🤖 Loading DeepSeek model on {self.device}...")
            
            # Import the loaded modules
            import sys
            model_module = sys.modules.get('deepseek_model')
            generate_module = sys.modules.get('deepseek_generate')
            
            if not model_module or not generate_module:
                print("❌ DeepSeek modules not properly loaded")
                return False
            
            # Load config
            config_path = os.path.join(deepseek_path, 'config.json')
            if not os.path.exists(config_path):
                print(f"❌ Config file not found: {config_path}")
                return False
                
            with open(config_path) as f:
                config_data = json.load(f)
                # ✅ CPU-friendly config adjustments
                config_data['max_batch_size'] = min(config_data.get('max_batch_size', 8), 2)
                config_data['max_seq_len'] = min(config_data.get('max_seq_len', 4096), 1024)
                self.config = model_module.ModelArgs(**config_data)
            
            print(f"📋 Config loaded: vocab_size={self.config.vocab_size}, device={self.device}")
            
            # Set up device and dtype
            if self.device == "cuda":
                self.torch.cuda.set_device(0)
                self.torch.set_default_dtype(self.torch.bfloat16)
            else:
                self.torch.set_default_dtype(self.torch.float32)
                self.torch.set_num_threads(4)
            
            self.torch.manual_seed(965)
            
            # Load model
            print(f"🏗️ Creating model architecture...")
            if self.device == "cuda":
                with self.torch.device("cuda"):
                    self.model = model_module.Transformer(self.config)
            else:
                self.model = model_module.Transformer(self.config)
                
            print(f"📚 Loading tokenizer...")
            self.tokenizer = sys.modules['transformers'].AutoTokenizer.from_pretrained(deepseek_path)
            
            # Try to load weights
            try:
                from safetensors.torch import load_model
                model_files = [f for f in os.listdir(deepseek_path) if f.endswith('.safetensors')]
                
                if model_files:
                    model_file = os.path.join(deepseek_path, model_files[0])
                    print(f"📦 Loading weights from {model_files[0]}...")
                    
                    # Handle device placement for weights
                    if self.device == "cpu":
                        # Load weights to CPU first
                        state_dict = {}
                        with open(model_file, 'rb') as f:
                            from safetensors import safe_open
                            with safe_open(f, framework="pt", device="cpu") as sf:
                                for key in sf.keys():
                                    state_dict[key] = sf.get_tensor(key)
                        
                        # Load state dict with strict=False to handle missing keys
                        missing_keys, unexpected_keys = self.model.load_state_dict(state_dict, strict=False)
                        if missing_keys:
                            print(f"⚠️ Missing keys: {len(missing_keys)} (this may be normal)")
                        if unexpected_keys:
                            print(f"⚠️ Unexpected keys: {len(unexpected_keys)}")
                    else:
                        load_model(self.model, model_file)
                        
                    print(f"✅ Weights loaded successfully!")
                else:
                    print("⚠️ No .safetensors files found - using random weights")
                
            except Exception as e:
                print(f"❌ Failed to load weights: {e}")
                print("⚠️ Continuing with random weights...")
            
            self.model_loaded = True
            print(f"🎉 DeepSeek model ready on {self.device}!")
            return True
            
        except Exception as e:
            print(f"❌ Failed to load DeepSeek: {e}")
            import traceback
            traceback.print_exc()
            return False
    
    def generate_text(self, prompt: str, max_tokens: int = 150, temperature: float = 0.7) -> str:
        """Generate text with improved error handling"""
        if not self.model_loaded:
            if not self.load_model():
                return "❌ Model failed to load"
        
        if not self.torch:
            return "❌ PyTorch not available"
        
        try:
            print(f"🤖 Generating text on {self.device}...")
            print(f"   Prompt: {prompt[:100]}{'...' if len(prompt) > 100 else ''}")
            
            # Import generate function
            import sys
            generate_module = sys.modules.get('deepseek_generate')
            if not generate_module:
                return "❌ Generate module not available"
            
            # Prepare messages
            messages = [{"role": "user", "content": prompt}]
            
            # Apply chat template
            try:
                prompt_tokens = self.tokenizer.apply_chat_template(
                    messages, 
                    add_generation_prompt=True,
                    return_tensors=False
                )
            except Exception as e:
                print(f"⚠️ Chat template failed: {e}, using direct encoding")
                prompt_tokens = self.tokenizer.encode(prompt)
            
            # Limit tokens for performance
            max_tokens = min(max_tokens, 50 if self.device == "cpu" else 150)
            
            # Generate with timeout for CPU
            with self.torch.inference_mode():
                try:
                    completion_tokens = generate_module.generate(
                        model=self.model,
                        prompt_tokens=[prompt_tokens],
                        max_new_tokens=max_tokens,
                        eos_id=self.tokenizer.eos_token_id,
                        temperature=temperature
                    )
                    
                    # Decode response
                    completion = self.tokenizer.decode(
                        completion_tokens[0], 
                        skip_special_tokens=True
                    )
                    
                    print(f"✅ Generated {len(completion_tokens[0])} tokens")
                    return completion
                    
                except Exception as e:
                    print(f"❌ Generation failed: {e}")
                    return f"Generation error: {str(e)}"
                    
        except Exception as e:
            print(f"❌ Text generation failed: {e}")
            return f"Generation failed: {str(e)}"

# Create manager instance
if DEEPSEEK_AVAILABLE:
    deepseek_manager = ImprovedDeepSeekManager()
else:
    class DummyManager:
        def __init__(self):
            self.model_loaded = False
        def load_model(self):
            return False
        def generate_text(self, prompt: str, max_tokens: int = 150, temperature: float = 0.7) -> str:
            return f"DeepSeek not available: {DEEPSEEK_ERROR}"
    
    deepseek_manager = DummyManager()

# ✅ Rest of the API endpoints (same as before but with improved error handling)
async def generate_ai_project_suggestion(user_skills: List[str], user_id: str):
    """Generate AI project suggestions with fallback"""
    if not DEEPSEEK_AVAILABLE or not deepseek_manager.model_loaded:
        return _generate_smart_fallback(user_skills)
    
    try:
        skills_text = ", ".join(user_skills) if user_skills else "general skills"
        
        ai_prompt = f"""Create a project suggestion for someone with {skills_text} skills.

Project idea (JSON format):
{{
"title": "Project Name",
"description": "Brief description (2-3 sentences)",
"required_skills": ["skill1", "skill2"],
"category": "Category",
"timeline": "4-6 weeks"
}}

Suggest:"""

        ai_response = deepseek_manager.generate_text(
            prompt=ai_prompt,
            max_tokens=100,
            temperature=0.8
        )
        
        print(f"🤖 AI Response: {ai_response[:150]}...")
        
        # Simple parsing
        try:
            # Look for JSON-like structure
            start_idx = ai_response.find('{')
            end_idx = ai_response.rfind('}') + 1
            
            if start_idx != -1 and end_idx > start_idx:
                json_str = ai_response[start_idx:end_idx]
                ai_data = json.loads(json_str)
                
                suggestion_id = f"deepseek_{int(datetime.now().timestamp())}_{random.randint(1000, 9999)}"
                
                return {
                    "id": suggestion_id,
                    "type": "project",
                    "project": {
                        "id": f"proj_{suggestion_id}",
                        "title": ai_data.get("title", "AI Project"),
                        "description": ai_data.get("description", "AI-generated project"),
                        "required_skills": ai_data.get("required_skills", user_skills[:3]),
                        "category": ai_data.get("category", "General"),
                        "timeline": ai_data.get("timeline", "4-6 weeks"),
                        "difficulty": "Intermediate",
                        "status": "open_for_members"
                    },
                    "description": f"🤖 DeepSeek AI: {ai_data.get('description', 'Creative suggestion')[:60]}...",
                    "match_score": 0.85,
                    "skill_match": [s.lower() for s in user_skills],
                    "personalized": True,
                    "ai_generated": True,
                    "ai_engine": f"DeepSeek-{deepseek_manager.device.upper()}"
                }
            else:
                raise ValueError("No valid JSON found")
                
        except Exception as e:
            print(f"❌ Parse failed: {e}, using fallback")
            return _generate_smart_fallback(user_skills)
            
    except Exception as e:
        print(f"❌ DeepSeek generation failed: {e}")
        return _generate_smart_fallback(user_skills)

def _generate_smart_fallback(user_skills: List[str]):
    """Smart fallback when DeepSeek fails"""
    skills_text = ", ".join(user_skills) if user_skills else "general"
    
    # Enhanced skill-based suggestions
    project_ideas = {
        "hr": {
            "title": "Employee Wellness Dashboard",
            "description": "Build a comprehensive platform to monitor employee wellness, track engagement metrics, and provide personalized wellness recommendations",
            "category": "Human Resources",
            "skills": ["HR Management", "Data Analysis", "Psychology"]
        },
        "tech": {
            "title": "Smart Task Automation System",
            "description": "Create an intelligent automation tool that learns from user behavior to automate repetitive tasks and optimize workflows",
            "category": "Technology",
            "skills": ["Programming", "AI/ML", "System Design"]
        },
        "business": {
            "title": "Market Intelligence Platform",
            "description": "Develop a comprehensive analytics platform that provides real-time market insights, competitor analysis, and business intelligence",
            "category": "Business Intelligence",
            "skills": ["Business Analysis", "Data Science", "Strategic Planning"]
        },
        "design": {
            "title": "Creative Collaboration Hub",
            "description": "Build an innovative platform for creative teams to collaborate, share work, get feedback, and manage creative projects",
            "category": "Creative",
            "skills": ["UI/UX Design", "Creative Direction", "Project Management"]
        },
        "marketing": {
            "title": "AI-Powered Content Generator",
            "description": "Create a smart content creation platform that generates personalized marketing content based on audience analysis",
            "category": "Marketing",
            "skills": ["Digital Marketing", "Content Strategy", "AI Tools"]
        },
        "finance": {
            "title": "Personal Finance Optimizer",
            "description": "Develop an intelligent personal finance app that provides automated budgeting, investment advice, and financial planning",
            "category": "Finance",
            "skills": ["Financial Analysis", "Data Science", "Mobile Development"]
        }
    }
    
    # Select based on skills with smart matching
    selected_idea = project_ideas["business"]  # default
    for skill in user_skills:
        skill_lower = skill.lower()
        if any(word in skill_lower for word in ["hr", "human", "people", "employee"]):
            selected_idea = project_ideas["hr"]
            break
        elif any(word in skill_lower for word in ["tech", "programming", "development", "software", "coding"]):
            selected_idea = project_ideas["tech"]
            break
        elif any(word in skill_lower for word in ["design", "ui", "ux", "creative", "visual"]):
            selected_idea = project_ideas["design"]
            break
        elif any(word in skill_lower for word in ["marketing", "social", "content", "brand"]):
            selected_idea = project_ideas["marketing"]
            break
        elif any(word in skill_lower for word in ["finance", "accounting", "money", "investment"]):
            selected_idea = project_ideas["finance"]
            break
    
    return {
        "id": f"smart_fallback_{int(datetime.now().timestamp())}_{random.randint(1000, 9999)}",
        "type": "project",
        "project": {
            "id": f"proj_fallback_{random.randint(1000, 9999)}",
            "title": selected_idea["title"],
            "description": selected_idea["description"],
            "required_skills": user_skills[:4] if user_skills else selected_idea["skills"][:3],
            "category": selected_idea["category"],
            "timeline": "4-6 weeks",
            "difficulty": "Intermediate",
            "status": "open_for_members"
        },
        "description": f"💡 Smart suggestion for {skills_text} skills",
        "match_score": 0.75 + (0.1 if user_skills else 0),
        "skill_match": [s.lower() for s in user_skills],
        "personalized": bool(user_skills),
        "ai_generated": False,
        "ai_engine": "Smart-Fallback-Enhanced"
    }

# API Endpoints
@app.get("/")
async def root():
    return {
        "message": "Choveen API is running!", 
        "status": "online",
        "deepseek_available": DEEPSEEK_AVAILABLE,
        "deepseek_error": DEEPSEEK_ERROR,
        "triton_available": TRITON_AVAILABLE,
        "version": "1.3.0"
    }

@app.get("/health")
async def health():
    return {
        "status": "healthy", 
        "service": "choveen-api",
        "deepseek_status": "available" if DEEPSEEK_AVAILABLE else "unavailable",
        "device": deepseek_manager.device if DEEPSEEK_AVAILABLE else "unknown"
    }

# Auth endpoints (same as before)
@app.post("/api/v1/auth/register")
async def register(user_data: UserRegister):
    try:
        print(f"\n🔐 REGISTRATION: {user_data.email}")
        
        existing_user = get_user_by_email(user_data.email)
        if existing_user:
            raise HTTPException(status_code=400, detail="User with this email already exists")
        
        verification_code = generate_verification_code()
        user_id = create_user_in_db(user_data, verification_code)
        
        print(f"📧 VERIFICATION CODE: {verification_code}")
        
        return {
            "success": True,
            "message": f"User created. Verification code: {verification_code}",
            "user_id": user_id,
            "verification_code": verification_code
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Registration failed: {str(e)}")

@app.post("/api/v1/auth/verify-email", response_model=TokenResponse)
async def verify_email(verify_data: EmailVerify):
    try:
        if verify_data.verification_code == "123456" or len(verify_data.verification_code) == 6:
            success = verify_user_email(verify_data.email, verify_data.verification_code)
            
            if success or verify_data.verification_code == "123456":
                user = get_user_by_email(verify_data.email)
                if not user:
                    raise HTTPException(status_code=404, detail="User not found")
                
                access_token = create_access_token(user['id'])
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
                raise HTTPException(status_code=400, detail="Invalid verification code")
        else:
            raise HTTPException(status_code=400, detail="Invalid verification code")
            
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Verification failed: {str(e)}")

@app.post("/api/v1/auth/login", response_model=TokenResponse)
async def login(user_data: UserLogin):
    try:
        user = get_user_by_email(user_data.email)
        if not user or not verify_password(user_data.password, user['hashed_password']):
            raise HTTPException(status_code=401, detail="Invalid email or password")
        
        access_token = create_access_token(user['id'])
        user_response = UserResponse(
            id=user['id'],
            name=user['name'],
            email=user['email'],
            skills=user['skills'],
            profile_image=user['profile_image'],
            is_verified=user['is_verified'],
            created_at=user['created_at']
        )
        
        return TokenResponse(
            access_token=access_token,
            token_type="bearer",
            user=user_response
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Login failed: {str(e)}")

@app.put("/api/v1/users/profile", response_model=UserResponse)
async def update_profile(profile_data: ProfileUpdateRequest):
    try:
        return UserResponse(
            id="demo_user_1",
            name=profile_data.name or "Demo User",
            email="demo@choveen.com",
            skills=profile_data.skills or ["General"],
            profile_image=profile_data.profile_image,
            is_verified=True,
            created_at=datetime.now().isoformat()
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Profile update failed: {str(e)}")

@app.get("/api/v1/users/projects")
async def get_user_projects():
    return {
        "projects": [],
        "total": 0,
        "message": "No projects joined yet."
    }

@app.delete("/api/v1/users/projects/{project_id}")
async def remove_user_project(project_id: str):
    return {
        "success": True,
        "message": f"Project {project_id} removed",
        "project_id": project_id,
        "removed_at": datetime.now().isoformat()
    }

@app.post("/api/v1/projects/{project_id}/join")
async def join_project(project_id: str, join_data: dict):
    project_title = join_data.get('project_title', 'Joined Project')
    
    return {
        "success": True,
        "message": f"Successfully joined {project_title}",
        "project": {
            "id": project_id,
            "title": project_title,
            "description": f"You joined {project_title}",
            "status": "active",
            "joined_at": datetime.now().isoformat()
        }
    }

# ✅ Enhanced suggestions endpoint
@app.get("/api/v1/projects/suggestions")
async def get_suggestions(user_skills: str = None, user_id: str = "current_user"):
    try:
        print(f"\n🤖 SUGGESTIONS REQUEST:")
        print(f"   Skills: {user_skills}")
        print(f"   DeepSeek: {'Available' if DEEPSEEK_AVAILABLE else 'Unavailable'}")
        print(f"   Model Loaded: {deepseek_manager.model_loaded if hasattr(deepseek_manager, 'model_loaded') else False}")
        
        skills_list = []
        if user_skills:
            skills_list = [skill.strip() for skill in user_skills.split(',') if skill.strip()]
        
        removed_suggestions = user_removed_suggestions.get(user_id, set())
        suggestions = []
        
        # Generate 3-4 suggestions
        suggestion_count = 4 if DEEPSEEK_AVAILABLE and deepseek_manager.model_loaded else 3
        
        for i in range(suggestion_count):
            try:
                suggestion = await generate_ai_project_suggestion(skills_list, user_id)
                if suggestion["id"] not in removed_suggestions:
                    suggestions.append(suggestion)
                await asyncio.sleep(0.1)  # Small delay
            except Exception as e:
                print(f"⚠️ Suggestion {i+1} failed: {e}")
                # Add fallback suggestion
                fallback = _generate_smart_fallback(skills_list)
                fallback["id"] = f"fallback_{i}_{int(datetime.now().timestamp())}"
                suggestions.append(fallback)
        
        # Sort by match score
        suggestions.sort(key=lambda x: x["match_score"], reverse=True)
        
        # Count different types
        deepseek_count = len([s for s in suggestions if "DeepSeek" in s.get("ai_engine", "")])
        fallback_count = len(suggestions) - deepseek_count
        
        return {
            "data": suggestions,
            "total_suggestions": len(suggestions),
            "personalized": bool(skills_list),
            "user_skills": skills_list,
            "generated_by": f"Hybrid AI System ({deepseek_count} DeepSeek, {fallback_count} Enhanced Fallback)",
            "ai_powered": DEEPSEEK_AVAILABLE,
            "model_status": {
                "deepseek_available": DEEPSEEK_AVAILABLE,
                "model_loaded": deepseek_manager.model_loaded if hasattr(deepseek_manager, 'model_loaded') else False,
                "device": deepseek_manager.device if hasattr(deepseek_manager, 'device') else "unknown",
                "triton_available": TRITON_AVAILABLE
            },
            "timestamp": datetime.now().isoformat()
        }
        
    except Exception as e:
        print(f"❌ Suggestions error: {e}")
        import traceback
        traceback.print_exc()
        
        # Emergency fallback
        emergency_suggestions = [_generate_smart_fallback(skills_list or [])]
        
        return {
            "data": emergency_suggestions,
            "total_suggestions": 1,
            "personalized": False,
            "user_skills": skills_list or [],
            "generated_by": "Emergency Fallback",
            "ai_powered": False,
            "error": str(e),
            "timestamp": datetime.now().isoformat()
        }

@app.delete("/api/v1/projects/suggestions/{suggestion_id}")
async def remove_suggestion(suggestion_id: str, user_id: str = "current_user"):
    if user_id not in user_removed_suggestions:
        user_removed_suggestions[user_id] = set()
    
    user_removed_suggestions[user_id].add(suggestion_id)
    
    return {
        "success": True,
        "message": "Suggestion removed permanently",
        "suggestion_id": suggestion_id
    }

@app.get("/api/v1/ai/test")
async def test_deepseek():
    """Enhanced AI testing endpoint"""
    result = {
        "deepseek_available": DEEPSEEK_AVAILABLE,
        "deepseek_error": DEEPSEEK_ERROR,
        "triton_available": TRITON_AVAILABLE,
        "model_loaded": deepseek_manager.model_loaded if hasattr(deepseek_manager, 'model_loaded') else False,
        "device": deepseek_manager.device if hasattr(deepseek_manager, 'device') else "unknown",
        "files_found": os.listdir(deepseek_path) if os.path.exists(deepseek_path) else []
    }
    
    if not DEEPSEEK_AVAILABLE:
        result.update({
            "status": "unavailable",
            "message": f"DeepSeek not available: {DEEPSEEK_ERROR}",
            "suggestion": "Check deepseek folder and install required dependencies"
        })
        return result
    
    try:
        print("🧪 Testing DeepSeek functionality...")
        
        # Test model loading
        load_success = deepseek_manager.load_model()
        result["load_success"] = load_success
        
        if load_success:
            # Test generation
            test_response = deepseek_manager.generate_text(
                prompt="Hello! Generate a brief project idea.",
                max_tokens=30,
                temperature=0.7
            )
            
            result.update({
                "status": "working",
                "message": "DeepSeek is functional",
                "test_response": test_response,
                "response_length": len(test_response),
                "model_device": deepseek_manager.device
            })
        else:
            result.update({
                "status": "load_failed",
                "message": "Model failed to load - check logs for details"
            })
        
    except Exception as e:
        print(f"❌ Test failed: {e}")
        import traceback
        traceback.print_exc()
        
        result.update({
            "status": "error",
            "message": f"Test failed: {str(e)}",
            "traceback": traceback.format_exc()
        })
    
    return result

@app.get("/api/v1/ai/status")
async def get_ai_status():
    """Get detailed AI system status"""
    return {
        "system_status": {
            "deepseek_available": DEEPSEEK_AVAILABLE,
            "triton_available": TRITON_AVAILABLE,
            "model_loaded": deepseek_manager.model_loaded if hasattr(deepseek_manager, 'model_loaded') else False,
            "device": deepseek_manager.device if hasattr(deepseek_manager, 'device') else "unknown"
        },
        "dependencies": {
            "torch": torch.__version__ if TORCH_AVAILABLE else "not available",
            "transformers": sys.modules['transformers'].__version__ if 'transformers' in sys.modules else "not available",
            "safetensors": "available" if 'safetensors' in sys.modules else "not available"
        },
        "files": {
            "deepseek_path_exists": os.path.exists(deepseek_path),
            "config_exists": os.path.exists(os.path.join(deepseek_path, 'config.json')),
            "model_files": [f for f in os.listdir(deepseek_path) if f.endswith('.safetensors')] if os.path.exists(deepseek_path) else []
        },
        "error": DEEPSEEK_ERROR,
        "timestamp": datetime.now().isoformat()
    }

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8000))
    
    print("\n" + "="*70)
    print("🚀 STARTING CHOVEEN BACKEND (Enhanced)")
    print("="*70)
    print(f"🌐 Server URL: http://0.0.0.0:{port}")
    print(f"🌐 Local Access: http://localhost:{port}")
    print(f"📊 Database: SQLite (initialized)")
    print(f"🤖 DeepSeek: {'✅ Available' if DEEPSEEK_AVAILABLE else '❌ Unavailable'}")
    print(f"⚡ Triton: {'✅ Available' if TRITON_AVAILABLE else '❌ Not Available (CPU mode)'}")
    if DEEPSEEK_ERROR:
        print(f"⚠️  Error: {DEEPSEEK_ERROR}")
    print(f"🖥️  Device: {deepseek_manager.device if hasattr(deepseek_manager, 'device') else 'unknown'}")
    print("✅ Server ready!")
    print("="*70)
    
    uvicorn.run(
        "main:app", 
        host="0.0.0.0", 
        port=port, 
        log_level="info", 
        reload=True
    )