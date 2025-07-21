import uuid
from sqlalchemy import Column, String, ForeignKey, Boolean, Text
from .base import BaseModel

class Chat(BaseModel):
    __tablename__ = "chats"

    participant_1 = Column(String(36), ForeignKey("users.id"), nullable=False)
    participant_2 = Column(String(36), ForeignKey("users.id"), nullable=False)
    last_message = Column(Text, nullable=True)
    is_active = Column(Boolean, default=True)
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        if not self.id:
            self.id = str(uuid.uuid4())