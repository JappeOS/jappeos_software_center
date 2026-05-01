import 'dart:convert';
import 'dart:io';

import '../../models/app_detail_model.dart';
import '../../models/app_model.dart';
import '../../models/install_state.dart';
import '../../models/update_model.dart';
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
  String get sourceId => 'pacman';

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
  Future<AppDetailModel?> getAppDetails(String id) async {
    final result = await _runInfoCommand(id);
    if (result == null) {
      return null;
    }

    final fields = _parseKeyValueOutput(result.stdout);
    if (fields.isEmpty) {
      return null;
    }

    final name = fields['Name']?.trim();
    if (name == null || name.isEmpty) {
      return null;
    }

    final description = fields['Description']?.trim() ?? 'Pacman package';
    final url = fields['URL']?.trim();
    final installDate = _parsePacmanDate(fields['Install Date']);
    final buildDate = _parsePacmanDate(fields['Build Date']);
    final installedSize = _parsePacmanSize(fields['Installed Size']);
    final downloadSize = _parsePacmanSize(fields['Download Size']);
    final licenses = fields['Licenses']?.trim();
    final version = fields['Version']?.trim();
    final repository = fields['Repository']?.trim();
    final packager = fields['Packager']?.trim();
    final arch = fields['Architecture']?.trim();

    final links = <AppLink>[];
    if (url != null && url.isNotEmpty) {
      links.add(AppLink(label: 'Project Website', url: url));
    }

    final extraInfo = <String, String>{};
    _addIfPresent(extraInfo, 'Repository', repository);
    _addIfPresent(extraInfo, 'Architecture', arch);
    _addIfPresent(extraInfo, 'Packager', packager);
    _addIfPresent(extraInfo, 'Build Date', fields['Build Date']);
    _addIfPresent(extraInfo, 'Install Date', fields['Install Date']);
    _addIfPresent(extraInfo, 'Depends On', fields['Depends On']);
    _addIfPresent(extraInfo, 'Optional Deps', fields['Optional Deps']);
    _addIfPresent(extraInfo, 'Required By', fields['Required By']);

    return AppDetailModel(
      app: AppModel(
        id: id,
        name: name,
        description: description,
        icon: name,
        backend: 'pacman',
        installState: InstallState.installed,
        version: version == null || version.isEmpty ? null : version,
      ),
      sourceLabel: repository == null || repository.isEmpty
          ? 'Pacman'
          : 'Pacman ($repository)',
      sourceKey: 'pacman',
      longDescription: description,
      developer: packager == null || packager.isEmpty ? null : packager,
      license: licenses == null || licenses.isEmpty ? null : licenses,
      ageRating: null,
      downloadCount: null,
      installedSizeBytes: installedSize,
      downloadSizeBytes: downloadSize,
      installDate: installDate ?? buildDate,
      screenshots: const [],
      links: links,
      extraInfo: extraInfo,
    );
  }

  @override
  Future<List<UpdateModel>> getAvailableUpdates() async {
    CommandResult listResult;
    try {
      listResult = await _commandRunner.run(
        'pacman',
        ['-Qu'],
        timeout: _defaultTimeout,
        environment: const {'LC_ALL': 'C'},
      );
    } on CommandStartException {
      return const [];
    }

    if (!listResult.success) {
      if (listResult.stdout.trim().isEmpty && listResult.stderr.trim().isEmpty) {
        return const [];
      }
      throw PacmanServiceException(
        'pacman -Qu failed (exit ${listResult.exitCode}): ${listResult.stderr}',
      );
    }

    final packageNames = _parsePacmanUpdateNames(listResult.stdout);
    if (packageNames.isEmpty) {
      return const [];
    }

    final updates = <UpdateModel>[];
    var totalSize = 0;
    var sizedCount = 0;

    for (final chunk in _chunk(packageNames, 80)) {
      final infoResult = await _commandRunner.run(
        'pacman',
        ['-Si', ...chunk],
        timeout: _defaultTimeout,
        environment: const {'LC_ALL': 'C'},
      );
      if (!infoResult.success) {
        continue;
      }
      final infoByName = _parseSyncInfo(infoResult.stdout);
      for (final package in chunk) {
        final info = infoByName[package];
        final size = _parsePacmanSize(info?['Download Size']);
        if (size != null) {
          totalSize += size;
          sizedCount++;
        }
        updates.add(
          UpdateModel(
            id: 'pacman:$package',
            name: package,
            description: info?['Description']?.trim().isNotEmpty == true
                ? info!['Description']!.trim()
                : 'Pacman package update',
            icon: package,
            sourceKey: 'pacman',
            appId: package,
            downloadSizeBytes: size,
            version: info?['Version']?.trim(),
            isSystem: false,
            app: null,
          ),
        );
      }
    }

    updates.insert(
      0,
      UpdateModel(
        id: 'pacman:__system__',
        name: 'System Updates',
        description: '${packageNames.length} package updates available',
        icon: '',
        sourceKey: 'pacman',
        appId: '__all__',
        downloadSizeBytes: sizedCount > 0 ? totalSize : null,
        version: null,
        isSystem: true,
        app: null,
      ),
    );

    return updates;
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
      final args = ['pacman'];
      if (id == '__all__') {
        args.addAll(['-Syu', '--noconfirm']);
      } else {
        args.addAll(['-S', '--noconfirm', id]);
      }
      result = await _commandRunner.run(
        'pkexec',
        args,
        timeout: const Duration(minutes: 10),
      );
    } on CommandStartException {
      throw PacmanServiceException(
        'Pacman (or pkexec) is not available on this system.',
      );
    }

    if (!result.success) {
      throw PacmanServiceException('Failed to update "$id": ${result.stderr}');
    }
  }

  @override
  Future<void> open(String id) async {
    final launchCandidates = <List<String>>[
      ['gtk-launch', id],
      ['setsid', id],
    ];

    var lastError = '';
    for (final candidate in launchCandidates) {
      try {
        final result = await Process.run(
          candidate.first,
          candidate.sublist(1),
          runInShell: false,
        );
        if (result.exitCode == 0) {
          return;
        }
        lastError = result.stderr.toString().trim();
      } on ProcessException catch (error) {
        lastError = error.message;
      }
    }

    throw PacmanServiceException(
      'Failed to open "$id"${lastError.isEmpty ? '' : ': $lastError'}',
    );
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
          icon: name,
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

  Future<CommandResult?> _runInfoCommand(String id) async {
    CommandResult result;
    try {
      result = await _commandRunner.run(
        'pacman',
        ['-Qi', id],
        timeout: _defaultTimeout,
        environment: const {'LC_ALL': 'C'},
      );
    } on CommandStartException {
      return null;
    }

    if (result.success) {
      return result;
    }

    final syncResult = await _commandRunner.run(
      'pacman',
      ['-Si', id],
      timeout: _defaultTimeout,
      environment: const {'LC_ALL': 'C'},
    );
    if (!syncResult.success) {
      return null;
    }
    return syncResult;
  }

  Map<String, String> _parseKeyValueOutput(String stdout) {
    final values = <String, String>{};
    String? currentKey;

    for (final line in const LineSplitter().convert(stdout)) {
      if (line.trim().isEmpty) {
        currentKey = null;
        continue;
      }

      final separatorIndex = line.indexOf(':');
      if (separatorIndex <= 0) {
        if (currentKey != null) {
          final nextValue = line.trim();
          if (nextValue.isNotEmpty) {
            values[currentKey] = '${values[currentKey]} $nextValue'.trim();
          }
        }
        continue;
      }

      currentKey = line.substring(0, separatorIndex).trim();
      values[currentKey] = line.substring(separatorIndex + 1).trim();
    }

    return values;
  }

  int? _parsePacmanSize(String? raw) {
    if (raw == null) {
      return null;
    }
    final match = RegExp(r'([0-9]+(?:\.[0-9]+)?)\s*([KMGTP]?i?B)', caseSensitive: false).firstMatch(raw);
    if (match == null) {
      return null;
    }

    final number = double.tryParse(match.group(1)!);
    if (number == null) {
      return null;
    }

    final unit = match.group(2)!.toUpperCase();
    const factors = <String, int>{
      'B': 1,
      'KB': 1000,
      'MB': 1000 * 1000,
      'GB': 1000 * 1000 * 1000,
      'TB': 1000 * 1000 * 1000 * 1000,
      'KIB': 1024,
      'MIB': 1024 * 1024,
      'GIB': 1024 * 1024 * 1024,
      'TIB': 1024 * 1024 * 1024 * 1024,
    };
    final factor = factors[unit];
    if (factor == null) {
      return null;
    }
    return (number * factor).round();
  }

  DateTime? _parsePacmanDate(String? raw) {
    if (raw == null || raw.trim().isEmpty || raw.trim() == 'Unknown') {
      return null;
    }

    return DateTime.tryParse(raw.trim());
  }

  void _addIfPresent(Map<String, String> target, String key, String? value) {
    if (value == null) {
      return;
    }
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == 'None') {
      return;
    }
    target[key] = trimmed;
  }

  List<String> _parsePacmanUpdateNames(String stdout) {
    final names = <String>[];
    for (final line in const LineSplitter().convert(stdout)) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      final name = trimmed.split(' ').first.trim();
      if (name.isNotEmpty) {
        names.add(name);
      }
    }
    return names;
  }

  Map<String, Map<String, String>> _parseSyncInfo(String stdout) {
    final packages = <String, Map<String, String>>{};
    Map<String, String> current = <String, String>{};
    String? currentName;

    void flush() {
      final name = currentName;
      if (name == null || name.isEmpty) {
        return;
      }
      packages[name] = Map<String, String>.from(current);
    }

    for (final line in const LineSplitter().convert(stdout)) {
      if (line.trim().isEmpty) {
        flush();
        current = <String, String>{};
        currentName = null;
        continue;
      }
      final sep = line.indexOf(':');
      if (sep <= 0) {
        continue;
      }
      final key = line.substring(0, sep).trim();
      final value = line.substring(sep + 1).trim();
      current[key] = value;
      if (key == 'Name') {
        currentName = value;
      }
    }
    flush();
    return packages;
  }
}
