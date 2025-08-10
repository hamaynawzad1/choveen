# backend/app/services/ai_service.py - Enhanced with Personalization
import json
import time
import random
import hashlib
from typing import List, Dict, Any, Optional
from datetime import datetime, timedelta
from sqlalchemy.orm import Session
from dataclasses import dataclass

@dataclass
class ChatMessage:
    role: str
    content: str
    timestamp: Optional[str] = None
    project_id: Optional[str] = None

class EnhancedAIService:
    def __init__(self, db: Session = None):
        self.db = db
        self.is_initialized = True
        self.fallback_mode = False
        
        # 🎯 User personalization cache
        self.user_profiles = {}
        self.suggestion_cache = {}
        self.interaction_history = {}
        
        print("🤖 Enhanced AI Service initialized with personalization features")

    def generate_smart_response(
        self, 
        message: str, 
        project_title: str = "Current Project",
        project_context: str = "",
        conversation_history: List[ChatMessage] = None,
        max_tokens: int = 200,
        temperature: float = 0.7
    ) -> str:
        """Generate intelligent, context-aware responses"""
        
        try:
            # 🎯 Analyze message intent and context
            intent = self._analyze_message_intent(message)
            project_type = self._detect_project_type(project_title, project_context)
            
            # 🚀 Generate contextual response based on intent
            if intent == "planning":
                return self._generate_planning_response(message, project_title, project_type)
            elif intent == "technical":
                return self._generate_technical_response(message, project_title, project_type)
            elif intent == "collaboration":
                return self._generate_collaboration_response(message, project_title)
            elif intent == "learning":
                return self._generate_learning_response(message, project_type)
            else:
                return self._generate_general_response(message, project_title, project_context)
                
        except Exception as e:
            print(f"❌ AI Response Error: {e}")
            return self._generate_fallback_response(message, project_title)

    def generate_personalized_suggestions(
        self, 
        user_skills: List[str], 
        user_interests: List[str] = None,
        user_id: str = None,
        force_refresh: bool = False
    ) -> List[Dict[str, Any]]:
        """Generate dynamic, personalized project suggestions"""
        
        try:
            # 🎯 Create user profile key for caching
            profile_key = self._create_profile_key(user_skills, user_interests)
            cache_key = f"suggestions_{profile_key}_{user_id}"
            
            # 📊 Check cache first (unless force refresh)
            if not force_refresh and cache_key in self.suggestion_cache:
                cached_data = self.suggestion_cache[cache_key]
                if cached_data['timestamp'] > datetime.now() - timedelta(hours=1):
                    print(f"🔄 Returning cached suggestions for user profile: {profile_key}")
                    return cached_data['suggestions']
            
            print(f"🎯 Generating fresh personalized suggestions")
            print(f"   User Skills: {user_skills}")
            print(f"   User Interests: {user_interests}")
            print(f"   Force Refresh: {force_refresh}")
            
            # 🚀 Generate suggestions based on user profile
            suggestions = []
            
            # 1. Skill-based suggestions
            skill_suggestions = self._generate_skill_based_suggestions(user_skills)
            suggestions.extend(skill_suggestions)
            
            # 2. Progressive difficulty suggestions
            difficulty_suggestions = self._generate_difficulty_based_suggestions(user_skills)
            suggestions.extend(difficulty_suggestions)
            
            # 3. Trending/Popular suggestions with user twist
            trending_suggestions = self._generate_trending_suggestions(user_skills)
            suggestions.extend(trending_suggestions)
            
            # 🎨 Personalize and score suggestions
            personalized_suggestions = []
            for i, suggestion in enumerate(suggestions[:5]):  # Top 5
                personalized_suggestion = self._personalize_suggestion(
                    suggestion, user_skills, user_interests, i
                )
                personalized_suggestions.append(personalized_suggestion)
            
            # 💾 Cache the results
            self.suggestion_cache[cache_key] = {
                'suggestions': personalized_suggestions,
                'timestamp': datetime.now(),
                'user_profile': profile_key
            }
            
            print(f"✅ Generated {len(personalized_suggestions)} personalized suggestions")
            return personalized_suggestions
            
        except Exception as e:
            print(f"❌ Error generating personalized suggestions: {e}")
            return self._generate_fallback_suggestions(user_skills)

    def _generate_skill_based_suggestions(self, user_skills: List[str]) -> List[Dict]:
        """Generate suggestions based on user's specific skills"""
        suggestions = []
        
        # 🎯 Skill-specific project templates
        skill_projects = {
            'python': {
                'title': 'AI-Powered Data Analytics Dashboard',
                'description': 'Build a comprehensive data analytics platform with machine learning insights',
                'skills': ['Python', 'Pandas', 'Scikit-learn', 'Plotly', 'FastAPI'],
                'category': 'Data Science',
                'difficulty': 'Intermediate'
            },
            'javascript': {
                'title': 'Real-time Collaborative Workspace',
                'description': 'Create a modern collaborative platform with real-time editing and communication',
                'skills': ['JavaScript', 'React', 'WebSockets', 'Node.js', 'MongoDB'],
                'category': 'Web Development',
                'difficulty': 'Advanced'
            },
            'flutter': {
                'title': 'Cross-Platform Productivity App',
                'description': 'Develop a beautiful, cross-platform mobile app for task and project management',
                'skills': ['Flutter', 'Dart', 'Firebase', 'SQLite', 'Provider'],
                'category': 'Mobile Development',
                'difficulty': 'Intermediate'
            },
            'react': {
                'title': 'Progressive Web App (PWA)',
                'description': 'Build a modern PWA with offline capabilities and native-like experience',
                'skills': ['React', 'TypeScript', 'Service Workers', 'IndexedDB', 'Material-UI'],
                'category': 'Frontend Development',
                'difficulty': 'Intermediate'
            },
            'machine learning': {
                'title': 'Intelligent Recommendation System',
                'description': 'Create an ML-powered recommendation engine with personalization features',
                'skills': ['Python', 'TensorFlow', 'Pandas', 'Docker', 'API Development'],
                'category': 'Machine Learning',
                'difficulty': 'Advanced'
            }
        }
        
        # 🔍 Match user skills to project templates
        for skill in user_skills[:3]:  # Top 3 skills
            skill_lower = skill.lower()
            for template_skill, project_template in skill_projects.items():
                if template_skill in skill_lower or skill_lower in template_skill:
                    suggestions.append({
                        'base_template': project_template,
                        'match_type': 'skill_based',
                        'primary_skill': skill,
                        'confidence': 0.9
                    })
                    break
        
        return suggestions

    def _generate_difficulty_based_suggestions(self, user_skills: List[str]) -> List[Dict]:
        """Generate suggestions based on user's skill level"""
        skill_count = len(user_skills)
        
        # 📊 Determine user experience level
        if skill_count >= 5:
            experience_level = 'advanced'
        elif skill_count >= 3:
            experience_level = 'intermediate'
        else:
            experience_level = 'beginner'
        
        # 🎯 Level-appropriate project suggestions
        level_projects = {
            'beginner': {
                'title': 'Personal Portfolio Website',
                'description': 'Create a beautiful, responsive portfolio to showcase your growing skills',
                'skills': ['HTML', 'CSS', 'JavaScript', 'Git', 'Responsive Design'],
                'category': 'Web Development',
                'difficulty': 'Beginner'
            },
            'intermediate': {
                'title': 'Full-Stack Web Application',
                'description': 'Build a complete web application with authentication and database integration',
                'skills': ['Frontend Framework', 'Backend API', 'Database', 'Authentication', 'Deployment'],
                'category': 'Full-Stack Development',
                'difficulty': 'Intermediate'
            },
            'advanced': {
                'title': 'Microservices Architecture Project',
                'description': 'Design and implement a scalable microservices system with modern DevOps practices',
                'skills': ['Microservices', 'Docker', 'Kubernetes', 'CI/CD', 'Cloud Deployment'],
                'category': 'Software Architecture',
                'difficulty': 'Advanced'
            }
        }
        
        project = level_projects.get(experience_level, level_projects['intermediate'])
        return [{
            'base_template': project,
            'match_type': 'difficulty_based',
            'experience_level': experience_level,
            'confidence': 0.8
        }]

    def _generate_trending_suggestions(self, user_skills: List[str]) -> List[Dict]:
        """Generate suggestions based on current tech trends"""
        trending_projects = [
            {
                'title': 'AI-Enhanced Creative Tool',
                'description': 'Build a creative application enhanced with AI capabilities for content generation',
                'skills': ['AI Integration', 'Creative APIs', 'User Interface', 'Real-time Processing'],
                'category': 'AI Applications',
                'difficulty': 'Advanced',
                'trend_factor': 'AI Integration'
            },
            {
                'title': 'Sustainable Tech Solution',
                'description': 'Create technology that addresses environmental challenges and promotes sustainability',
                'skills': ['Data Analysis', 'IoT Sensors', 'Environmental APIs', 'Visualization'],
                'category': 'GreenTech',
                'difficulty': 'Intermediate',
                'trend_factor': 'Sustainability'
            },
            {
                'title': 'Web3 Decentralized App',
                'description': 'Explore blockchain technology by building a decentralized application',
                'skills': ['Blockchain', 'Smart Contracts', 'DApp Development', 'Crypto Integration'],
                'category': 'Blockchain',
                'difficulty': 'Advanced',
                'trend_factor': 'Web3'
            }
        ]
        
        # 🎲 Randomly select trending projects
        selected_trending = random.sample(trending_projects, min(2, len(trending_projects)))
        
        return [{
            'base_template': project,
            'match_type': 'trending',
            'trend_factor': project['trend_factor'],
            'confidence': 0.7
        } for project in selected_trending]

    def _personalize_suggestion(
        self, 
        suggestion: Dict, 
        user_skills: List[str], 
        user_interests: List[str], 
        index: int
    ) -> Dict[str, Any]:
        """Personalize a suggestion for the specific user"""
        
        base_template = suggestion['base_template']
        match_type = suggestion['match_type']
        
        # 🎯 Calculate personalized match score
        match_score = self._calculate_match_score(base_template, user_skills, user_interests)
        
        # 🎨 Personalize project details
        personalized_title = self._personalize_title(base_template['title'], user_skills)
        personalized_description = self._personalize_description(
            base_template['description'], user_skills, match_type
        )
        
        # 🔧 Adapt required skills
        adapted_skills = self._adapt_skills_to_user(base_template['skills'], user_skills)
        
        # 📊 Generate unique project ID
        project_hash = hashlib.md5(
            f"{personalized_title}_{str(user_skills)}_{index}".encode()
        ).hexdigest()[:8]
        
        return {
            "id": f"intelligent_{project_hash}",
            "type": "project",
            "project": {
                "id": f"proj_intelligent_{project_hash}",
                "title": personalized_title,
                "description": personalized_description,
                "required_skills": adapted_skills,
                "category": base_template['category'],
                "difficulty": base_template['difficulty'],
                "estimated_duration": self._estimate_duration(base_template['difficulty']),
                "personalization_context": {
                    "match_type": match_type,
                    "primary_user_skills": user_skills[:3],
                    "adapted_for_user": True
                }
            },
            "description": f"Personalized {match_type.replace('_', ' ')} suggestion based on your {', '.join(user_skills[:2])} skills",
            "match_score": match_score,
            "timeline": self._estimate_duration(base_template['difficulty']),
            "difficulty": base_template['difficulty'],
            "personalization_score": match_score,
            "why_recommended": self._generate_recommendation_reason(base_template, user_skills, match_type),
            "ai_generated": True,
            "personalized": True,
            "generated_at": datetime.now().isoformat()
        }

    def _calculate_match_score(self, project: Dict, user_skills: List[str], user_interests: List[str]) -> float:
        """Calculate how well a project matches the user's profile"""
        if not user_skills:
            return 0.5
        
        project_skills = project.get('skills', [])
        if not project_skills:
            return 0.5
        
        # 🎯 Calculate skill overlap
        skill_matches = 0
        for user_skill in user_skills:
            for project_skill in project_skills:
                if (user_skill.lower() in project_skill.lower() or 
                    project_skill.lower() in user_skill.lower()):
                    skill_matches += 1
                    break
        
        skill_match_ratio = skill_matches / len(user_skills)
        
        # 🚀 Boost score based on project category alignment
        category_boost = 0.0
        if user_interests:
            for interest in user_interests:
                if interest.lower() in project['category'].lower():
                    category_boost = 0.2
                    break
        
        # 📊 Calculate final score
        base_score = 0.6 + (skill_match_ratio * 0.3) + category_boost
        
        # 🎲 Add slight randomization for variety
        randomization = random.uniform(-0.05, 0.05)
        
        return max(0.1, min(1.0, base_score + randomization))

    def _personalize_title(self, base_title: str, user_skills: List[str]) -> str:
        """Personalize project title based on user skills"""
        if not user_skills:
            return base_title
        
        primary_skill = user_skills[0]
        
        # 🎯 Skill-specific title modifications
        skill_modifiers = {
            'python': 'Python-Powered',
            'javascript': 'Modern JavaScript',
            'react': 'React-Based',
            'flutter': 'Flutter',
            'machine learning': 'AI-Enhanced',
            'data science': 'Data-Driven',
            'web development': 'Full-Stack',
            'mobile': 'Cross-Platform',
            'ai': 'Intelligent',
            'blockchain': 'Decentralized'
        }
        
        for skill_key, modifier in skill_modifiers.items():
            if skill_key in primary_skill.lower():
                if not base_title.startswith(modifier):
                    return f"{modifier} {base_title}"
                break
        
        return base_title

    def _personalize_description(self, base_description: str, user_skills: List[str], match_type: str) -> str:
        """Personalize project description"""
        if not user_skills:
            return base_description
        
        # 🎯 Add personalization context
        skill_context = f"Leveraging your {', '.join(user_skills[:3])} expertise"
        
        personalization_additions = {
            'skill_based': f"{skill_context}, this project is specifically designed to advance your current skill set.",
            'difficulty_based': f"Perfectly matched to your experience level with {', '.join(user_skills[:2])} skills.",
            'trending': f"Stay ahead of the curve by combining {user_skills[0]} with cutting-edge technology trends."
        }
        
        addition = personalization_additions.get(match_type, skill_context)
        
        return f"{base_description} {addition}"

    def _adapt_skills_to_user(self, project_skills: List[str], user_skills: List[str]) -> List[str]:
        """Adapt project skills to include user's existing skills"""
        adapted_skills = project_skills.copy()
        
        # 🎯 Replace generic skills with user's specific skills where applicable
        skill_mappings = {
            'Frontend Framework': ['React', 'Vue', 'Angular'],
            'Backend API': ['FastAPI', 'Express', 'Django'],
            'Database': ['PostgreSQL', 'MongoDB', 'MySQL'],
            'Programming Language': ['Python', 'JavaScript', 'Dart']
        }
        
        for i, skill in enumerate(adapted_skills):
            if skill in skill_mappings:
                for user_skill in user_skills:
                    if user_skill in skill_mappings[skill]:
                        adapted_skills[i] = user_skill
                        break
        
        # 🚀 Add user's primary skills if not already included
        for user_skill in user_skills[:2]:
            if user_skill not in adapted_skills:
                adapted_skills.append(user_skill)
        
        return adapted_skills[:5]  # Limit to 5 skills

    def _estimate_duration(self, difficulty: str) -> str:
        """Estimate project duration based on difficulty"""
        duration_map = {
            'Beginner': '2-3 weeks',
            'Intermediate': '4-6 weeks',
            'Advanced': '8-12 weeks'
        }
        return duration_map.get(difficulty, '4-6 weeks')

    def _generate_recommendation_reason(self, project: Dict, user_skills: List[str], match_type: str) -> str:
        """Generate explanation for why this project is recommended"""
        reasons = {
            'skill_based': f"This project perfectly aligns with your {', '.join(user_skills[:2])} skills and will help you build advanced capabilities in {project['category']}.",
            'difficulty_based': f"Based on your skill portfolio, this {project['difficulty'].lower()}-level project will provide the right challenge to grow your expertise.",
            'trending': f"This cutting-edge project combines your {user_skills[0]} skills with trending technologies in {project['category']}."
        }
        
        return reasons.get(match_type, f"Great match for your {', '.join(user_skills[:2])} background!")

    def _analyze_message_intent(self, message: str) -> str:
        """Analyze user message to determine intent"""
        message_lower = message.lower()
        
        # 🎯 Intent keywords
        planning_keywords = ['plan', 'planning', 'roadmap', 'timeline', 'schedule', 'organize']
        technical_keywords = ['code', 'implement', 'bug', 'error', 'technical', 'algorithm', 'syntax']
        collaboration_keywords = ['team', 'collaborate', 'share', 'together', 'meeting', 'communication']
        learning_keywords = ['learn', 'tutorial', 'guide', 'how to', 'explain', 'understand', 'teach']
        
        if any(keyword in message_lower for keyword in planning_keywords):
            return 'planning'
        elif any(keyword in message_lower for keyword in technical_keywords):
            return 'technical'
        elif any(keyword in message_lower for keyword in collaboration_keywords):
            return 'collaboration'
        elif any(keyword in message_lower for keyword in learning_keywords):
            return 'learning'
        else:
            return 'general'

    def _detect_project_type(self, project_title: str, project_context: str) -> str:
        """Detect the type of project from title and context"""
        combined_text = f"{project_title} {project_context}".lower()
        
        if any(keyword in combined_text for keyword in ['web', 'website', 'frontend', 'backend']):
            return 'web_development'
        elif any(keyword in combined_text for keyword in ['mobile', 'app', 'android', 'ios', 'flutter']):
            return 'mobile_development'
        elif any(keyword in combined_text for keyword in ['ai', 'ml', 'machine learning', 'data']):
            return 'ai_data_science'
        elif any(keyword in combined_text for keyword in ['game', 'gaming', 'unity', 'unreal']):
            return 'game_development'
        else:
            return 'general_software'

    def _generate_planning_response(self, message: str, project_title: str, project_type: str) -> str:
        """Generate planning-focused response"""
        planning_templates = {
            'web_development': f"""
🎯 **Planning Strategy for {project_title}**

**Phase 1: Foundation (Week 1-2)**
• Set up development environment and project structure
• Design user interface mockups and user experience flow
• Plan database schema and API endpoints

**Phase 2: Core Development (Week 3-5)**
• Implement frontend components and user interface
• Build backend API and database integration
• Add authentication and user management

**Phase 3: Enhancement (Week 6-8)**
• Add advanced features and optimizations
• Implement testing and security measures
• Deploy and configure production environment

**Next Steps:**
• Create detailed task breakdown for each phase
• Set up project management tools (Trello, GitHub Issues)
• Define clear milestones and deliverables
            """,
            'mobile_development': f"""
🚀 **Mobile Development Roadmap for {project_title}**

**Discovery Phase (Week 1)**
• Define target audience and core features
• Create user personas and journey maps
• Plan app architecture and technology stack

**Design Phase (Week 2-3)**
• Design UI/UX with platform guidelines
• Create interactive prototypes
• Plan navigation and user flow

**Development Phase (Week 4-8)**
• Build core features and functionality
• Implement responsive design for multiple screen sizes
• Add offline capabilities and data synchronization

**Polish Phase (Week 9-10)**
• Testing on multiple devices and platforms
• Performance optimization and bug fixes
• Prepare for app store submission
            """,
            'ai_data_science': f"""
🧠 **AI/Data Science Project Plan for {project_title}**

**Data Collection & Analysis (Week 1-2)**
• Identify and gather relevant datasets
• Perform exploratory data analysis
• Clean and preprocess data for modeling

**Model Development (Week 3-5)**
• Select appropriate machine learning algorithms
• Train and validate models with cross-validation
• Fine-tune hyperparameters for optimal performance

**Implementation & Deployment (Week 6-8)**
• Build prediction pipeline and API endpoints
• Create user interface for model interaction
• Deploy model to cloud platform with monitoring

**Optimization & Monitoring (Week 9+)**
• Monitor model performance and accuracy
• Implement continuous learning and updates
• Scale infrastructure based on usage patterns
            """
        }
        
        return planning_templates.get(project_type, f"""
📋 **Project Planning Guide for {project_title}**

**1. Requirements Analysis**
• Define project scope and objectives
• Identify key features and user stories
• Research similar solutions and best practices

**2. Technical Planning**
• Choose technology stack and tools
• Design system architecture
• Plan development workflow and methodologies

**3. Implementation Strategy**
• Break down tasks into manageable sprints
• Set up development environment
• Create timeline with realistic milestones

**4. Quality Assurance**
• Plan testing strategy (unit, integration, user)
• Set up continuous integration/deployment
• Prepare documentation and user guides

Would you like me to elaborate on any specific phase?
        """)

    def _generate_technical_response(self, message: str, project_title: str, project_type: str) -> str:
        """Generate technical assistance response"""
        if 'error' in message.lower() or 'bug' in message.lower():
            return f"""
🔧 **Debugging Strategy for {project_title}**

**Immediate Steps:**
• Check console/logs for error messages
• Verify recent code changes that might have caused the issue
• Test in isolation to reproduce the problem consistently

**Common Solutions by Project Type:**
""" + {
            'web_development': """
• **Frontend Issues**: Check browser developer tools, verify API endpoints
• **Backend Issues**: Review server logs, check database connections
• **Integration**: Validate data formats and API contracts""",
            'mobile_development': """
• **Flutter Issues**: Run `flutter doctor`, check device logs
• **Performance**: Use Flutter Inspector, check memory usage
• **Platform-specific**: Test on multiple devices and OS versions""",
            'ai_data_science': """
• **Data Issues**: Validate input data format and quality
• **Model Problems**: Check feature engineering and data preprocessing
• **Performance**: Profile model inference time and memory usage"""
        }.get(project_type, "• Review documentation and check for version compatibility") + """

**Advanced Debugging:**
• Use breakpoints and step-through debugging
• Add detailed logging at key decision points
• Create minimal reproducible examples

Need help with a specific error message? Share the details!
        """
        
        return f"""
⚡ **Technical Guidance for {project_title}**

**Best Practices:**
• Follow clean code principles and consistent naming conventions
• Implement proper error handling and input validation
• Use version control effectively with meaningful commit messages

**Architecture Recommendations:**
• Design modular components for easier testing and maintenance
• Implement separation of concerns (MVC, MVVM patterns)
• Plan for scalability and future feature additions

**Performance Optimization:**
• Profile your application to identify bottlenecks
• Implement caching strategies where appropriate
• Optimize database queries and API calls

**Security Considerations:**
• Validate and sanitize all user inputs
• Implement proper authentication and authorization
• Keep dependencies updated and scan for vulnerabilities

What specific technical aspect would you like to dive deeper into?
        """

    def _generate_collaboration_response(self, message: str, project_title: str) -> str:
        """Generate collaboration-focused response"""
        return f"""
👥 **Team Collaboration Strategy for {project_title}**

**Communication Setup:**
• Establish regular team meetings (daily standups, weekly reviews)
• Choose collaboration tools (Slack, Discord, Microsoft Teams)
• Create shared documentation space (Notion, Confluence)

**Project Management:**
• Use project boards (GitHub Projects, Trello, Jira)
• Define clear roles and responsibilities for team members
• Set up sprint planning and task assignment processes

**Code Collaboration:**
• Implement branch-based workflow (Git Flow, GitHub Flow)
• Establish code review processes and quality standards
• Set up continuous integration for automated testing

**Knowledge Sharing:**
• Schedule regular tech talks and knowledge sharing sessions
• Maintain project documentation and architectural decisions
• Create onboarding guides for new team members

**Conflict Resolution:**
• Establish open communication channels for concerns
• Regular retrospectives to improve team processes
• Clear escalation paths for technical and interpersonal issues

How many team members are you working with? I can provide more specific advice based on your team size.
        """

    def _generate_learning_response(self, message: str, project_type: str) -> str:
        """Generate learning-focused response"""
        learning_resources = {
            'web_development': """
📚 **Learning Path for Web Development**

**Frontend Fundamentals:**
• HTML5 semantic elements and accessibility
• CSS Grid, Flexbox, and responsive design
• JavaScript ES6+ features and async programming
• React/Vue framework concepts and state management

**Backend Development:**
• RESTful API design principles
• Database design and SQL/NoSQL concepts
• Authentication and security best practices
• Server deployment and cloud services

**Recommended Resources:**
• MDN Web Docs for comprehensive references
• FreeCodeCamp for hands-on practice
• The Odin Project for structured curriculum
• YouTube channels: Traversy Media, Academind
            """,
            'mobile_development': """
📱 **Mobile Development Learning Journey**

**Cross-Platform Development:**
• Flutter/Dart fundamentals and widget system
• State management (Provider, Bloc, Riverpod)
• Navigation and routing patterns
• Platform-specific integrations

**Native Development:**
• iOS: Swift/SwiftUI and Xcode environment
• Android: Kotlin/Java and Android Studio
• Platform design guidelines (Material Design, Human Interface)

**Essential Skills:**
• Mobile UI/UX design principles
• API integration and data persistence
• Testing strategies for mobile apps
• App store submission processes

**Learning Resources:**
• Official Flutter/Android/iOS documentation
• Udemy courses by Angela Yu, Stephen Grider
• GitHub repositories with example projects
            """,
            'ai_data_science': """
🤖 **AI/Data Science Learning Roadmap**

**Mathematics Foundation:**
• Linear algebra and statistics fundamentals
• Probability theory and statistical inference
• Calculus basics for optimization

**Programming Skills:**
• Python for data science (Pandas, NumPy, Matplotlib)
• Machine learning libraries (Scikit-learn, TensorFlow, PyTorch)
• SQL for data manipulation and analysis

**Machine Learning Concepts:**
• Supervised vs unsupervised learning
• Model evaluation and validation techniques
• Feature engineering and selection
• Deep learning and neural networks

**Practical Experience:**
• Kaggle competitions and datasets
• Real-world project portfolio
• Open source contributions

**Learning Resources:**
• Coursera: Andrew Ng's Machine Learning Course
• fast.ai for practical deep learning
• Hands-On Machine Learning book by Aurélien Géron
            """
        }
        
        return learning_resources.get(project_type, """
🎓 **General Learning Strategy**

**Structured Approach:**
• Start with fundamentals and build gradually
• Practice with small projects before tackling complex ones
• Join communities and seek mentorship opportunities

**Hands-On Learning:**
• Build projects that interest you personally
• Contribute to open source projects
• Participate in hackathons and coding challenges

**Stay Updated:**
• Follow industry blogs and newsletters
• Attend webinars and tech conferences
• Join relevant Discord/Slack communities

**Document Your Journey:**
• Maintain a learning blog or journal
• Create tutorial content to reinforce understanding
• Build a portfolio showcasing your projects

What specific technology or concept would you like to focus on learning?
        """)

    def _generate_general_response(self, message: str, project_title: str, project_context: str) -> str:
        """Generate general helpful response"""
        return f"""
🚀 **AI Assistant for {project_title}**

I'm here to help you succeed with your project! I can assist you with:

**🎯 Project Planning & Strategy**
• Breaking down complex features into manageable tasks
• Creating realistic timelines and milestones
• Identifying potential challenges and solutions

**⚡ Technical Guidance**
• Code review and best practices
• Architecture decisions and design patterns
• Debugging assistance and problem-solving

**👥 Team Collaboration**
• Communication strategies and tools
• Workflow optimization and productivity tips
• Conflict resolution and team dynamics

**📚 Learning & Development**
• Skill development recommendations
• Resource suggestions and learning paths
• Career guidance and industry insights

**Current Focus Areas:**
{project_context if project_context else "Ready to help with any aspect of your project"}

What specific area would you like to explore? Feel free to ask about:
• Planning your next sprint or feature
• Solving a technical challenge
• Improving team collaboration
• Learning new technologies or concepts

I'm here to provide personalized guidance based on your project needs!
        """

    def _generate_fallback_response(self, message: str, project_title: str) -> str:
        """Generate fallback response when other methods fail"""
        return f"""
🤖 **AI Assistant for {project_title}**

I'm here to help you with your project! While I process your request, here are some ways I can assist:

**💡 Immediate Help:**
• Project planning and task breakdown
• Technical problem-solving and debugging
• Code review and best practices
• Learning resources and skill development

**🚀 Quick Actions:**
• Ask me about specific technologies or frameworks
• Get help with project architecture decisions
• Brainstorm solutions to current challenges
• Plan your next development sprint

Feel free to ask me anything about:
- Planning and organizing your project
- Technical implementation details
- Team collaboration strategies
- Learning new skills and technologies

What would you like to focus on today?
        """

    def _generate_fallback_suggestions(self, user_skills: List[str]) -> List[Dict[str, Any]]:
        """Generate basic fallback suggestions when advanced generation fails"""
        user_hash = abs(hash(str(user_skills))) % 10000
        
        return [
            {
                "id": f"fallback_{user_hash}_1",
                "type": "project",
                "project": {
                    "id": f"proj_fallback_{user_hash}_1",
                    "title": "Skill-Focused Portfolio Project",
                    "description": f"Build a comprehensive portfolio showcasing your {', '.join(user_skills[:3])} skills",
                    "required_skills": user_skills[:3] if user_skills else ["Programming", "Design"],
                    "category": "Portfolio Development",
                    "difficulty": "Intermediate"
                },
                "description": "Perfect project to demonstrate your abilities",
                "match_score": 0.8,
                "timeline": "3-4 weeks",
                "difficulty": "Intermediate",
                "ai_generated": True,
                "fallback": True
            }
        ]

    def _create_profile_key(self, user_skills: List[str], user_interests: List[str]) -> str:
        """Create a unique key for user profile caching"""
        skills_str = "_".join(sorted(user_skills[:5])) if user_skills else "no_skills"
        interests_str = "_".join(sorted(user_interests[:3])) if user_interests else "no_interests"
        return f"{skills_str}_{interests_str}"

# 🚀 Service factory function
def get_enhanced_ai_service(db: Session = None) -> EnhancedAIService:
    """Get enhanced AI service instance"""
    return EnhancedAIService(db)

# Backwards compatibility
def get_ai_service(db: Session = None) -> EnhancedAIService:
    """Get AI service instance (backwards compatible)"""
    return get_enhanced_ai_service(db)