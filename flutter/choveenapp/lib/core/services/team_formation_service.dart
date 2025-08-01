// 👥 TEAM FORMATION: lib/services/team_formation_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/project_model.dart';
import '../../models/user_model.dart';

class TeamFormationService {
  static final TeamFormationService _instance = TeamFormationService._internal();
  factory TeamFormationService() => _instance;
  TeamFormationService._internal();

  static const String _projectMembersKey = 'project_members';
  static const String _teamChatsKey = 'team_chats';

  // 🚨 AUTO TEAM FORMATION - When 2+ people join same project
  Future<Map<String, dynamic>> checkAndFormTeam(String projectId, String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get current members for this project
      final membersJson = prefs.getString('${_projectMembersKey}_$projectId') ?? '[]';
      final members = List<String>.from(json.decode(membersJson));
      
      // Add new member if not already added
      if (!members.contains(userId)) {
        members.add(userId);
        await prefs.setString('${_projectMembersKey}_$projectId', json.encode(members));
        
        print('👥 Project $projectId now has ${members.length} members');
        
        // AUTO TEAM FORMATION when 2+ members
        if (members.length >= 2) {
          await _createTeamChat(projectId, members);
          
          return {
            'team_formed': true,
            'member_count': members.length,
            'team_chat_id': 'team_$projectId',
            'message': '🎉 Team formed! ${members.length} members joined.',
            'members': members,
          };
        }
      }
      
      return {
        'team_formed': false,
        'member_count': members.length,
        'message': 'Waiting for more members to form a team...',
        'members': members,
      };
    } catch (e) {
      print('❌ Team formation error: $e');
      return {
        'team_formed': false,
        'member_count': 1,
        'message': 'Project joined successfully!',
        'error': e.toString(),
      };
    }
  }

  // Create team chat when team is formed
  Future<void> _createTeamChat(String projectId, List<String> members) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final teamChat = {
        'id': 'team_$projectId',
        'project_id': projectId,
        'members': members,
        'created_at': DateTime.now().toIso8601String(),
        'messages': [
          {
            'id': 'welcome_${DateTime.now().millisecondsSinceEpoch}',
            'sender': 'system',
            'content': '🎉 Welcome to the team! You now have ${members.length} members working together.',
            'timestamp': DateTime.now().toIso8601String(),
            'type': 'system'
          }
        ]
      };
      
      // Save team chat
      final chatsJson = prefs.getString(_teamChatsKey) ?? '[]';
      final chats = List<Map<String, dynamic>>.from(json.decode(chatsJson));
      
      // Remove existing chat for this project
      chats.removeWhere((chat) => chat['project_id'] == projectId);
      
      // Add new team chat
      chats.add(teamChat);
      await prefs.setString(_teamChatsKey, json.encode(chats));
      
      print('✅ Team chat created for project $projectId with ${members.length} members');
    } catch (e) {
      print('❌ Error creating team chat: $e');
    }
  }

  // Get team chat for project
  Future<Map<String, dynamic>?> getTeamChat(String projectId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final chatsJson = prefs.getString(_teamChatsKey) ?? '[]';
      final chats = List<Map<String, dynamic>>.from(json.decode(chatsJson));
      
      return chats.firstWhere(
        (chat) => chat['project_id'] == projectId,
        orElse: () => {},
      );
    } catch (e) {
      print('❌ Error getting team chat: $e');
      return null;
    }
  }

  // Add message to team chat
  Future<void> addTeamMessage(String projectId, String senderId, String content) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final chatsJson = prefs.getString(_teamChatsKey) ?? '[]';
      final chats = List<Map<String, dynamic>>.from(json.decode(chatsJson));
      
      final chatIndex = chats.indexWhere((chat) => chat['project_id'] == projectId);
      if (chatIndex != -1) {
        final messages = List<Map<String, dynamic>>.from(chats[chatIndex]['messages'] ?? []);
        
        messages.add({
          'id': 'msg_${DateTime.now().millisecondsSinceEpoch}',
          'sender': senderId,
          'content': content,
          'timestamp': DateTime.now().toIso8601String(),
          'type': 'user'
        });
        
        chats[chatIndex]['messages'] = messages;
        await prefs.setString(_teamChatsKey, json.encode(chats));
      }
    } catch (e) {
      print('❌ Error adding team message: $e');
    }
  }

  // Get project members count
  Future<int> getProjectMemberCount(String projectId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final membersJson = prefs.getString('${_projectMembersKey}_$projectId') ?? '[]';
      final members = List<String>.from(json.decode(membersJson));
      return members.length;
    } catch (e) {
      return 1;
    }
  }

  // Get all team chats for user
  Future<List<Map<String, dynamic>>> getUserTeamChats(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final chatsJson = prefs.getString(_teamChatsKey) ?? '[]';
      final allChats = List<Map<String, dynamic>>.from(json.decode(chatsJson));
      
      // Filter chats where user is a member
      return allChats.where((chat) {
        final members = List<String>.from(chat['members'] ?? []);
        return members.contains(userId);
      }).toList();
    } catch (e) {
      print('❌ Error getting user team chats: $e');
      return [];
    }
  }

  // Simulate other users joining (for demo)
  Future<void> simulateTeamJoining(String projectId) async {
    try {
      final demoUsers = ['demo_sarah', 'demo_ahmad', 'demo_karwan'];
      
      for (final user in demoUsers) {
        await Future.delayed(const Duration(seconds: 2));
        await checkAndFormTeam(projectId, user);
      }
    } catch (e) {
      print('❌ Error simulating team joining: $e');
    }
  }
}