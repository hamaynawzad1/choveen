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

        formatted_messages = []
        for msg in messages:
            formatted_messages.append({
                "id": msg.id,
                "sender_id": msg.sender_id,
                "receiver_id": msg.receiver_id,
                "project_id": msg.project_id,
                "content": msg.content,
                "message_type": msg.message_type,
                "created_at": msg.created_at.isoformat(),
                "is_ai": msg.sender_id == "ai_assistant"
            })

        return {"messages": formatted_messages}
    except Exception as e:
        print(f"Error fetching messages: {e}")
        return {"messages": []}

@router.post("/{chat_id}/messages")
async def send_message(
    chat_id: str,
    message_data: MessageCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Send a message to a chat"""
    try:
        # Create message
        message = Message(
            id=str(uuid.uuid4()),
            sender_id=current_user.id,
            receiver_id=chat_id if not chat_id.startswith("ai_") else None,
            project_id=chat_id.replace("ai_", "") if chat_id.startswith("ai_") else None,
            content=message_data.content,
            message_type="user"
        )
        
        db.add(message)
        db.commit()
        db.refresh(message)
        
        # Update chat last message
        if not chat_id.startswith("ai_"):
            chat = db.query(Chat).filter(
                ((Chat.participant_1 == current_user.id) & (Chat.participant_2 == chat_id)) |
                ((Chat.participant_1 == chat_id) & (Chat.participant_2 == current_user.id))
            ).first()
            
            if chat:
                chat.last_message = message_data.content[:100]
            else:
                # Create new chat
                new_chat = Chat(
                    id=str(uuid.uuid4()),
                    participant_1=current_user.id,
                    participant_2=chat_id,
                    last_message=message_data.content[:100]
                )
                db.add(new_chat)
            
            db.commit()

        return {
            "id": message.id,
            "sender_id": message.sender_id,
            "receiver_id": message.receiver_id,
            "project_id": message.project_id,
            "content": message.content,
            "message_type": message.message_type,
            "created_at": message.created_at.isoformat()
        }
        
    except Exception as e:
        print(f"Error sending message: {e}")
        db.rollback()
        raise HTTPException(status_code=500, detail="Failed to send message")

@router.delete("/{chat_id}/messages")
async def clear_messages(
    chat_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Clear all messages in a chat"""
    try:
        if chat_id.startswith("ai_"):
            project_id = chat_id.replace("ai_", "")
            db.query(Message).filter(Message.project_id == project_id).delete()
        else:
            db.query(Message).filter(
                ((Message.sender_id == current_user.id) & (Message.receiver_id == chat_id)) |
                ((Message.sender_id == chat_id) & (Message.receiver_id == current_user.id))
            ).delete()
        
        db.commit()
        return {"message": "Messages cleared successfully"}
        
    except Exception as e:
        print(f"Error clearing messages: {e}")
        db.rollback()
        raise HTTPException(status_code=500, detail="Failed to clear messages")

@router.get("/{chat_id}/info")
async def get_chat_info(
    chat_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get chat information"""
    try:
        if chat_id.startswith("ai_"):
            project_id = chat_id.replace("ai_", "")
            message_count = db.query(Message).filter(Message.project_id == project_id).count()
            
            return {
                "chat_id": chat_id,
                "type": "ai_chat",
                "project_id": project_id,
                "message_count": message_count,
                "participants": ["user", "ai_assistant"]
            }
        else:
            chat = db.query(Chat).filter(
                ((Chat.participant_1 == current_user.id) & (Chat.participant_2 == chat_id)) |
                ((Chat.participant_1 == chat_id) & (Chat.participant_2 == current_user.id))
            ).first()
            
            if not chat:
                raise HTTPException(status_code=404, detail="Chat not found")
            
            message_count = db.query(Message).filter(
                ((Message.sender_id == current_user.id) & (Message.receiver_id == chat_id)) |
                ((Message.sender_id == chat_id) & (Message.receiver_id == current_user.id))
            ).count()
            
            return {
                "chat_id": chat.id,
                "type": "user_chat",
                "message_count": message_count,
                "participants": [chat.participant_1, chat.participant_2],
                "created_at": chat.created_at.isoformat()
            }
            
    except HTTPException:
        raise
    except Exception as e:
        print(f"Error getting chat info: {e}")
        raise HTTPException(status_code=500, detail="Failed to get chat info")