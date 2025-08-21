import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final recentFilesProvider = StateNotifierProvider<RecentFilesController, List<String>>(
  (ref) => RecentFilesController(),
);

class RecentFilesController extends StateNotifier<List<String>> {
  RecentFilesController() : super(const <String>[]) {
    _load();
  }

  static const String _prefsKey = 'recent_files_v1';
  static const int _maxItems = 10;

  Future<void> _load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    state = prefs.getStringList(_prefsKey) ?? const <String>[];
  }

  Future<void> add(String path) async {
    final List<String> next = <String>[path, ...state.where((p) => p != path)];
    if (next.length > _maxItems) {
      next.removeRange(_maxItems, next.length);
    }
    state = next;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, state);
  }

  Future<void> clear() async {
    state = const <String>[];
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}