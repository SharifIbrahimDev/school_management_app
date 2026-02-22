import 'package:flutter/material.dart';
import '../core/models/user_model.dart';
import '../core/utils/app_theme.dart';

class NavigationSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final UserRole userRole;
  final bool isCollapsed;

  const NavigationSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.userRole,
    this.isCollapsed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: _getNavItems().asMap().entries.map((entry) {
                  return _buildNavItem(context, entry.key, entry.value);
                }).toList(),
              ),
            ),
          ),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 80,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: isCollapsed
          ? const Icon(Icons.school, size: 32, color: AppTheme.primaryColor)
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.school, color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 12),
                const Text(
                  'School App',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, _NavItem item) {
    final isSelected = selectedIndex == index;
    
    return InkWell(
      onTap: () => onItemSelected(index),
      child: Container(
        height: 56,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Icon(
              item.icon,
              color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
              size: 24,
            ),
            if (!isCollapsed) ...[
              const SizedBox(width: 16),
              Text(
                item.label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: isCollapsed
          ? const SizedBox()
          : Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  child: const Icon(Icons.person, color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userRole.toString().split('.').last.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      Text(
                        'Logged In',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  List<_NavItem> _getNavItems() {
    List<_NavItem> items = [
      _NavItem(Icons.grid_view_rounded, 'Home'),
    ];

    switch (userRole) {
      case UserRole.proprietor:
        items.addAll([
          _NavItem(Icons.school_rounded, 'Sections'),
          _NavItem(Icons.class_rounded, 'Classes'),
          _NavItem(Icons.people_alt_rounded, 'Users'),
          _NavItem(Icons.analytics_rounded, 'Reports'),
          _NavItem(Icons.settings_suggest_rounded, 'Settings'),
        ]);
        break;
      case UserRole.principal:
        items.addAll([
          _NavItem(Icons.school_rounded, 'Sections'),
          _NavItem(Icons.groups_rounded, 'Students'),
          _NavItem(Icons.event_note_rounded, 'Sessions'),
        ]);
        break;
      case UserRole.bursar:
        items.addAll([
          _NavItem(Icons.school_rounded, 'Sections'),
          _NavItem(Icons.payments_rounded, 'Fees'),
          _NavItem(Icons.event_note_rounded, 'Sessions'),
        ]);
        break;
      case UserRole.teacher:
        items.addAll([
          _NavItem(Icons.auto_stories_rounded, 'Academics'),
        ]);
        break;
      case UserRole.parent:
        break;
    }

    items.add(_NavItem(Icons.person_2_rounded, 'Profile'));
    return items;
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  _NavItem(this.icon, this.label);
}
