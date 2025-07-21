import uuid
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.schemas.message import MessageCreate, MessageResponse
from app.models.message import Message
from app.models.user import User
from app.models.chat import Chat
from app.api.auth import get_current_user

router = APIRouter()

@router.get("/")
async def get_chat_list(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get user's chat list"""
    try:
        # Get all chats where user is a participant
        chats = db.query(Chat).filter(
            (Chat.participant_1 == current_user.id) | 
            (Chat.participant_2 == current_user.id)
        ).all()
        
        chat_list = []
        for chat in chats:
            other_user_id = chat.participant_2 if chat.participant_1 == current_user.id else chat.participant_1
            other_user = db.query(User).filter(User.id == other_user_id).first()
            
            chat_list.append({
                "id": chat.id,
                "name": other_user.name if other_user else "Unknown User",
                "last_message": chat.last_message,
                "unread_count": 0  # TODO: Implement unread count
            })
        
        return {"data": chat_list}
    except Exception as e:
        return {"data": []}

@router.get("/{chat_id}/messages")
async def get_messages(
    chat_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get messages for a chat"""
    try:
        # For AI chats, filter by project_id
        if chat_id.startswith("ai_"):
            project_id = chat_id.replace("ai_", "")
            messages = db.query(Message).filter(
                Message.project_id == project_id
            ).order_by(Message.created_at).all()
        else:
            # For regular chats, filter by chat participants
            messages = db.query(Message).filter(
                ((Message.sender_id == current_user.id) & (Message.receiver_id == chat_id)) |
                ((Message.sender_id == chat_id) & (Message.receiver_id == current_user.id))
            ).order_by(Message.created_at).all()
        
        return {"data": [MessageResponse.from_orm(msg) for msg in messages]}
    except Exception as e:
        return {"data": []}

@router.post("/messages", response_model=MessageResponse)
async def send_message(
    message_data: MessageCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Send a message"""
    try:
        message = Message(
            id=str(uuid.uuid4()),
            sender_id=current_user.id,
            receiver_id=message_data.receiver_id,
            project_id=message_data.project_id,
            content=message_data.content,
            message_type=message_data.message_type
        )
        
        db.add(message)
        db.commit()
        db.refresh(message)
        
        return MessageResponse.from_orm(message)
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail="Failed to send message")