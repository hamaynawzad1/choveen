import os
from dotenv import load_dotenv

load_dotenv()

class Settings:
    DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://user:password@localhost/choveen")
    SECRET_KEY = os.getenv("SECRET_KEY", "AIzaSyAoKbeNrRdUQkLs0b7ZP-IbUyar53i2PcQ")
    ALGORITHM = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES = 30
    
    # Email settings
    SMTP_SERVER = os.getenv("SMTP_SERVER", "smtp.gmail.com")
    SMTP_PORT = int(os.getenv("SMTP_PORT", "587"))
    SMTP_USERNAME = os.getenv("SMTP_USERNAME", "")
    SMTP_PASSWORD = os.getenv("SMTP_PASSWORD", "")
    
    GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "AIzaSyAoKbeNrRdUQkLs0b7ZP-IbUyar53i2PcQ")
    
settings = Settings()