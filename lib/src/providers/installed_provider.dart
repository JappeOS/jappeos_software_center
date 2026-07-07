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
import '../models/app_detail_model.dart';
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

  Future<List<AppDetailModel>> getAppDetails(String appId) async {
    final details = <AppDetailModel>[];
    final seen = <String>{};
    final installed = _apps.where((app) => app.id == appId).toList();

    for (final source in _sources) {
      try {
        var detail = await source.getAppDetails(appId);
        if (detail == null) {
          continue;
        }
        detail = _mergeInstalledValues(detail, installed);
        if (seen.add(detail.sourceKey)) {
          details.add(detail);
        }
      } catch (_) {
        // Ignore one source's detail failure to allow rendering from others.
      }
    }

    details.sort(
      (left, right) =>
          left.sourceLabel.toLowerCase().compareTo(
            right.sourceLabel.toLowerCase(),
          ),
    );
    return details;
  }

  Future<void> installApp({
    required String sourceKey,
    required String appId,
  }) async {
    final service = _serviceForSourceKey(sourceKey);
    await service.install(appId);
  }

  Future<void> uninstallApp({
    required String sourceKey,
    required String appId,
  }) async {
    final service = _serviceForSourceKey(sourceKey);
    await service.uninstall(appId);
  }

  Future<void> updateApp({
    required String sourceKey,
    required String appId,
  }) async {
    final service = _serviceForSourceKey(sourceKey);
    await service.update(appId);
  }

  Future<void> openAppBySource({
    required String sourceKey,
    required String appId,
  }) async {
    final service = _serviceForSourceKey(sourceKey);
    await service.open(appId);
  }

  AppDetailModel _mergeInstalledValues(
    AppDetailModel detail,
    List<AppModel> installedCandidates,
  ) {
    if (installedCandidates.isEmpty) {
      return detail;
    }

    AppModel? preferred;
    for (final app in installedCandidates) {
      if (_normalizeBackend(app.backend) == _normalizeBackend(detail.app.backend)) {
        preferred = app;
        break;
      }
    }
    preferred ??= installedCandidates.first;

    final current = detail.app;
    final merged = AppModel(
      id: current.id,
      name: _looksLikeAppId(current.name) ? preferred.name : current.name,
      description: current.description.trim().isEmpty
          ? preferred.description
          : current.description,
      icon: current.icon.trim().isEmpty ? preferred.icon : current.icon,
      backend: current.backend,
      installState: current.installState,
      version: (current.version == null || current.version!.trim().isEmpty)
          ? preferred.version
          : current.version,
    );

    return AppDetailModel(
      app: merged,
      sourceLabel: detail.sourceLabel,
      sourceKey: detail.sourceKey,
      longDescription: detail.longDescription,
      developer: detail.developer,
      license: detail.license,
      ageRating: detail.ageRating,
      downloadCount: detail.downloadCount,
      installedSizeBytes: detail.installedSizeBytes,
      downloadSizeBytes: detail.downloadSizeBytes,
      installDate: detail.installDate,
      screenshots: detail.screenshots,
      links: detail.links,
      extraInfo: detail.extraInfo,
    );
  }

  bool _looksLikeAppId(String value) {
    final trimmed = value.trim();
    if (!trimmed.contains('.')) {
      return false;
    }
    return RegExp(r'^[a-zA-Z0-9_-]+(\.[a-zA-Z0-9_-]+)+$').hasMatch(trimmed);
  }

  String _normalizeBackend(String backend) {
    final lower = backend.toLowerCase().trim();
    if (lower.startsWith('flatpak')) {
      return 'flatpak';
    }
    if (lower.startsWith('pacman')) {
      return 'pacman';
    }
    return lower;
  }

  PackageService _serviceForSourceKey(String sourceKey) {
    final sourcePrefix = sourceKey.split(':').first.toLowerCase().trim();
    for (final service in _sources) {
      if (service.sourceId.toLowerCase() == sourcePrefix) {
        return service;
      }
    }
    throw StateError('No package service found for source key "$sourceKey".');
  }

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
