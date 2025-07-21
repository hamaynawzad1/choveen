import uuid
import random
import json
from sqlalchemy.orm import Session
from app.models.user import User
from app.schemas.user import UserCreate
from app.core.security import get_password_hash, verify_password
from app.services.email_service import send_verification_email

class AuthService:
    def __init__(self, db: Session):
        self.db = db

    def create_user(self, user_data: UserCreate) -> User:
        # Check if user already exists
        existing_user = self.db.query(User).filter(User.email == user_data.email).first()
        if existing_user:
            raise ValueError("User with this email already exists")

        # Generate verification code
        verification_code = str(random.randint(100000, 999999))

        # Create user
        user = User(
            name=user_data.name,
            email=user_data.email,
            hashed_password=get_password_hash(user_data.password),
            profile_image=user_data.profile_image,
            skills=json.dumps(user_data.skills),  # Convert to JSON string
            verification_code=verification_code
        )

        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)

        # Send verification email
        send_verification_email(user.email, verification_code)

        return user

    def authenticate_user(self, email: str, password: str) -> User:
        user = self.db.query(User).filter(User.email == email).first()
        if not user or not verify_password(password, user.hashed_password):
            return None
        return user

    def verify_email(self, email: str, code: str) -> User:
        user = self.db.query(User).filter(User.email == email).first()
        if not user or user.verification_code != code:
            raise ValueError("Invalid verification code")

        user.is_verified = True
        user.verification_code = None
        self.db.commit()
        self.db.refresh(user)

        return user