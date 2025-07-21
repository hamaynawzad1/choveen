from app.core.database import engine
from app.models import user, project, message, chat
from app.models import Base

def create_tables():
    try:
        # Import all models to register them with Base
        from app.models.user import User
        from app.models.project import Project
        from app.models.message import Message
        from app.models.chat import Chat
        
        # Create all tables
        Base.metadata.create_all(bind=engine)
        print("✅ Database tables created successfully!")
        
    except Exception as e:
        print(f"❌ Error creating tables: {e}")

if __name__ == "__main__":
    create_tables()