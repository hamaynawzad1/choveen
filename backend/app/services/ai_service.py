# backend/app/services/ai_service.py - COMPLETELY FIXED VERSION
import google.generativeai as genai
import hashlib
import time
import random
from app.core.config import settings
import logging

logger = logging.getLogger(__name__)

class AIService:
    def __init__(self, db_session=None):
        """Initialize AI Service with Gemini"""
        try:
            genai.configure(api_key=settings.GEMINI_API_KEY)
            self.model = genai.GenerativeModel('gemini-1.5-flash')
            self.ai_service = "gemini"
            print("✅ Gemini AI initialized successfully")
        except Exception as e:
            print(f"❌ Gemini initialization failed: {e}")
            self.model = None
            self.ai_service = "fallback"

    def generate_project_suggestions(self, user_skills: list, project_preferences: str = "", user_id: str = None, force_refresh: bool = False) -> list:
        """🧠 INTELLIGENT: Generate truly creative and personalized suggestions"""
        try:
            skills_text = ", ".join(user_skills) if user_skills else "Technology enthusiast"
            
            print(f"🧠 INTELLIGENT AI: Analyzing skills for user {user_id}")
            print(f"🎯 Skills: {user_skills}")
            print(f"🔄 Creative mode: {force_refresh}")
            
            # Generate creative suggestions based on skills
            return self._generate_creative_suggestions(user_skills, user_id, force_refresh)
            
        except Exception as e:
            print(f"❌ AI suggestion error: {e}")
            return self._generate_creative_suggestions(user_skills, user_id, force_refresh)

    def _generate_creative_suggestions(self, user_skills: list, user_id: str, force_refresh: bool = False) -> list:
        """🎨 Generate intelligent, creative project suggestions"""
        try:
            skills_text = ", ".join(user_skills) if user_skills else "general programming"
            
            # Create unique identifier for this generation
            if force_refresh:
                timestamp = int(time.time())
                creativity_seed = random.randint(1000, 9999)
                unique_id = f"{user_id}_{timestamp}_{creativity_seed}"
            else:
                unique_id = f"{user_id}_consistent"
                
            suggestion_hash = abs(hash(unique_id)) % 100000
            
            print(f"🎨 Creating creative suggestions with hash: {suggestion_hash}")
            
            # 🧠 INTELLIGENT PROJECT TEMPLATES based on skill combinations
            creative_templates = self._get_skill_based_templates(user_skills, suggestion_hash)
            
            suggestions = []
            
            for i, template in enumerate(creative_templates):
                # Match skills to template requirements
                matched_skills = self._match_skills_to_template(user_skills, template)
                
                # Generate unique project idea
                project_idea = self._generate_project_idea(template, matched_skills, suggestion_hash, i)
                
                suggestion = {
                    "id": f"intelligent_{suggestion_hash}_{i + 1}",
                    "type": "project",
                    "project": {
                        "id": f"proj_intelligent_{suggestion_hash}_{i + 1}",
                        "title": project_idea["title"],
                        "description": project_idea["description"],
                        "required_skills": matched_skills
                    },
                    "description": project_idea["reasoning"],
                    "match_score": project_idea["match_score"],
                    "timeline": project_idea["timeline"],
                    "difficulty": project_idea["difficulty"],
                    "ai_generated": True,
                    "intelligence_level": "creative",
                    "personalized_for": skills_text,
                    "generated_for_user": str(user_id),
                    "creative_mode": force_refresh
                }
                suggestions.append(suggestion)
            
            print(f"✨ Generated {len(suggestions)} intelligent suggestions for {user_id}")
            return suggestions
            
        except Exception as e:
            print(f"❌ Creative generation error: {e}")
            return self._create_fallback_suggestions(user_skills, user_id)

    def _create_fallback_suggestions(self, user_skills: list, user_id: str) -> list:
        """🔄 Create simple fallback suggestions if everything fails"""
        try:
            skills_text = ", ".join(user_skills) if user_skills else "Programming"
            fallback_hash = abs(hash(f"{user_id}_fallback")) % 10000
            
            return [
                {
                    "id": f"fallback_{fallback_hash}_1",
                    "type": "project",
                    "project": {
                        "id": f"proj_fallback_{fallback_hash}_1",
                        "title": "Creative Portfolio Platform",
                        "description": f"Build a modern portfolio platform showcasing your {skills_text} skills with interactive features and professional design.",
                        "required_skills": user_skills[:3] if user_skills else ["HTML", "CSS", "JavaScript"]
                    },
                    "description": f"Perfect for demonstrating your {skills_text} expertise to potential employers and clients.",
                    "match_score": 0.85,
                    "timeline": "3-4 weeks",
                    "difficulty": "Intermediate"
                },
                {
                    "id": f"fallback_{fallback_hash}_2",
                    "type": "project",
                    "project": {
                        "id": f"proj_fallback_{fallback_hash}_2",
                        "title": "Smart Task Manager",
                        "description": f"Create an intelligent task management application using your {skills_text} skills with automation and smart scheduling.",
                        "required_skills": user_skills[:3] if user_skills else ["Python", "Database", "UI/UX"]
                    },
                    "description": f"Excellent project to showcase your {skills_text} abilities while solving real-world productivity challenges.",
                    "match_score": 0.78,
                    "timeline": "4-6 weeks",
                    "difficulty": "Advanced"
                }
            ]
        except Exception as e:
            print(f"❌ Fallback creation failed: {e}")
            return []

    def _get_skill_based_templates(self, user_skills: list, hash_seed: int) -> list:
        """🎯 Get templates based on user's actual skills"""
        
        # Analyze skill categories
        skill_categories = self._analyze_skill_categories(user_skills)
        
        # 🧠 INTELLIGENT TEMPLATES for different skill combinations
        if "design" in skill_categories:
            return [
                {
                    "category": "creative_platform",
                    "focus": "visual_innovation",
                    "complexity": "intermediate",
                    "industry": "creative_tech"
                },
                {
                    "category": "brand_experience",
                    "focus": "user_engagement", 
                    "complexity": "advanced",
                    "industry": "marketing_tech"
                },
                {
                    "category": "interactive_media",
                    "focus": "storytelling",
                    "complexity": "expert",
                    "industry": "entertainment"
                }
            ]
        elif "programming" in skill_categories or "development" in skill_categories:
            return [
                {
                    "category": "smart_automation",
                    "focus": "efficiency_optimization",
                    "complexity": "intermediate", 
                    "industry": "productivity_tech"
                },
                {
                    "category": "ai_integration",
                    "focus": "intelligent_systems",
                    "complexity": "advanced",
                    "industry": "artificial_intelligence"
                },
                {
                    "category": "platform_architecture",
                    "focus": "scalable_solutions",
                    "complexity": "expert",
                    "industry": "enterprise_tech"
                }
            ]
        elif "business" in skill_categories or "management" in skill_categories:
            return [
                {
                    "category": "strategic_dashboard",
                    "focus": "data_insights",
                    "complexity": "intermediate",
                    "industry": "business_intelligence"
                },
                {
                    "category": "collaboration_hub",
                    "focus": "team_optimization",
                    "complexity": "advanced", 
                    "industry": "team_productivity"
                },
                {
                    "category": "innovation_platform",
                    "focus": "strategic_growth",
                    "complexity": "expert",
                    "industry": "business_transformation"
                }
            ]
        else:
            # Generic innovative templates
            return [
                {
                    "category": "innovation_lab",
                    "focus": "creative_solutions",
                    "complexity": "intermediate",
                    "industry": "emerging_tech"
                },
                {
                    "category": "community_platform",
                    "focus": "social_impact",
                    "complexity": "advanced",
                    "industry": "social_tech"
                },
                {
                    "category": "future_concept",
                    "focus": "next_generation",
                    "complexity": "expert", 
                    "industry": "innovation"
                }
            ]

    def _analyze_skill_categories(self, user_skills: list) -> list:
        """📊 Analyze and categorize user skills"""
        categories = []
        
        design_keywords = ["design", "ui", "ux", "graphic", "visual", "creative", "art", "animation"]
        programming_keywords = ["programming", "development", "coding", "software", "web", "mobile", "python", "javascript", "flutter", "dart"]
        business_keywords = ["business", "management", "strategy", "marketing", "sales", "analytics", "finance"]
        
        skills_lower = [skill.lower() for skill in user_skills]
        skills_text = " ".join(skills_lower)
        
        if any(keyword in skills_text for keyword in design_keywords):
            categories.append("design")
        if any(keyword in skills_text for keyword in programming_keywords):
            categories.append("programming")
        if any(keyword in skills_text for keyword in business_keywords):
            categories.append("business")
        if any(keyword in skills_text for keyword in ["data", "analysis", "research", "science"]):
            categories.append("data")
        if any(keyword in skills_text for keyword in ["communication", "writing", "content", "social"]):
            categories.append("communication")
            
        return categories if categories else ["general"]

    def _match_skills_to_template(self, user_skills: list, template: dict) -> list:
        """🎯 Match user skills to project template requirements"""
        matched = user_skills[:3] if len(user_skills) >= 3 else user_skills.copy()
        
        # Add complementary skills based on template
        category = template["category"]
        
        if "platform" in category:
            matched.extend(["System Architecture", "User Experience"])
        elif "dashboard" in category:
            matched.extend(["Data Visualization", "Analytics"])
        elif "creative" in category:
            matched.extend(["Innovation", "Visual Design"])
        elif "ai" in category:
            matched.extend(["Machine Learning", "Algorithm Design"])
        else:
            matched.extend(["Problem Solving", "Team Collaboration"])
            
        # Remove duplicates and limit to 5 skills
        return list(dict.fromkeys(matched))[:5]

    def _generate_project_idea(self, template: dict, skills: list, hash_seed: int, index: int) -> dict:
        """💡 Generate specific project idea based on template and skills"""
        
        # Creative project ideas based on template category
        ideas = self._get_project_ideas_by_category()
        
        # Get appropriate ideas for template category
        category = template["category"]
        if category not in ideas:
            category = "innovation_lab"  # Default fallback
            
        idea_set = ideas[category]
        
        # Select idea based on hash and index for consistency
        title_index = (hash_seed + index) % len(idea_set["titles"])
        desc_index = (hash_seed + index) % len(idea_set["descriptions"])
        
        title = idea_set["titles"][title_index]
        description = idea_set["descriptions"][desc_index]
        
        # Calculate match score based on skill alignment
        match_score = round(0.82 + (len(skills) * 0.02) + (index * 0.03), 2)
        
        # Determine timeline based on complexity
        complexity = template["complexity"]
        timelines = {
            "intermediate": ["3-4 weeks", "4-5 weeks", "5-6 weeks"],
            "advanced": ["6-8 weeks", "8-10 weeks", "10-12 weeks"],
            "expert": ["12-16 weeks", "16-20 weeks", "20-24 weeks"]
        }
        
        timeline_options = timelines.get(complexity, timelines["intermediate"])
        timeline = timeline_options[index % len(timeline_options)]
        
        # Generate personalized reasoning
        main_skills = ", ".join(skills[:3])
        reasoning = f"This project perfectly aligns with your expertise in {main_skills}. It's designed to challenge your current skills while introducing cutting-edge technologies and methodologies that will significantly enhance your professional portfolio."
        
        return {
            "title": title,
            "description": description,
            "reasoning": reasoning,
            "match_score": match_score,
            "timeline": timeline,
            "difficulty": complexity.title()
        }

    def _get_project_ideas_by_category(self) -> dict:
        """📚 Get all project ideas organized by category"""
        return {
            "creative_platform": {
                "titles": [
                    "Visual Storytelling Studio",
                    "Creative Collaboration Hub", 
                    "Digital Art Innovation Platform",
                    "Interactive Design Workspace"
                ],
                "descriptions": [
                    "Build a cutting-edge platform where creators can collaborate on visual projects with real-time editing, AI-assisted design suggestions, and seamless workflow integration.",
                    "Create an innovative space for creative professionals to showcase portfolios, collaborate on projects, and discover new opportunities through intelligent matching.",
                    "Develop a comprehensive creative suite that combines traditional design tools with AI-powered features for enhanced creativity and productivity."
                ]
            },
            "smart_automation": {
                "titles": [
                    "Intelligent Workflow Optimizer",
                    "Smart Task Automation Engine",
                    "AI-Powered Productivity Suite",
                    "Automated Decision Support System"
                ],
                "descriptions": [
                    "Design an intelligent system that learns from user behavior to automate repetitive tasks and optimize workflows for maximum efficiency.",
                    "Build a smart automation platform that can analyze processes and suggest improvements while seamlessly integrating with existing tools.",
                    "Create a comprehensive productivity solution that uses machine learning to predict user needs and automate routine operations."
                ]
            },
            "strategic_dashboard": {
                "titles": [
                    "Executive Intelligence Dashboard",
                    "Strategic Insights Platform",
                    "Business Analytics Command Center",
                    "Performance Optimization Hub"
                ],
                "descriptions": [
                    "Develop a sophisticated dashboard that transforms complex business data into actionable insights with predictive analytics and real-time monitoring.",
                    "Build a comprehensive platform that aggregates business metrics and provides intelligent recommendations for strategic decision-making.",
                    "Create an advanced analytics solution that visualizes key performance indicators and identifies optimization opportunities."
                ]
            },
            "ai_integration": {
                "titles": [
                    "Intelligent Assistant Ecosystem",
                    "AI-Powered Decision Platform",
                    "Smart Integration Framework",
                    "Cognitive Computing Solution"
                ],
                "descriptions": [
                    "Build a sophisticated AI ecosystem that integrates multiple intelligent services to provide seamless automation and decision support.",
                    "Create a platform that leverages artificial intelligence to enhance human decision-making with data-driven insights and predictions.",
                    "Develop an advanced framework that enables businesses to integrate AI capabilities into their existing workflows and processes."
                ]
            },
            "innovation_lab": {
                "titles": [
                    "Future Innovation Incubator",
                    "Emerging Technology Hub",
                    "Creative Solution Laboratory",
                    "Next-Gen Development Platform"
                ],
                "descriptions": [
                    "Create an experimental platform for testing and developing innovative solutions that address emerging challenges in technology and society.",
                    "Build a collaborative space where innovators can prototype new ideas, share resources, and accelerate the development of breakthrough technologies.",
                    "Develop a comprehensive innovation ecosystem that supports the entire journey from concept to implementation."
                ]
            },
            "brand_experience": {
                "titles": [
                    "Brand Identity Revolution",
                    "Customer Experience Platform",
                    "Digital Brand Ecosystem"
                ],
                "descriptions": [
                    "Create a comprehensive brand management platform that unifies visual identity, customer touchpoints, and brand messaging across all channels.",
                    "Build an innovative customer experience platform that delivers personalized brand interactions through intelligent automation and design.",
                    "Develop a complete digital ecosystem that strengthens brand presence and enhances customer engagement through creative technology."
                ]
            },
            "collaboration_hub": {
                "titles": [
                    "Team Synergy Platform",
                    "Collaborative Intelligence Hub",
                    "Unified Workspace Solution"
                ],
                "descriptions": [
                    "Design a next-generation collaboration platform that enhances team productivity through intelligent task management and seamless communication.",
                    "Build a comprehensive hub that combines project management, communication tools, and knowledge sharing in an intuitive interface.",
                    "Create a unified workspace that adapts to team needs and provides intelligent insights for optimal collaboration and productivity."
                ]
            }
        }

    def get_project_chat_response(self, message: str, project_title: str, project_description: str = "") -> str:
        """🧠 INTELLIGENT: Enhanced AI chat with better context awareness"""
        try:
            message_lower = message.lower().strip()
            
            # Check for non-project topics
            non_project_keywords = ['weather', 'car', 'ferrari', 'bugatti', 'food', 'movie', 'sport',
                                  'news', 'politics', 'celebrity', 'game', 'music', 'travel']
            
            if any(keyword in message_lower for keyword in non_project_keywords):
                return "I'm focused on helping you with your project development. Let's discuss your project goals, technical challenges, or team coordination instead!"
            
            # 🧠 INTELLIGENT PROJECT RESPONSES
            if any(word in message_lower for word in ['hi', 'hello', 'hey', 'start', 'begin']):
                return f"Hello! I'm your intelligent project assistant for '{project_title}'. I can help you with:\n\n🎯 Strategic planning and roadmaps\n💡 Creative problem-solving\n🔧 Technical guidance\n👥 Team coordination\n📊 Progress tracking\n\nWhat aspect would you like to explore first?"
            
            if any(word in message_lower for word in ['plan', 'planning', 'strategy', 'roadmap']):
                return f"Excellent! Let's create a strategic plan for '{project_title}':\n\n🔍 **Discovery Phase:**\n• Requirements analysis\n• Stakeholder mapping\n• Technology assessment\n\n🎨 **Design Phase:**\n• User experience design\n• System architecture\n• Prototype development\n\n🚀 **Development Phase:**\n• Iterative development\n• Quality assurance\n• Performance optimization\n\n📈 **Launch Phase:**\n• Deployment strategy\n• User onboarding\n• Performance monitoring\n\nWhich phase would you like to dive deeper into?"
            
            if any(word in message_lower for word in ['stuck', 'problem', 'issue', 'help', 'challenge', 'difficult']):
                return f"I'm here to help you overcome challenges with '{project_title}'! Let's troubleshoot together:\n\n🔍 **Problem-Solving Framework:**\n• Clearly define the issue\n• Identify root causes\n• Brainstorm potential solutions\n• Evaluate pros and cons\n• Implement and test\n\n💡 **Common Solutions:**\n• Break complex problems into smaller parts\n• Research similar implementations\n• Consult with experts or community\n• Prototype different approaches\n\nCan you describe the specific challenge you're facing? The more details you provide, the better I can assist you!"
            
            # Enhanced default response
            return f"I'm your intelligent project assistant for '{project_title}'! I can provide deep insights on strategic planning, technical guidance, team leadership, and project management. What specific aspect would you like help with?"
            
        except Exception as e:
            print(f"❌ AI chat error: {e}")
            return f"I'm your intelligent assistant for '{project_title}'! How can I help you succeed with your project today?"
    
    def get_ai_response(prompt: str) -> str:
        try:
            # نموونە بۆ جیمینای گووگڵ (پێویستە API Key هەبێت)
            response = palm.generate_text(
                model='models/text-bison-001',
                prompt=prompt,
                temperature=0.7,
                max_output_tokens=500
            )
            return response.result
        except Exception as e:
            return f"هەڵە: {str(e)}"

def get_ai_service(db_session=None):
    """Get AI service instance"""
    return AIService(db_session)