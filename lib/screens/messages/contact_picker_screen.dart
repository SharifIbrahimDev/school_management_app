import 'package:flutter/material.dart';
import '../../widgets/custom_app_bar.dart';
import 'package:provider/provider.dart';
import '../../core/utils/app_theme.dart';
import '../../core/services/user_service_api.dart';
import '../../widgets/loading_indicator.dart';

class ContactPickerScreen extends StatefulWidget {
  const ContactPickerScreen({super.key});

  @override
  State<ContactPickerScreen> createState() => _ContactPickerScreenState();
}

class _ContactPickerScreenState extends State<ContactPickerScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _admins = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  String _searchQuery = '';
  int _selectedTab = 0; // 0: Teachers, 1: Admins

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);
    try {
      final userService = Provider.of<UserServiceApi>(context, listen: false);
      
      // Fetch teachers
      final teachers = await userService.getUsers(role: 'teacher', isActive: true);
      
      // Fetch admins (principal, bursar, proprietor)
      // Note: API might support comma separated roles or we fetch individually. 
      // For simplicity, let's assume we fetch all and filter or make parallel calls if supported.
      // UserServiceApi doesn't look like it supports multiple roles in one call looking at the code (queryParams['role'] = role).
      // So we make parallel calls.
      
      final principals = await userService.getUsers(role: 'principal', isActive: true);
      final bursars = await userService.getUsers(role: 'bursar', isActive: true);
      final proprietors = await userService.getUsers(role: 'proprietor', isActive: true);
      
      final admins = [...principals, ...bursars, ...proprietors];

      if (mounted) {
        setState(() {
          _teachers = teachers;
          _admins = admins;
          _updateFilteredList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading contacts: $e')));
      }
    }
  }

  void _updateFilteredList() {
    final sourceList = _selectedTab == 0 ? _teachers : _admins;
    if (_searchQuery.isEmpty) {
      _filteredUsers = sourceList;
    } else {
      _filteredUsers = sourceList.where((u) {
        final name = (u['full_name'] ?? u['name'] ?? '').toString().toLowerCase();
        return name.contains(_searchQuery.toLowerCase());
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'New Message',
      ),
      body: Container(
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: AssetImage('assets/images/auth_bg_pattern.png'),
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
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  decoration: AppTheme.glassDecoration(context: context, opacity: 0.2, borderRadius: 12),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search people...',
                      prefixIcon: Icon(Icons.search),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                        _updateFilteredList();
                      });
                    },
                  ),
                ),
              ),

              // Tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildTab('Teachers', 0),
                    const SizedBox(width: 12),
                    _buildTab('Admins', 1),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // List
              Expanded(
                child: _isLoading
                    ? const Center(child: LoadingIndicator())
                    : _filteredUsers.isEmpty
                        ? Center(child: Text('No ${_selectedTab == 0 ? "teachers" : "admins"} found'))
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredUsers.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final user = _filteredUsers[index];
                              final name = user['full_name'] ?? user['name'] ?? 'Unknown';
                              final role = user['role'] ?? '';
                              
                              return Container(
                                decoration: AppTheme.glassDecoration(context: context, opacity: 0.5, borderRadius: 16),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                                    child: Text(name[0], style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                                  ),
                                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text(role.toUpperCase(), style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                                  trailing: const Icon(Icons.message_outlined, color: AppTheme.primaryColor),
                                  onTap: () {
                                    Navigator.pop(context, user);
                                  },
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = index;
            _updateFilteredList();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.withValues(alpha: 0.3)),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }
}
