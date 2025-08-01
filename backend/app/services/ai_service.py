import json
import time
import random
from typing import List, Dict, Any, Optional
from datetime import datetime, timedelta
from sqlalchemy.orm import Session
from ..models.user import User
from ..models.message import Message
from ..models.project import Project
from ..models.user_preferences import UserPreferences 

class EnhancedAIService:
    def __init__(self, db: Session):
        self.db = db
        self.user_contexts = {}  
        
    def generate_personalized_response(
        self, 
        user_id: str,
        message: str, 
        project_id: str,
        conversation_history: List[Dict] = None
    ) -> str:
        """Generate dynamic, user-specific AI responses"""
        
        # Get user context
        user_context = self._get_user_context(user_id)
        
        # Analyze message intent
        intent = self._analyze_message_intent(message)
        
        # Get project context
        project_context = self._get_project_context(project_id)
        
        # Generate personalized response
        response = self._generate_contextual_response(
            user_context=user_context,
            message=message,
            intent=intent,
            project_context=project_context,
            conversation_history=conversation_history or []
        )
        
        # Save interaction for learning
        self._save_user_interaction(user_id, message, response, intent)
        
        return response
    
    def _get_user_context(self, user_id: str) -> Dict[str, Any]:
        """Get comprehensive user context"""
        
        # Check cache first
        if user_id in self.user_contexts:
            cached_context = self.user_contexts[user_id]
            if cached_context['last_updated'] > datetime.now() - timedelta(minutes=30):
                return cached_context
        
        # Build fresh context
        user = self.db.query(User).filter(User.id == user_id).first()
        if not user:
            return self._get_default_context()
        
        # Get user preferences (new table)
        preferences = self.db.query(UserPreferences).filter(
            UserPreferences.user_id == user_id
        ).first()
        
        # Get recent messages for behavior analysis
        recent_messages = self.db.query(Message).filter(
            Message.sender_id == user_id
        ).order_by(Message.created_at.desc()).limit(50).all()
        
        # Get projects user is involved in
        user_projects = self.db.query(Project).filter(
            Project.created_by == user_id
        ).all()
        
        # Analyze user behavior patterns
        behavior_patterns = self._analyze_user_behavior(recent_messages)
        
        context = {
            'user_id': user_id,
            'name': user.name,
            'skills': user.skills_list or [],
            'experience_level': self._calculate_experience_level(user, recent_messages),
            'preferences': preferences.to_dict() if preferences else {},
            'communication_style': behavior_patterns['communication_style'],
            'preferred_topics': behavior_patterns['preferred_topics'],
            'project_types': behavior_patterns['project_types'],
            'active_projects': len(user_projects),
            'last_active': user.last_login,
            'total_messages': len(recent_messages),
            'personality_traits': self._extract_personality_traits(recent_messages),
            'current_challenges': self._identify_current_challenges(recent_messages),
            'last_updated': datetime.now()
        }
        
        # Cache context
        self.user_contexts[user_id] = context
        
        return context
    
    def _analyze_user_behavior(self, messages: List[Message]) -> Dict[str, Any]:
        """Analyze user behavior from message history"""
        
        if not messages:
            return {
                'communication_style': 'neutral',
                'preferred_topics': [],
                'project_types': [],
                'help_seeking_pattern': 'independent'
            }
        
        message_contents = [msg.content.lower() for msg in messages]
        all_text = ' '.join(message_contents)
        
        # Analyze communication style
        question_ratio = sum(1 for msg in message_contents if '?' in msg) / len(messages)
        urgent_words = ['urgent', 'asap', 'quickly', 'fast', 'help']
        urgency_ratio = sum(1 for msg in message_contents 
                          if any(word in msg for word in urgent_words)) / len(messages)
        
        if question_ratio > 0.4:
            communication_style = 'inquisitive'
        elif urgency_ratio > 0.3:
            communication_style = 'direct'
        else:
            communication_style = 'collaborative'
        
        # Extract preferred topics
        topic_keywords = {
            'frontend': ['ui', 'ux', 'design', 'frontend', 'css', 'html', 'react'],
            'backend': ['api', 'database', 'server', 'backend', 'python', 'node'],
            'mobile': ['mobile', 'app', 'android', 'ios', 'flutter', 'react native'],
            'data': ['data', 'analytics', 'ml', 'ai', 'machine learning'],
            'devops': ['deploy', 'docker', 'aws', 'cloud', 'devops']
        }
        
        preferred_topics = []
        for topic, keywords in topic_keywords.items():
            if any(keyword in all_text for keyword in keywords):
                preferred_topics.append(topic)
        
        return {
            'communication_style': communication_style,
            'preferred_topics': preferred_topics,
            'project_types': self._extract_project_types(message_contents),
            'help_seeking_pattern': 'collaborative' if question_ratio > 0.3 else 'independent'
        }
    
    def _generate_contextual_response(
        self,
        user_context: Dict[str, Any],
        message: str,
        intent: str,
        project_context: Dict[str, Any],
        conversation_history: List[Dict]
    ) -> str:
        """Generate personalized response based on full context"""
        
        # Personalize greeting based on user
        greeting = self._get_personalized_greeting(user_context)
        
        # Adjust response style based on communication preference
        if user_context['communication_style'] == 'direct':
            response_style = 'concise'
        elif user_context['communication_style'] == 'inquisitive':
            response_style = 'detailed'
        else:
            response_style = 'balanced'
        
        # Generate base response based on intent
        if intent == 'technical_help':
            base_response = self._generate_technical_help(
                message, user_context['skills'], user_context['experience_level']
            )
        elif intent == 'project_planning':
            base_response = self._generate_project_planning_help(
                message, user_context['preferred_topics'], project_context
            )
        elif intent == 'learning':
            base_response = self._generate_learning_guidance(
                message, user_context['skills'], user_context['experience_level']
            )
        else:
            base_response = self._generate_general_help(message, user_context)
        
        # Personalize response with user context
        personalized_response = self._personalize_response(
            base_response, user_context, response_style
        )
        
        # Add relevant suggestions based on user history
        suggestions = self._get_contextual_suggestions(user_context, intent)
        
        if suggestions:
            personalized_response += f"\n\n💡 **Based on your interests in {', '.join(user_context['preferred_topics'])}:**\n"
            personalized_response += '\n'.join([f"• {suggestion}" for suggestion in suggestions])
        
        return personalized_response
    
    def generate_dynamic_suggestions(
        self, 
        user_id: str, 
        force_refresh: bool = False
    ) -> List[Dict[str, Any]]:
        """Generate truly dynamic, personalized project suggestions"""
        
        user_context = self._get_user_context(user_id)
        
        # Check if we should use cached suggestions
        if not force_refresh:
            cached_suggestions = self._get_cached_suggestions(user_id)
            if cached_suggestions and len(cached_suggestions) > 0:
                return cached_suggestions
        
        # Generate new personalized suggestions
        suggestions = []
        
        # Base suggestions on user's actual interests and behavior
        base_templates = self._get_personalized_templates(user_context)
        
        for i, template in enumerate(base_templates[:3]):  # Top 3 suggestions
            
            # Customize based on user context
            customized_project = self._customize_project_for_user(
                template, user_context, i
            )
            
            suggestion = {
                "id": f"personalized_{user_id}_{int(time.time())}_{i}",
                "type": "project",
                "project": customized_project,
                "personalization_score": self._calculate_personalization_score(
                    customized_project, user_context
                ),
                "reason": self._explain_suggestion_reason(customized_project, user_context),
                "estimated_interest": self._predict_user_interest(customized_project, user_context)
            }
            
            suggestions.append(suggestion)
        
        # Cache suggestions
        self._cache_suggestions(user_id, suggestions)
        
        return suggestions
    
    def _get_personalized_templates(self, user_context: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Get project templates tailored to user's interests and skills"""
        
        templates = []
        skills = user_context['skills']
        preferred_topics = user_context['preferred_topics']
        experience_level = user_context['experience_level']
        
        # Web Development Projects
        if any(skill in ['html', 'css', 'javascript', 'react', 'vue'] for skill in skills):
            if 'frontend' in preferred_topics:
                templates.append({
                    'category': 'web_frontend',
                    'base_title': f"Interactive {user_context['name']}'s Portfolio",
                    'description_template': 'Modern, responsive portfolio showcasing your frontend skills',
                    'skills_focus': ['HTML5', 'CSS3', 'JavaScript', 'React'],
                    'difficulty': experience_level,
                    'estimated_duration': '2-3 weeks'
                })
        
        # Mobile Development Projects  
        if any(skill in ['flutter', 'react native', 'android', 'ios'] for skill in skills):
            templates.append({
                'category': 'mobile',
                'base_title': 'Smart Task Management App',
                'description_template': 'Cross-platform mobile app with offline sync',
                'skills_focus': ['Flutter', 'Firebase', 'SQLite'],
                'difficulty': experience_level,
                'estimated_duration': '4-6 weeks'
            })
        
        # Data Science Projects
        if any(skill in ['python', 'data analysis', 'ml', 'ai'] for skill in skills):
            if 'data' in preferred_topics:
                templates.append({
                    'category': 'data_science',
                    'base_title': 'Predictive Analytics Dashboard',
                    'description_template': 'Build ML models and interactive visualizations',
                    'skills_focus': ['Python', 'Pandas', 'Scikit-learn', 'Plotly'],
                    'difficulty': experience_level,
                    'estimated_duration': '3-5 weeks'
                })
        
        # Backend Projects
        if any(skill in ['python', 'node', 'api', 'database'] for skill in skills):
            if 'backend' in preferred_topics:
                templates.append({
                    'category': 'backend',
                    'base_title': 'Scalable API Service',
                    'description_template': 'RESTful API with authentication and real-time features',
                    'skills_focus': ['Python/FastAPI', 'PostgreSQL', 'Redis', 'WebSockets'],
                    'difficulty': experience_level,
                    'estimated_duration': '3-4 weeks'
                })
        
        # If no specific templates match, provide general ones
        if not templates:
            templates = self._get_general_templates(user_context)
        
        return templates
    
    def _save_user_interaction(
        self, 
        user_id: str, 
        message: str, 
        response: str, 
        intent: str
    ):
        """Save user interaction for learning and personalization"""
        
        try:
            # Update user preferences based on interaction
            preferences = self.db.query(UserPreferences).filter(
                UserPreferences.user_id == user_id
            ).first()
            
            if not preferences:
                preferences = UserPreferences(user_id=user_id)
                self.db.add(preferences)
            
            # Update interaction count for intent
            if hasattr(preferences, f'{intent}_count'):
                current_count = getattr(preferences, f'{intent}_count', 0)
                setattr(preferences, f'{intent}_count', current_count + 1)
            
            # Update last interaction
            preferences.last_interaction = datetime.utcnow()
            
            self.db.commit()
            
        except Exception as e:
            print(f"❌ Error saving user interaction: {e}")
            self.db.rollback()


# New database model for user preferences
class UserPreferences:
    """Store user preferences and behavioral data"""
    
    def __init__(self, user_id: str):
        self.user_id = user_id
        self.technical_help_count = 0
        self.project_planning_count = 0
        self.learning_count = 0
        self.preferred_response_style = 'balanced'
        self.favorite_topics = []
        self.last_interaction = datetime.utcnow()
        self.created_at = datetime.utcnow()
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            'technical_help_count': self.technical_help_count,
            'project_planning_count': self.project_planning_count,
            'learning_count': self.learning_count,
            'preferred_response_style': self.preferred_response_style,
            'favorite_topics': self.favorite_topics,
            'last_interaction': self.last_interaction
        }