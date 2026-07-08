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

import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../models/app_model.dart';
import 'explore_provider.dart';

class SearchProvider extends ChangeNotifier {
  List<AppModel> _searchResult = const [];
  bool _isLoading = false;
  String _searchQuery = "";

  List<AppModel> get searchResult => _searchResult;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  Future<void> search(
    ExploreProvider exploreProvider,
    {String category = "",
    required String name,
  }) async {
    if (_isLoading) {
      return;
    }
    if (name.trim().isEmpty) {
      clear();
      return;
    }
    _isLoading = true;
    notifyListeners();
    try {
      await exploreProvider.loadIfNeeded();
      final apps = exploreProvider.apps;
      _searchQuery = name.trim();
      _searchResult = _performSearch(apps, name);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    if (_searchResult.isEmpty) {
      return;
    }
    _searchQuery = "";
    _searchResult = const [];
    notifyListeners();
  }

  List<AppModel> _performSearch(List<AppModel> apps, String search) {
    final results = apps
        .map((app) => (
              app: app,
              score: weightedRatio(search, app.name),
            ))
        .where((e) => e.score > 60)
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    final matchingApps = results.map((e) => e.app).toList();
    return matchingApps;
  }
}