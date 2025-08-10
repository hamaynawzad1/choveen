# app/services/local_deepseek_service.py - Local DeepSeek Integration
import os
import json
import torch
import logging
from typing import List, Dict, Optional, Any
from datetime import datetime
from dataclasses import dataclass
import asyncio
from concurrent.futures import ThreadPoolExecutor
import threading

# Import DeepSeek components
try:
    from transformers import AutoTokenizer
    from deepseek.generate import generate, ModelArgs, Transformer
    DEEPSEEK_AVAILABLE = True
except ImportError as e:
    print(f"DeepSeek dependencies not available: {e}")
    DEEPSEEK_AVAILABLE = False

logger = logging.getLogger(__name__)

@dataclass
class ChatMessage:
    role: str  # 'user' or 'assistant'
    content: str
    timestamp: Optional[str] = None
    project_id: Optional[str] = None

class LocalDeepSeekService:
    """Local DeepSeek AI Service using local model files"""
    
    def __init__(self):
        self.model = None
        self.tokenizer = None
        self.is_initialized = False
        self.is_loading = False
        self.model_lock = threading.Lock()
        self.executor = ThreadPoolExecutor(max_workers=1, thread_name_prefix="deepseek")
        
        # Configuration from environment
        self.model_path = os.getenv("DEEPSEEK_MODEL_PATH", "./deepseek")
        self.config_path = os.getenv("DEEPSEEK_CONFIG_PATH", "./deepseek/config.json")
        self.max_tokens = int(os.getenv("DEEPSEEK_MAX_TOKENS", "200"))
        self.temperature = float(os.getenv("DEEPSEEK_TEMPERATURE", "0.7"))
        
        # Initialize model in background
        if DEEPSEEK_AVAILABLE and os.path.exists(self.model_path):
            self._initialize_model()
    
    def _initialize_model(self):
        """Initialize DeepSeek model"""
        if self.is_loading or self.is_initialized:
            return
            
        self.is_loading = True
        try:
            logger.info("Initializing local DeepSeek model...")
            
            # Check if model files exist
            if not os.path.exists(self.config_path):
                logger.error(f"Config file not found: {self.config_path}")
                return
            
            # Load configuration
            with open(self.config_path, 'r') as f:
                config_dict = json.load(f)
            
            # Setup model arguments
            model_args = ModelArgs(**config_dict)
            
            # Set device and dtype
            torch.cuda.set_device(0 if torch.cuda.is_available() else "cpu")
            torch.set_default_dtype(torch.bfloat16)
            torch.set_num_threads(8)
            torch.manual_seed(965)
            
            # Initialize model
            device = "cuda" if torch.cuda.is_available() else "cpu"
            with torch.device(device):
                self.model = Transformer(model_args)
            
            # Load tokenizer
            self.tokenizer = AutoTokenizer.from_pretrained(self.model_path)
            
            self.is_initialized = True
            logger.info("✅ Local DeepSeek model initialized successfully!")
            
        except Exception as e:
            logger.error(f"❌ Failed to initialize DeepSeek model: {e}")
            self.is_initialized = False
        finally:
            self.is_loading = False
    
    async def generate_response(
        self,
        message: str,
        project_title: str = "Current Project",
        project_context: str = "",
        conversation_history: List[ChatMessage] = None,
        max_tokens: int = None,
        temperature: float = None
    ) -> str:
        """Generate AI response using local DeepSeek model"""
        
        if not self.is_initialized:
            return self._generate_fallback_response(message, project_title, project_context)
        
        try:
            # Prepare parameters
            max_tokens = max_tokens or self.max_tokens
            temperature = temperature or self.temperature
            
            # Build prompt with context
            prompt = self._build_prompt(message, project_title, project_context, conversation_history)
            
            # Generate response in thread pool to avoid blocking
            loop = asyncio.get_event_loop()
            response = await loop.run_in_executor(
                self.executor, 
                self._generate_sync, 
                prompt, 
                max_tokens, 
                temperature
            )
            
            return self._format_response(response)
            
        except Exception as e:
            logger.error(f"DeepSeek generation error: {e}")
            return self._generate_fallback_response(message, project_title, project_context)
    
    def _generate_sync(self, prompt: str, max_tokens: int, temperature: float) -> str:
        """Synchronous generation method for thread execution"""
        with self.model_lock:
            try:
                # Tokenize input
                input_ids = self.tokenizer.encode(prompt)
                input_tensor = torch.tensor([input_ids])
                
                # Generate response
                with torch.no_grad():
                    output_ids = generate(
                        self.model, 
                        input_tensor, 
                        max_tokens, 
                        temperature
                    )
                
                # Decode response
                response = self.tokenizer.decode(output_ids[0], skip_special_tokens=True)
                
                # Remove input prompt from response
                if response.startswith(prompt):
                    response = response[len(prompt):].strip()
                
                return response
                
            except Exception as e:
                logger.error(f"Sync generation error: {e}")
                raise
    
    def _build_prompt(
        self, 
        message: str, 
        project_title: str, 
        project_context: str,
        conversation_history: List[ChatMessage]
    ) -> str:
        """Build conversation prompt for DeepSeek"""
        
        # System instruction
        system_prompt = f"""You are an intelligent AI assistant helping with the project "{project_title}".

Project Context: {project_context if project_context else 'Software development project'}

Your role:
- Provide practical, actionable advice
- Help with planning, technical decisions, and problem-solving
- Give specific solutions based on project context
- Be concise and professional
- Focus on software development best practices

"""
        
        # Add conversation history
        conversation = ""
        if conversation_history:
            for msg in conversation_history[-5:]:  # Last 5 messages
                role = "Human" if msg.role == "user" else "Assistant"
                conversation += f"{role}: {msg.content}\n"
        
        # Build final prompt
        prompt = f"{system_prompt}{conversation}Human: {message}\nAssistant:"
        
        return prompt
    
    def _format_response(self, response: str) -> str:
        """Format and clean the response"""
        if not response:
            return "I'm here to help with your project. Could you please rephrase your question?"
        
        # Clean the response
        response = response.strip()
        
        # Remove any "Assistant:" prefix if present
        if response.startswith("Assistant:"):
            response = response[10:].strip()
        
        # Limit response length
        if len(response) > 800:
            sentences = response.split('. ')
            truncated = []
            length = 0
            
            for sentence in sentences:
                if length + len(sentence) > 750:
                    break
                truncated.append(sentence)
                length += len(sentence) + 2
            
            response = '. '.join(truncated)
            if not response.endswith('.'):
                response += '.'
        
        return response
    
    def _generate_fallback_response(
        self, 
        message: str, 
        project_title: str, 
        project_context: str
    ) -> str:
        """Generate fallback response when model is not available"""
        
        msg_lower = message.lower().strip()
        
        # Greeting responses
        if any(word in msg_lower for word in ['hi', 'hello', 'hey', 'start']):
            return f"""👋 **Welcome to {project_title}!**

I'm your AI project assistant. I can help with:
• Project planning and task breakdown
• Technical guidance and best practices
• Problem-solving and debugging
• Code review and optimization

How can I assist you today?"""

        # Planning responses
        if any(word in msg_lower for word in ['plan', 'planning', 'strategy']):
            return f"""📋 **Project Planning for {project_title}**

Let's structure your approach:

**Phase 1: Setup & Planning**
• Define requirements and scope
• Choose technology stack
• Set up development environment

**Phase 2: Core Development**
• Implement main features
• Regular testing and reviews
• Iterative development

**Phase 3: Testing & Deployment**
• Comprehensive testing
• Performance optimization
• Production deployment

Which area would you like to focus on?"""

        # Technical help
        if any(word in msg_lower for word in ['error', 'bug', 'issue', 'problem']):
            return f"""🔧 **Technical Debugging for {project_title}**

**Systematic Approach:**
• Check logs and error messages
• Identify recent changes
• Test with minimal examples
• Use debugging tools

**Common Solutions:**
• Verify configurations and dependencies
• Check data formats and API calls
• Review recent code changes
• Test in isolated environment

Can you share more details about the specific issue?"""

        # Default response
        return f"""🤖 **AI Assistant for {project_title}**

I understand you're asking about: "{message}"

**I can help with:**
• Project planning and organization
• Technical implementation guidance
• Problem-solving strategies
• Best practices and recommendations

**Project Context:** {project_context if project_context else 'Ready to assist with your development needs'}

What specific aspect would you like to explore?"""

