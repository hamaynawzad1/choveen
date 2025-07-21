import uuid
from sqlalchemy import Column, String, ForeignKey, Text
from sqlalchemy.orm import relationship
from .base import BaseModel

class Message(BaseModel):
    __tablename__ = "messages"

    sender_id = Column(String(36), ForeignKey("users.id"), nullable=False)
    receiver_id = Column(String(36), ForeignKey("users.id"), nullable=True)
    project_id = Column(String(36), ForeignKey("projects.id"), nullable=True)
    content = Column(Text, nullable=False)
    message_type = Column(String(20), default="user")  # user, ai

    # Relationships
    sender = relationship("User", back_populates="sent_messages", foreign_keys=[sender_id])
    project = relationship("Project", back_populates="messages")
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        if not self.id:
            self.id = str(uuid.uuid4())