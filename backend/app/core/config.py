# app/core/config.py - Updated for Local DeepSeek Integration
import os
from dotenv import load_dotenv

load_dotenv()

class Settings:
    """Application settings with local DeepSeek configuration"""
    
    # Database Configuration
    DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./choveen.db")
    
    # Security Settings
    SECRET_KEY = os.getenv("SECRET_KEY", "choveen-secret-key-change-in-production")
    ALGORITHM = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES = 30
    
    # Email Settings (Optional)
    SMTP_SERVER = os.getenv("SMTP_SERVER", "smtp.gmail.com")
    SMTP_PORT = int(os.getenv("SMTP_PORT", "587"))
    SMTP_USERNAME = os.getenv("SMTP_USERNAME", "")
    SMTP_PASSWORD = os.getenv("SMTP_PASSWORD", "")
    
    # ✅ Local DeepSeek Configuration
    # Path to your DeepSeek model directory
    DEEPSEEK_MODEL_PATH = os.getenv("DEEPSEEK_MODEL_PATH", "./deepseek")
    
    # Path to DeepSeek config.json file
    DEEPSEEK_CONFIG_PATH = os.getenv("DEEPSEEK_CONFIG_PATH", "./deepseek/config.json")
    
    # DeepSeek Generation Settings
    DEEPSEEK_MAX_TOKENS = int(os.getenv("DEEPSEEK_MAX_TOKENS", "200"))
    DEEPSEEK_TEMPERATURE = float(os.getenv("DEEPSEEK_TEMPERATURE", "0.7"))
    
    # GPU/CPU Settings
    DEEPSEEK_DEVICE = os.getenv("DEEPSEEK_DEVICE", "auto")  # "auto", "cuda", "cpu"
    DEEPSEEK_DTYPE = os.getenv("DEEPSEEK_DTYPE", "bfloat16")  # "bfloat16", "float16", "float32"
    
    # AI Service Type - Now uses local DeepSeek
    AI_SERVICE_TYPE = os.getenv("AI_SERVICE_TYPE", "local_deepseek")  # "local_deepseek" or "fallback"
    
    # Performance Settings
    TORCH_NUM_THREADS = int(os.getenv("TORCH_NUM_THREADS", "8"))
    CUDA_DEVICE = int(os.getenv("CUDA_DEVICE", "0"))
    
    # Model Loading Settings
    DEEPSEEK_LAZY_LOADING = os.getenv("DEEPSEEK_LAZY_LOADING", "true").lower() == "true"
    DEEPSEEK_CACHE_SIZE = int(os.getenv("DEEPSEEK_CACHE_SIZE", "1000"))  # Number of cached responses
    
    # Fallback Settings
    ENABLE_FALLBACK = os.getenv("ENABLE_FALLBACK", "true").lower() == "true"
    
    # Development Settings
    DEBUG = os.getenv("DEBUG", "false").lower() == "true"
    LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")
    
    @property
    def deepseek_available(self) -> bool:
        """Check if DeepSeek model files are available"""
        return (
            os.path.exists(self.DEEPSEEK_MODEL_PATH) and 
            os.path.exists(self.DEEPSEEK_CONFIG_PATH)
        )
    
    def get_model_info(self) -> dict:
        """Get model configuration info"""
        return {
            "model_path": self.DEEPSEEK_MODEL_PATH,
            "config_path": self.DEEPSEEK_CONFIG_PATH,
            "available": self.deepseek_available,
            "service_type": self.AI_SERVICE_TYPE,
            "max_tokens": self.DEEPSEEK_MAX_TOKENS,
            "temperature": self.DEEPSEEK_TEMPERATURE,
            "device": self.DEEPSEEK_DEVICE,
            "dtype": self.DEEPSEEK_DTYPE
        }

settings = Settings()

# Logging configuration
import logging

logging.basicConfig(
    level=getattr(logging, settings.LOG_LEVEL),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

# Print model info on startup
if settings.DEBUG:
    model_info = settings.get_model_info()
    print("\n" + "="*50)
    print("🤖 DEEPSEEK MODEL CONFIGURATION")
    print("="*50)
    for key, value in model_info.items():
        print(f"   {key.upper()}: {value}")
    print("="*50 + "\n")