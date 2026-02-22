import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/user_model.dart';
import '../../core/services/auth_service_api.dart';
import '../../core/services/user_service_api.dart';
import '../../core/utils/app_theme.dart';
import 'add_user_screen.dart';
import 'user_details_screen.dart';
import 'student_parent_linking_screen.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_display_widget.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedRoleFilter = 'All';
  
  List<UserModel> _users = [];
  bool _isLoading = true;
  bool _isFetchingMore = false;
  int _currentPage = 1;
  bool _hasMore = true;
  String? _errorMessage;
  UserModel? _currentUser;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadUsers();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isFetchingMore && _hasMore && !_isLoading) {
        _loadUsers(loadMore: true);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  static const int _pageLimit = 100;

  Future<void> _loadUsers({bool loadMore = false}) async {
    if (loadMore) {
      if (_isFetchingMore || !_hasMore) return;
      setState(() => _isFetchingMore = true);
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _currentPage = 1;
        _hasMore = true;
      });
    }
    
    try {
      final authService = Provider.of<AuthServiceApi>(context, listen: false);
      final userService = Provider.of<UserServiceApi>(context, listen: false);

      final userMap = authService.currentUser;
      if (userMap == null) throw Exception('User not logged in');
      _currentUser = UserModel.fromMap(userMap);

      if (_currentUser!.role != UserRole.proprietor) {
        throw Exception('Access denied');
      }

      final pageToLoad = loadMore ? _currentPage : 1;

      // Convert "All" to null, and other roles to lowercase strings for the API
      final roleFilter = _selectedRoleFilter == 'All' ? null : _selectedRoleFilter.toLowerCase();
      
      final usersData = await userService.getUsers(
        role: roleFilter,
        page: pageToLoad,
        limit: _pageLimit,
        search: _searchController.text.isNotEmpty ? _searchController.text : null,
      );
      
      if (mounted) {
        setState(() {
          final newUsers = usersData.map((data) => UserModel.fromMap(data)).toList();
          
          if (loadMore) {
            _users.addAll(newUsers);
            _isFetchingMore = false;
          } else {
            _users = newUsers;
            _isLoading = false;
          }
          
          _currentPage = pageToLoad + 1;
          // If we got 0 users, there's definitely no more.
          // Or if we got some users but it's clearly less than a standard page (usually 15 or 50)
          // we should still keep trying until we get an empty list or total results is known.
          if (newUsers.isEmpty) {
            _hasMore = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isFetchingMore = false;
          _errorMessage = 'Error loading users: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_currentUser?.role != UserRole.proprietor) {
      return const Scaffold(
        body: Center(child: Text('Access denied')),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Users',
        actions: [
          IconButton(
            icon: const Icon(Icons.link, color: Colors.white),
            tooltip: 'Link Parent-Student',
            onPressed: _isLoading ? null : () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StudentParentLinkingScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _isLoading ? null : _loadUsers,
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton(
          backgroundColor: AppTheme.primaryColor,
          onPressed: _isLoading ? null : () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddUserScreen()),
            ).then((_) => _loadUsers());
          },
          tooltip: 'Add User',
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/auth_bg_pattern.png'),
            fit: BoxFit.cover,
            opacity: 0.05,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withValues(alpha: 0.1),
              AppTheme.accentColor.withValues(alpha: 0.2),
              Colors.white,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: AppTheme.glassDecoration(
                        context: context,
                        opacity: 0.6,
                        borderRadius: 16,
                        borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                      ),
                       child: TextField(
                        controller: _searchController,
                        onSubmitted: (value) => _loadUsers(),
                        decoration: InputDecoration(
                          hintText: 'Search users...',
                          prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
                          suffixIcon: _searchController.text.isNotEmpty 
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: _isLoading ? null : () {
                                  _searchController.clear();
                                  _loadUsers();
                                },
                              )
                            : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: AppTheme.glassDecoration(
                      context: context,
                      opacity: 0.6,
                      borderRadius: 16,
                      borderColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedRoleFilter,
                      underline: const SizedBox(),
                      items: ['All', 'Principal', 'Bursar', 'Teacher', 'Parent']
                          .map((role) => DropdownMenuItem(
                                value: role,
                                child: Text(role, style: const TextStyle(fontSize: 14)),
                              ))
                          .toList(),
                      onChanged: _isLoading ? null : (value) {
                        if (value != null) {
                          setState(() {
                            _selectedRoleFilter = value;
                            _isLoading = true;
                          });
                          _loadUsers();
                        }
                      },
                      icon: const Icon(Icons.filter_list, size: 20, color: AppTheme.primaryColor),
                      dropdownColor: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: LoadingIndicator(message: 'Loading users...'))
                  : _errorMessage != null
                      ? ErrorDisplayWidget(
                          error: _errorMessage!,
                          onRetry: _loadUsers,
                        )
                      : _buildUsersList(),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildUsersList() {
    // Include everyone except the proprietor in the "All" view
    final filteredUsers = _selectedRoleFilter == 'All'
        ? _users.where((u) => u.role != UserRole.proprietor).toList()
        : _users.where((u) => u.role.toString().split('.').last.toLowerCase() == _selectedRoleFilter.toLowerCase()).toList();

    if (filteredUsers.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.people_outline_rounded,
        title: 'No Users Found',
        message: _searchController.text.isNotEmpty 
            ? 'We couldn\'t find any users matching "${_searchController.text}"'
            : 'Start by adding your first school staff or parent account',
        actionButtonText: _searchController.text.isNotEmpty ? 'Clear Search' : 'Add User',
        onActionPressed: () {
          if (_searchController.text.isNotEmpty) {
            _searchController.clear();
            _loadUsers();
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddUserScreen()),
            ).then((_) => _loadUsers());
          }
        },
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: filteredUsers.length + (_isFetchingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == filteredUsers.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: LoadingIndicator(message: 'Loading more...'),
          );
        }
        final user = filteredUsers[index];
        return _buildUserCard(context, user);
      },
    );
  }

  Widget _buildUserCard(BuildContext context, UserModel user) {
    final theme = Theme.of(context);
    final roleColor = _getRoleColor(user.role);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.glassDecoration(
        context: context,
        opacity: 0.9, // Higher opacity for card background
        hasGlow: user.isActive,
        borderRadius: 20,
        borderColor: roleColor.withValues(alpha: 0.2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => UserDetailsScreen(user: user)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: roleColor.withValues(alpha: 0.1),
                    child: Icon(
                      _getRoleIcon(user.role),
                      color: roleColor,
                      size: 28,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: user.isActive ? AppTheme.neonEmerald : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.colorScheme.surface, width: 2),
                        boxShadow: [
                          if (user.isActive)
                            BoxShadow(
                              color: AppTheme.neonEmerald.withValues(alpha: 0.5),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: roleColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: roleColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            user.roleDisplayName.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: roleColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      user.email,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textHintColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.principal:
        return AppTheme.neonPurple;
      case UserRole.bursar:
        return AppTheme.neonBlue;
      case UserRole.teacher:
        return AppTheme.neonTeal;
      case UserRole.parent:
        return Colors.orangeAccent;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.principal:
        return Icons.school;
      case UserRole.bursar:
        return Icons.account_balance;
      case UserRole.teacher:
        return Icons.person_rounded;
      case UserRole.parent:
        return Icons.family_restroom;
      default:
        return Icons.person;
    }
  }
}
