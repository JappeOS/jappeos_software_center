//  jappeos_software_center, A GUI app for installing software for JappeOS.
//  Copyright (C) 2026  The JappeOS team.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as
//  published by the Free Software Foundation, either version 3 of the
//  License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.

import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../core/services/package_service.dart';
import '../models/app_model.dart';

class ExploreProvider extends ChangeNotifier {
  final List<PackageService> _sources;

  List<AppModel> _apps = const [];
  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _errorMessage;

  ExploreProvider({required List<PackageService> sources}) : _sources = sources;

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
        merged.addAll(await source.getExploreApps());
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
      final existing = byId[app.id];
      if (existing == null || app.popularityScore > existing.popularityScore) {
        byId[app.id] = app;
      }
    }

    final deduped = byId.values.toList()
      ..sort((left, right) {
        final popularityComparison = right.popularityScore.compareTo(left.popularityScore);
        if (popularityComparison != 0) {
          return popularityComparison;
        }
        return left.name.toLowerCase().compareTo(right.name.toLowerCase());
      });

    return deduped;
  }
}
