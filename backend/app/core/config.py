import os
from dotenv import load_dotenv

load_dotenv()

class Settings:
    # Use SQLite for Windows (much easier)
    DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./choveen.db")
    
    SECRET_KEY = os.getenv("SECRET_KEY", "choveen-secret-key-change-in-production")
    ALGORITHM = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES = 30
    
    # Email settings (optional)
    SMTP_SERVER = os.getenv("SMTP_SERVER", "smtp.gmail.com")
    SMTP_PORT = int(os.getenv("SMTP_PORT", "587"))
    SMTP_USERNAME = os.getenv("SMTP_USERNAME", "")
    SMTP_PASSWORD = os.getenv("SMTP_PASSWORD", "")
    
    # DeepSeek settings
    DEEPSEEK_MODEL_PATH = os.getenv("DEEPSEEK_MODEL_PATH", "./deepseek")
    DEEPSEEK_CONFIG_PATH = os.getenv("DEEPSEEK_CONFIG_PATH", "./deepseek/config.json")
    
    # AI Service settings
    AI_SERVICE_TYPE = os.getenv("AI_SERVICE_TYPE", "fallback")  # "deepseek" or "fallback"
    
settings = Settings()