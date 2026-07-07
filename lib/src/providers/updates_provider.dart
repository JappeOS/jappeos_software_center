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
import '../models/update_model.dart';

class UpdatesProvider extends ChangeNotifier {
  final List<PackageService> _sources;

  List<UpdateModel> _updates = const [];
  bool _isLoading = false;
  bool _hasLoaded = false;
  bool _isUpdatingAll = false;
  final Set<String> _currentUpdateIds = {};
  String? _errorMessage;

  UpdatesProvider({required List<PackageService> sources}) : _sources = sources;

  List<UpdateModel> get updates => _updates;
  bool get isLoading => _isLoading;
  bool get isUpdatingAll => _isUpdatingAll;
  Set<String> get currentUpdateIds => _currentUpdateIds;
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

    final merged = <UpdateModel>[];
    final errors = <String>[];

    for (final source in _sources) {
      try {
        merged.addAll(await source.getAvailableUpdates());
      } catch (error) {
        errors.add(error.toString());
      }
    }

    _updates = _sortUpdates(_dedupe(merged));
    _hasLoaded = true;
    _isLoading = false;
    _errorMessage = errors.isEmpty ? null : errors.join('\n');
    notifyListeners();
  }

  Future<void> updateById(String id) async {
    UpdateModel? update;
    for (final item in _updates) {
      if (item.id == id) {
        update = item;
        break;
      }
    }
    if (update == null) {
      throw StateError('Update item not found: $id');
    }

    _currentUpdateIds.add(id);
    try {
      await _serviceFor(update.sourceKey).update(update.appId);
    } finally {
      _currentUpdateIds.remove(id);
    }

    await refresh();
  }

  Future<void> updateAll() async {
    if (_isUpdatingAll) {
      return;
    }

    _isUpdatingAll = true;
    notifyListeners();
    try {
      for (final source in _sources) {
        await source.update('__all__');
      }
      await refresh();
    } finally {
      _isUpdatingAll = false;
      notifyListeners();
    }
  }

  List<UpdateModel> _dedupe(List<UpdateModel> updates) {
    final byId = <String, UpdateModel>{};
    for (final update in updates) {
      byId[update.id] = update;
    }
    return byId.values.toList();
  }

  List<UpdateModel> _sortUpdates(List<UpdateModel> updates) {
    updates.sort((left, right) {
      if (left.isSystem && !right.isSystem) {
        return -1;
      }
      if (!left.isSystem && right.isSystem) {
        return 1;
      }
      return left.name.toLowerCase().compareTo(right.name.toLowerCase());
    });
    return updates;
  }

  PackageService _serviceFor(String sourceKey) {
    final sourcePrefix = sourceKey.split(':').first.toLowerCase().trim();
    for (final source in _sources) {
      if (source.sourceId.toLowerCase() == sourcePrefix) {
        return source;
      }
    }
    throw StateError('No package source for: $sourceKey');
  }
}
