import 'dart:convert';

import '../../models/app_model.dart';
import '../../models/install_state.dart';
import 'command_runner.dart';
import 'package_service.dart';

class FlatpakServiceException implements Exception {
  final String message;

  FlatpakServiceException(this.message);

  @override
  String toString() => message;
}

class FlatpakService implements PackageService {
  static const _defaultTimeout = Duration(seconds: 20);

  final CommandRunner _commandRunner;

  FlatpakService({required CommandRunner commandRunner})
    : _commandRunner = commandRunner;

  @override
  Future<List<AppModel>> getInstalledApps() async {
    CommandResult result;
    try {
      result = await _commandRunner.run('flatpak', [
        'list',
        '--app',
        '--columns=application,name,description,version,origin',
      ], timeout: _defaultTimeout);
    } on CommandStartException {
      // Flatpak is not installed on this system; treat as an unavailable backend.
      return const [];
    }

    if (!result.success) {
      final stderr = result.stderr.isNotEmpty ? result.stderr : result.stdout;
      throw FlatpakServiceException(
        'flatpak list failed (exit ${result.exitCode}): $stderr',
      );
    }

    return _parseFlatpakApps(result.stdout);
  }

  @override
  Future<void> install(String id) async {
    CommandResult result;
    try {
      result = await _commandRunner.run('flatpak', [
        'install',
        '-y',
        id,
      ], timeout: _defaultTimeout);
    } on CommandStartException {
      throw FlatpakServiceException('Flatpak is not available on this system.');
    }

    if (!result.success) {
      throw FlatpakServiceException(
        'Failed to install "$id": ${result.stderr}',
      );
    }
  }

  @override
  Future<void> uninstall(String id) async {
    CommandResult result;
    try {
      result = await _commandRunner.run('flatpak', [
        'uninstall',
        '-y',
        id,
      ], timeout: _defaultTimeout);
    } on CommandStartException {
      throw FlatpakServiceException('Flatpak is not available on this system.');
    }

    if (!result.success) {
      throw FlatpakServiceException(
        'Failed to uninstall "$id": ${result.stderr}',
      );
    }
  }

  @override
  Future<void> update(String id) async {
    CommandResult result;
    try {
      result = await _commandRunner.run('flatpak', [
        'update',
        '-y',
        id,
      ], timeout: _defaultTimeout);
    } on CommandStartException {
      throw FlatpakServiceException('Flatpak is not available on this system.');
    }

    if (!result.success) {
      throw FlatpakServiceException('Failed to update "$id": ${result.stderr}');
    }
  }

  List<AppModel> _parseFlatpakApps(String stdout) {
    if (stdout.trim().isEmpty) {
      return const [];
    }

    final apps = <AppModel>[];
    final seenIds = <String>{};

    for (final line in const LineSplitter().convert(stdout)) {
      if (line.trim().isEmpty) {
        continue;
      }

      final columns = line.split('\t');
      final id = _column(columns, 0);

      if (id.isEmpty || seenIds.contains(id)) {
        continue;
      }

      final name = _column(columns, 1);
      final description = _column(columns, 2);
      final version = _nullableColumn(columns, 3);
      final origin = _column(columns, 4);

      apps.add(
        AppModel(
          id: id,
          name: name.isNotEmpty ? name : _nameFromId(id),
          description: description.isNotEmpty
              ? description
              : 'No description available.',
          icon: '',
          backend: origin.isNotEmpty ? 'flatpak:$origin' : 'flatpak',
          installState: InstallState.installed,
          version: version,
        ),
      );

      seenIds.add(id);
    }

    apps.sort(
      (left, right) =>
          left.name.toLowerCase().compareTo(right.name.toLowerCase()),
    );

    return apps;
  }

  String _column(List<String> columns, int index) {
    if (index >= columns.length) {
      return '';
    }
    return columns[index].trim();
  }

  String? _nullableColumn(List<String> columns, int index) {
    final value = _column(columns, index);
    return value.isEmpty ? null : value;
  }

  String _nameFromId(String id) {
    final parts = id.split('.');
    if (parts.isEmpty) {
      return id;
    }

    return parts.last;
  }
}
