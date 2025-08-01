from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os

# Simple SQLite setup - no config import needed
DATABASE_URL = "sqlite:///./choveen.db"

# Create database directory if needed
os.makedirs(os.path.dirname(os.path.abspath("./choveen.db")), exist_ok=True)

# SQLite engine
engine = create_engine(
    DATABASE_URL,
    connect_args={"check_same_thread": False},  # SQLite specific
    echo=False
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def create_tables():
    """Create all tables"""
    try:
        Base.metadata.create_all(bind=engine)
        print("✅ Database tables created")
        return True
    except Exception as e:
        print(f"❌ Database error: {e}")
        return False