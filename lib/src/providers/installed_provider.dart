import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../core/services/package_service.dart';
import '../models/app_model.dart';

class InstalledProvider extends ChangeNotifier {
  final List<PackageService> _sources;

  List<AppModel> _apps = [];
  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _errorMessage;

  InstalledProvider({required List<PackageService> sources})
    : _sources = sources;

  List<AppModel> get apps => _apps;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadIfNeeded() async {
    if (_hasLoaded) {
      return;
    }
    await refresh();
  }

  Future<void> refresh() async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final merged = <AppModel>[];
    final errors = <String>[];

    for (final source in _sources) {
      try {
        merged.addAll(await source.getInstalledApps());
      } catch (error) {
        errors.add(error.toString());
      }
    }

    _apps = _dedupeAndSort(merged);
    _hasLoaded = true;
    _isLoading = false;
    _errorMessage = errors.isEmpty ? null : errors.join('\n');
    notifyListeners();
  }

  List<AppModel> _dedupeAndSort(List<AppModel> apps) {
    final byId = <String, AppModel>{};
    for (final app in apps) {
      byId[app.id] = app;
    }

    final deduped = byId.values.toList()
      ..sort(
        (left, right) =>
            left.name.toLowerCase().compareTo(right.name.toLowerCase()),
      );

    return deduped;
  }
}