# Enhanced AI Service with Local DeepSeek Integration
class EnhancedLocalAIService:
    """Enhanced AI Service that prioritizes local DeepSeek"""
    
    def __init__(self):
        self.local_deepseek = LocalDeepSeekService()
        self.fallback_mode = not self.local_deepseek.is_initialized
        
    async def generate_smart_response(
        self,
        message: str,
        project_title: str = "Current Project",
        project_context: str = "",
        conversation_history: List[ChatMessage] = None,
        max_tokens: int = 200,
        temperature: float = 0.7
    ) -> str:
        """Generate intelligent response using local DeepSeek or fallback"""
        
        if self.local_deepseek.is_initialized:
            return await self.local_deepseek.generate_response(
                message, project_title, project_context, 
                conversation_history, max_tokens, temperature
            )
        else:
            return self.local_deepseek._generate_fallback_response(
                message, project_title, project_context
            )
    
    @property
    def is_initialized(self) -> bool:
        """Check if the service is properly initialized"""
        return self.local_deepseek.is_initialized or True  # Always return True as fallback works

# Global service instance
_local_ai_service_instance = None

def get_local_ai_service() -> EnhancedLocalAIService:
    """Get the local AI service instance"""
    global _local_ai_service_instance
    if _local_ai_service_instance is None:
        _local_ai_service_instance = EnhancedLocalAIService()
    return _local_ai_service_instance