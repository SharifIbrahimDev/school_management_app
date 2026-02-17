import 'package:flutter/foundation.dart';
import '../utils/storage_helper.dart';

class GlobalFilterProvider extends ChangeNotifier {
  String? _selectedSessionId;
  String? _selectedTermId;
  String? _selectedSectionId;
  String? _selectedClassId;

  String? get selectedSessionId => _selectedSessionId;
  String? get selectedTermId => _selectedTermId;
  String? get selectedSectionId => _selectedSectionId;
  String? get selectedClassId => _selectedClassId;

  GlobalFilterProvider() {
    _loadFilters();
  }

  Future<void> _loadFilters() async {
    _selectedSessionId = await StorageHelper.getCache('global_session_id');
    _selectedTermId = await StorageHelper.getCache('global_term_id');
    _selectedSectionId = await StorageHelper.getCache('global_section_id');
    _selectedClassId = await StorageHelper.getCache('global_class_id');
    notifyListeners();
  }

  Future<void> setSessionId(String? id) async {
    _selectedSessionId = id;
    await StorageHelper.saveCache('global_session_id', id);
    notifyListeners();
  }

  Future<void> setTermId(String? id) async {
    _selectedTermId = id;
    await StorageHelper.saveCache('global_term_id', id);
    notifyListeners();
  }

  Future<void> setSectionId(String? id) async {
    _selectedSectionId = id;
    await StorageHelper.saveCache('global_section_id', id);
    notifyListeners();
  }

  Future<void> setClassId(String? id) async {
    _selectedClassId = id;
    await StorageHelper.saveCache('global_class_id', id);
    notifyListeners();
  }

  void clearFilters() {
    _selectedSessionId = null;
    _selectedTermId = null;
    _selectedSectionId = null;
    _selectedClassId = null;
    StorageHelper.saveCache('global_session_id', null);
    StorageHelper.saveCache('global_term_id', null);
    StorageHelper.saveCache('global_section_id', null);
    StorageHelper.saveCache('global_class_id', null);
    notifyListeners();
  }
}
