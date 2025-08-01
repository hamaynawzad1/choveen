// lib/core/services/simple_interest_service.dart
import 'dart:convert';
import 'dart:math';

class SimpleInterestGroupService {
  
  Future<Map<String, dynamic>> createInterestGroup({
    required String projectTitle,
    required String projectDescription,
    Map<String, dynamic>? aiSuggestionData,
  }) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Generate mock IDs
    final random = Random();
    final groupId = 'ig_${random.nextInt(999999).toString().padLeft(6, '0')}';
    final aiChatId = 'ai_${random.nextInt(999999).toString().padLeft(6, '0')}';
    final groupChatId = 'gc_${random.nextInt(999999).toString().padLeft(6, '0')}';
    
    // Mock successful response
    return {
      'id': groupId,
      'project_title': projectTitle,
      'member_count': 1,
      'ai_chat_id': aiChatId,
      'group_chat_id': groupChatId,
      'created_at': DateTime.now().toIso8601String(),
      'status': 'active'
    };
  }

  Future<bool> joinInterestGroup(String groupId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Mock success (90% success rate)
    return Random().nextDouble() > 0.1;
  }

  Future<List<Map<String, dynamic>>> getMyInterestGroups() async {
    await Future.delayed(const Duration(milliseconds: 600));
    
    // Mock data
    return [
      {
        'id': 'ig_123456',
        'project_title': 'Mobile App Development',
        'member_count': 3,
        'ai_chat_id': 'ai_123456',
        'group_chat_id': 'gc_123456',
        'status': 'active',
        'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String()
      },
      {
        'id': 'ig_789012',
        'project_title': 'AI Chat Bot',
        'member_count': 2,
        'ai_chat_id': 'ai_789012',
        'group_chat_id': 'gc_789012',
        'status': 'forming',
        'created_at': DateTime.now().subtract(const Duration(hours: 6)).toIso8601String()
      }
    ];
  }

  Future<String> sendAIMessage(String chatId, String message) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    
    // Mock AI responses
    final responses = [
      "That's a great idea! Let's break that down into smaller tasks.",
      "I think we should consider the technical requirements first. What technologies are you planning to use?",
      "Based on your message, I suggest we focus on these key areas: planning, design, development, and testing.",
      "That sounds feasible. What's your timeline for this project?",
      "Let me help you prioritize those tasks. Which one do you think is most critical?",
      "Good point! Have you considered the user experience aspect of this feature?",
      "I can help you create a project roadmap. Would you like to start with the MVP features?",
    ];
    
    return responses[Random().nextInt(responses.length)];
  }

  Future<List<Map<String, dynamic>>> getAIChatMessages(String chatId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    // Mock chat history
    return [
      {
        'id': 'msg_1',
        'sender': 'ai',
        'content': 'Hello! I\'m here to help you plan this project. What would you like to discuss?',
        'timestamp': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String()
      },
      {
        'id': 'msg_2',
        'sender': 'user',
        'content': 'What are the main tasks we should focus on?',
        'timestamp': DateTime.now().subtract(const Duration(hours: 1, minutes: 30)).toIso8601String()
      },
      {
        'id': 'msg_3',
        'sender': 'ai',
        'content': 'Great question! I recommend focusing on: 1) Requirements gathering, 2) UI/UX design, 3) Technical architecture, 4) Development planning. Which area interests you most?',
        'timestamp': DateTime.now().subtract(const Duration(hours: 1, minutes: 29)).toIso8601String()
      }
    ];
  }

  Future<Map<String, dynamic>> checkTeamFormation(String groupId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Mock team formation check
    final memberCount = Random().nextInt(5) + 1; // 1-5 members
    const minMembers = 2;
    
    if (memberCount >= minMembers) {
      return {
        'ready_for_team': true,
        'member_count': memberCount,
        'message': 'Your interest group is ready to form a real project team!',
        'next_steps': [
          'Create official project',
          'Assign roles to team members',
          'Set project timeline',
          'Start development'
        ]
      };
    } else {
      return {
        'ready_for_team': false,
        'member_count': memberCount,
        'members_needed': minMembers - memberCount,
        'message': 'Need ${minMembers - memberCount} more member(s) to form a team'
      };
    }
  }
}