import 'dart:convert';

import '../../models/app_model.dart';
import '../../models/install_state.dart';
import 'command_runner.dart';
import 'package_service.dart';

class PacmanServiceException implements Exception {
  final String message;

  PacmanServiceException(this.message);

  @override
  String toString() => message;
}

class PacmanService implements PackageService {
  static const _defaultTimeout = Duration(seconds: 30);

  final CommandRunner _commandRunner;

  PacmanService({required CommandRunner commandRunner})
    : _commandRunner = commandRunner;

  @override
  Future<List<AppModel>> getInstalledApps() async {
    CommandResult listResult;
    try {
      listResult = await _commandRunner.run(
        'pacman',
        ['-Qeq'],
        timeout: _defaultTimeout,
        environment: const {'LC_ALL': 'C'},
      );
    } on CommandStartException {
      // Pacman is unavailable on this system, so this source contributes no apps.
      return const [];
    }

    if (!listResult.success) {
      final stderr = listResult.stderr.isNotEmpty
          ? listResult.stderr
          : listResult.stdout;
      throw PacmanServiceException(
        'pacman -Qeq failed (exit ${listResult.exitCode}): $stderr',
      );
    }

    final packageNames = _parsePackageNames(listResult.stdout);
    if (packageNames.isEmpty) {
      return const [];
    }

    final apps = <AppModel>[];

    for (final chunk in _chunk(packageNames, 100)) {
      final infoResult = await _commandRunner.run(
        'pacman',
        ['-Qi', ...chunk],
        timeout: _defaultTimeout,
        environment: const {'LC_ALL': 'C'},
      );

      if (!infoResult.success) {
        final stderr = infoResult.stderr.isNotEmpty
            ? infoResult.stderr
            : infoResult.stdout;
        throw PacmanServiceException(
          'pacman -Qi failed (exit ${infoResult.exitCode}): $stderr',
        );
      }

      apps.addAll(_parsePackageInfo(infoResult.stdout));
    }

    apps.sort(
      (left, right) =>
          left.name.toLowerCase().compareTo(right.name.toLowerCase()),
    );

    return apps;
  }

  @override
  Future<void> install(String id) async {
    CommandResult result;
    try {
      result = await _commandRunner.run('pkexec', [
        'pacman',
        '-S',
        '--noconfirm',
        id,
      ], timeout: const Duration(minutes: 10));
    } on CommandStartException {
      throw PacmanServiceException(
        'Pacman (or pkexec) is not available on this system.',
      );
    }

    if (!result.success) {
      throw PacmanServiceException('Failed to install "$id": ${result.stderr}');
    }
  }

  @override
  Future<void> uninstall(String id) async {
    CommandResult result;
    try {
      result = await _commandRunner.run('pkexec', [
        'pacman',
        '-Rns',
        '--noconfirm',
        id,
      ], timeout: const Duration(minutes: 10));
    } on CommandStartException {
      throw PacmanServiceException(
        'Pacman (or pkexec) is not available on this system.',
      );
    }

    if (!result.success) {
      throw PacmanServiceException(
        'Failed to uninstall "$id": ${result.stderr}',
      );
    }
  }

  @override
  Future<void> update(String id) async {
    CommandResult result;
    try {
      result = await _commandRunner.run('pkexec', [
        'pacman',
        '-S',
        '--noconfirm',
        id,
      ], timeout: const Duration(minutes: 10));
    } on CommandStartException {
      throw PacmanServiceException(
        'Pacman (or pkexec) is not available on this system.',
      );
    }

    if (!result.success) {
      throw PacmanServiceException('Failed to update "$id": ${result.stderr}');
    }
  }

  List<String> _parsePackageNames(String stdout) {
    final names = <String>[];
    for (final line in const LineSplitter().convert(stdout)) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty) {
        names.add(trimmed);
      }
    }
    return names;
  }

  List<AppModel> _parsePackageInfo(String stdout) {
    final apps = <AppModel>[];

    String? currentName;
    String? currentVersion;
    String? currentDescription;

    void flushCurrent() {
      final name = currentName?.trim();
      if (name == null || name.isEmpty) {
        return;
      }

      apps.add(
        AppModel(
          id: name,
          name: name,
          description: (currentDescription ?? '').trim().isEmpty
              ? 'Pacman package'
              : currentDescription!.trim(),
          icon: '',
          backend: 'pacman',
          installState: InstallState.installed,
          version: (currentVersion ?? '').trim().isEmpty
              ? null
              : currentVersion!.trim(),
        ),
      );
    }

    for (final line in const LineSplitter().convert(stdout)) {
      if (line.trim().isEmpty) {
        flushCurrent();
        currentName = null;
        currentVersion = null;
        currentDescription = null;
        continue;
      }

      final separatorIndex = line.indexOf(':');
      if (separatorIndex <= 0) {
        continue;
      }

      final key = line.substring(0, separatorIndex).trim();
      final value = line.substring(separatorIndex + 1).trim();

      switch (key) {
        case 'Name':
          currentName = value;
          break;
        case 'Version':
          currentVersion = value;
          break;
        case 'Description':
          currentDescription = value;
          break;
      }
    }

    flushCurrent();
    return apps;
  }

  Iterable<List<T>> _chunk<T>(List<T> items, int chunkSize) sync* {
    var index = 0;
    while (index < items.length) {
      final end = (index + chunkSize < items.length)
          ? index + chunkSize
          : items.length;
      yield items.sublist(index, end);
      index = end;
    }
  }
}
