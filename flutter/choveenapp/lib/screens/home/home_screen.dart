import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/project_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/project_model.dart';
import '../../core/theme/app_colors.dart';
import '../profile/profile_screen.dart';
import '../ai_assistant/ai_chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Initialize providers with user data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
        projectProvider.initializeForUser(authProvider.user!.id);
        projectProvider.fetchProjects();
        
        // ✅ Fetch personalized suggestions with user skills
        projectProvider.fetchSuggestions(userSkills: authProvider.user!.skills);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHomeTab(),
          _buildProjectsTab(),
          _buildAITab(),
          _buildProfileTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
            ),
          ],
        ),
        child: TabBar(
          controller: _tabController,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          indicator: const BoxDecoration(),
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(
              icon: Icon(Icons.home, 
                color: _currentIndex == 0 ? AppColors.primary : Colors.grey),
              text: 'Home',
            ),
            Tab(
              icon: Icon(Icons.work, 
                color: _currentIndex == 1 ? AppColors.primary : Colors.grey),
              text: 'Projects',
            ),
            Tab(
              icon: Icon(Icons.psychology, 
                color: _currentIndex == 2 ? AppColors.primary : Colors.grey),
              text: 'AI Assistant',
            ),
            Tab(
              icon: Icon(Icons.person, 
                color: _currentIndex == 3 ? AppColors.primary : Colors.grey),
              text: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  // 🏠 HOME TAB - Enhanced with personalized content
  Widget _buildHomeTab() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        
        return RefreshIndicator(
          onRefresh: () async {
            if (user != null) {
              final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
              await projectProvider.fetchProjects();
              // ✅ Refresh with user skills for personalization
              await projectProvider.refreshSuggestions(userSkills: user.skills);
            }
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // Enhanced Header with User Skills
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Welcome back! 👋',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  user?.name ?? 'User',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                // ✅ Show user skills
                                if (user?.skills.isNotEmpty == true) ...[
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: user!.skills.take(3).map((skill) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          skill,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            child: Text(
                              user?.name.isNotEmpty == true 
                                  ? user!.name.substring(0, 1).toUpperCase() 
                                  : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Enhanced Stats Cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Consumer<ProjectProvider>(
                    builder: (context, projectProvider, child) {
                      return Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Projects',
                              '${projectProvider.projects.length}',
                              Icons.work,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              'AI Suggestions',
                              '${projectProvider.suggestions.length}',
                              Icons.lightbulb,
                              Colors.orange,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 32),

                // ✅ Enhanced AI Smart Suggestions Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "🎯 Personalized Suggestions",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Consumer<ProjectProvider>(
                                builder: (context, projectProvider, child) {
                                  return Text(
                                    "Last updated: ${projectProvider.getSuggestionsAge()}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
                              // ✅ Refresh with user skills
                              projectProvider.refreshSuggestions(userSkills: user?.skills);
                            },
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Refresh'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Consumer<ProjectProvider>(
                        builder: (context, projectProvider, child) {
                          if (projectProvider.isLoading) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32.0),
                                child: Column(
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 16),
                                    Text('Generating personalized suggestions...'),
                                  ],
                                ),
                              ),
                            );
                          }

                          if (projectProvider.suggestions.isEmpty) {
                            return Center(
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    children: [
                                      Icon(Icons.lightbulb_outline, size: 64, color: Colors.grey[400]),
                                      const SizedBox(height: 16),
                                      const Text('No suggestions available'),
                                      const SizedBox(height: 8),
                                      const Text('Update your skills in profile for better suggestions'),
                                      const SizedBox(height: 16),
                                      ElevatedButton(
                                        onPressed: () => projectProvider.fetchSuggestions(userSkills: user?.skills),
                                        child: const Text('Generate Suggestions'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }

                          return Column(
                            children: projectProvider.suggestions.take(3).map((suggestion) {
                              return _buildEnhancedSuggestionCard(suggestion, user?.skills);
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Enhanced Recent Projects Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildRecentProjectsSection(),
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        );
      },
    );
  }

  // ✅ Enhanced suggestion card with personalization indicators
  Widget _buildEnhancedSuggestionCard(suggestion, List<String>? userSkills) {
    final isPersonalized = suggestion.description.contains('Personalized') || 
                          (suggestion.matchScore > 0.8);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isPersonalized ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isPersonalized 
            ? BorderSide(color: Colors.purple.withOpacity(0.3), width: 1)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isPersonalized 
                        ? Colors.purple.withOpacity(0.1)
                        : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isPersonalized ? Icons.stars : Icons.auto_awesome, 
                    color: isPersonalized ? Colors.purple : Colors.blue, 
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              suggestion.project?.title ?? 'Project Suggestion',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (isPersonalized)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.purple.withOpacity(0.3)),
                              ),
                              child: const Text(
                                '🎯 FOR YOU',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.purple,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        suggestion.project?.description ?? suggestion.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // ✅ Enhanced Skills Chips with match indicators
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: (suggestion.project?.requiredSkills ?? []).take(4).map<Widget>((skill) {
                final isUserSkill = userSkills?.any((userSkill) => 
                    userSkill.toLowerCase().contains(skill.toLowerCase()) || 
                    skill.toLowerCase().contains(userSkill.toLowerCase())) ?? false;
                
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isUserSkill 
                        ? Colors.purple.withOpacity(0.15)
                        : AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: isUserSkill 
                        ? Border.all(color: Colors.purple.withOpacity(0.3))
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isUserSkill) ...[
                        const Icon(Icons.check_circle, size: 12, color: Colors.purple),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        skill,
                        style: TextStyle(
                          fontSize: 12,
                          color: isUserSkill ? Colors.purple : AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Match: ${(suggestion.matchScore * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (suggestion.timeline != null)
                      Text(
                        'Timeline: ${suggestion.timeline}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                  ],
                ),
                Row(
                  children: [
                    // ✅ Remove suggestion button
                    IconButton(
                      onPressed: () => _removeSuggestion(suggestion),
                      icon: const Icon(Icons.close, size: 20),
                      tooltip: 'Remove suggestion',
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        _openProjectDetail(suggestion);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isPersonalized ? Colors.purple : Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      child: const Text('Explore'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Enhanced Recent Projects Section with remove functionality
  Widget _buildRecentProjectsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Recent Projects",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => _tabController.animateTo(1),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Consumer<ProjectProvider>(
          builder: (context, projectProvider, child) {
            final recentProjects = projectProvider.projects.take(3).toList();
            
            if (recentProjects.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.work_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text('No projects yet'),
                      const SizedBox(height: 8),
                      const Text('Join a suggested project or create your own'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _tabController.animateTo(1),
                        child: const Text('Get Started'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: recentProjects.map((project) => _buildEnhancedProjectCard(project)).toList(),
            );
          },
        ),
      ],
    );
  }

  // ✅ Enhanced project card with remove functionality
  Widget _buildEnhancedProjectCard(Project project) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getStatusColor(project.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.work, color: _getStatusColor(project.status), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.title, 
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    project.description, 
                    style: const TextStyle(fontSize: 14), 
                    maxLines: 2, 
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(project.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          project.status.toUpperCase(), 
                          style: TextStyle(
                            fontSize: 12, 
                            color: _getStatusColor(project.status), 
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(project.createdAt), 
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // ✅ Action buttons
            PopupMenuButton(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'chat',
                  child: Row(
                    children: [
                      Icon(Icons.chat, size: 16),
                      SizedBox(width: 8),
                      Text('AI Chat'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Remove', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'chat') {
                  _openAIChat(project);
                } else if (value == 'remove') {
                  _removeProject(project);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // 📁 PROJECTS TAB
  Widget _buildProjectsTab() {
    return Consumer<ProjectProvider>(
      builder: (context, projectProvider, child) {
        return Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Colors.blue, Colors.blueAccent]),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Projects', 
                    style: TextStyle(
                      color: Colors.white, 
                      fontSize: 28, 
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Manage and track your projects', 
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
            
            // Projects List
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => projectProvider.fetchProjects(),
                child: projectProvider.projects.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.work_outline, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No projects yet'),
                            SizedBox(height: 8),
                            Text('Create your first project to get started'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: projectProvider.projects.length,
                        itemBuilder: (context, index) {
                          final project = projectProvider.projects[index];
                          return _buildEnhancedProjectCard(project);
                        },
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  // 🤖 AI ASSISTANT TAB
  Widget _buildAITab() {
    return Consumer<ProjectProvider>(
      builder: (context, projectProvider, child) {
        final projects = projectProvider.projects;
        
        if (projects.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.psychology, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No projects for AI assistance'),
                SizedBox(height: 8),
                Text('Create a project to start chatting with AI'),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Colors.purple, Colors.purpleAccent]),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.psychology, color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Text(
                        'AI Project Assistant', 
                        style: TextStyle(
                          color: Colors.white, 
                          fontSize: 20, 
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Get project-specific guidance and support', 
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${projects.length} Active Projects', 
                      style: const TextStyle(
                        color: Colors.white, 
                        fontSize: 12, 
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Projects List with AI Chat
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: projects.length,
                itemBuilder: (context, index) {
                  final project = projects[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.psychology, color: Colors.purple, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      project.title, 
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'AI Assistant for ${project.title}', 
                                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.circle, size: 8, color: Colors.green),
                                    SizedBox(width: 4),
                                    Text(
                                      'Online', 
                                      style: TextStyle(
                                        fontSize: 12, 
                                        color: Colors.green, 
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Get AI assistance for: ${project.requiredSkills.take(3).join(', ')}${project.requiredSkills.length > 3 ? '...' : ''}',
                            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Ready to help with your project', 
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _openAIChat(project),
                                icon: const Icon(Icons.chat, size: 18),
                                label: const Text('Start AI Chat'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // 👤 PROFILE TAB
  Widget _buildProfileTab() {
    return const EnhancedProfileScreen();
  }

  // ✅ Helper methods
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'on_hold':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else {
      return 'Recently';
    }
  }

  void _openAIChat(Project project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AIChatScreen(project: project),
      ),
    );
  }

  void _openProjectDetail(dynamic projectOrSuggestion) {
    // Handle both Project and Suggestion objects
    final project = projectOrSuggestion is Project 
        ? projectOrSuggestion 
        : projectOrSuggestion.project;
    
    if (project != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(project.title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(project.description),
                const SizedBox(height: 16),
                const Text('Required Skills:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: project.requiredSkills
                  .map((skill) => Chip(label: Text(skill as String)))
                  .toList()
                  .cast<Widget>(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _joinProject(project);
              },
              child: const Text('Join Project'),
            ),
          ],
        ),
      );
    }
  }

  // ✅ Enhanced action methods
  void _joinProject(Project project) {
    final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
    
    projectProvider.joinProject(project.id, project.title).then((success) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully joined "${project.title}"!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to join project'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  // ✅ Remove project functionality
  void _removeProject(Project project) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Project'),
        content: Text('Are you sure you want to remove "${project.title}" from your projects?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
              projectProvider.removeProject(project.id).then((success) {
                final message = success 
                    ? 'Project removed successfully'
                    : 'Failed to remove project';
                final color = success ? Colors.green : Colors.red;
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(message), backgroundColor: color),
                );
              });
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  // ✅ Remove suggestion functionality
  void _removeSuggestion(dynamic suggestion) {
    final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
    projectProvider.suggestions.remove(suggestion);
    projectProvider.notifyListeners();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Suggestion removed'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}