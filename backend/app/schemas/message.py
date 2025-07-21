from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class MessageBase(BaseModel):
    content: str
    receiver_id: Optional[str] = None
    project_id: Optional[str] = None
    message_type: str = "user"

class MessageCreate(MessageBase):
    pass

class MessageResponse(MessageBase):
    id: str
    sender_id: str
    created_at: datetime

    class Config:
        from_attributes = True
    
    @classmethod
    def from_orm(cls, obj):
        return cls(
            id=obj.id,
            sender_id=obj.sender_id,
            receiver_id=obj.receiver_id,
            project_id=obj.project_id,
            content=obj.content,
            message_type=obj.message_type,
            created_at=obj.created_at
        )