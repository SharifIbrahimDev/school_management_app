import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/global_filter_provider.dart';
import '../core/services/session_service_api.dart';
import '../core/services/term_service_api.dart';
import '../core/services/section_service_api.dart';
import '../core/utils/app_theme.dart';
import '../core/models/academic_session_model.dart';
import '../core/models/term_model.dart';
import '../core/models/section_model.dart';

class GlobalFilterBar extends StatelessWidget {
  const GlobalFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final filters = Provider.of<GlobalFilterProvider>(context);
    
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _FilterChip(
            label: 'Session',
            value: filters.selectedSessionId ?? 'Select',
            icon: Icons.calendar_today_rounded,
            onTap: () => _showSessionPicker(context),
          ),
          const SizedBox(width: 12),
          _FilterChip(
            label: 'Term',
            value: filters.selectedTermId ?? 'Select',
            icon: Icons.timer_rounded,
            onTap: () => _showTermPicker(context),
          ),
          const SizedBox(width: 12),
          _FilterChip(
            label: 'Section',
            value: filters.selectedSectionId ?? 'Select',
            icon: Icons.account_tree_rounded,
            onTap: () => _showSectionPicker(context),
          ),
        ],
      ),
    );
  }

  void _showSessionPicker(BuildContext context) async {
    final sessionService = Provider.of<SessionServiceApi>(context, listen: false);
    final sessionsData = await sessionService.getSessions();
    final List<AcademicSessionModel> sessions = sessionsData.map((s) => AcademicSessionModel.fromMap(s)).toList();
    final filters = Provider.of<GlobalFilterProvider>(context, listen: false);

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => _PickerSheet(
        title: 'Select Session',
        items: sessions.map((s) => _PickerItem(id: s.id, label: s.sessionName)).toList(),
        selectedId: filters.selectedSessionId,
        onSelect: (id) => filters.setSessionId(id),
      ),
    );
  }

  void _showTermPicker(BuildContext context) async {
    final termService = Provider.of<TermServiceApi>(context, listen: false);
    final termsData = await termService.getTerms();
    final terms = termsData.map((t) => TermModel.fromMap(t)).toList();
    final filters = Provider.of<GlobalFilterProvider>(context, listen: false);

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => _PickerSheet(
        title: 'Select Term',
        items: terms.map((t) => _PickerItem(id: t.id, label: t.termName)).toList(),
        selectedId: filters.selectedTermId,
        onSelect: (id) => filters.setTermId(id),
      ),
    );
  }

  void _showSectionPicker(BuildContext context) async {
    final sectionService = Provider.of<SectionServiceApi>(context, listen: false);
    final sectionsData = await sectionService.getSections();
    final sections = sectionsData.map((s) => SectionModel.fromMap(s)).toList();
    final filters = Provider.of<GlobalFilterProvider>(context, listen: false);

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => _PickerSheet(
        title: 'Select Section',
        items: sections.map((s) => _PickerItem(id: s.id, label: s.sectionName)).toList(),
        selectedId: filters.selectedSectionId,
        onSelect: (id) => filters.setSectionId(id),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: AppTheme.glassDecoration(
          context: context,
          opacity: 0.1,
          borderRadius: 20,
          borderColor: AppTheme.primaryColor.withValues(alpha: 0.1),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondaryColor)),
                Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppTheme.textSecondaryColor),
          ],
        ),
      ),
    );
  }
}

class _PickerSheet extends StatelessWidget {
  final String title;
  final List<_PickerItem> items;
  final String? selectedId;
  final Function(String) onSelect;

  const _PickerSheet({
    required this.title,
    required this.items,
    this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = item.id == selectedId;
                return ListTile(
                  title: Text(item.label, style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppTheme.primaryColor : null,
                  )),
                  trailing: isSelected ? const Icon(Icons.check_circle, color: AppTheme.primaryColor) : null,
                  onTap: () {
                    onSelect(item.id);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerItem {
  final String id;
  final String label;

  _PickerItem({required this.id, required this.label});
}
