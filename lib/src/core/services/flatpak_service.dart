import 'dart:convert';
import 'dart:io';

import '../../models/app_detail_model.dart';
import '../../models/app_model.dart';
import '../../models/install_state.dart';
import '../../models/update_model.dart';
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
  String get sourceId => 'flatpak';

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
  Future<List<AppModel>> getExploreApps() async {
    final result = await _runFlatpakExploreList();
    if (result == null || !result.success || result.stdout.trim().isEmpty) {
      return const [];
    }

    final apps = <AppModel>[];
    final seenIds = <String>{};
    for (final line in const LineSplitter().convert(result.stdout)) {
      if (line.trim().isEmpty) {
        continue;
      }
      final columns = _splitColumns(line);
      final id = _column(columns, 0);
      if (id.isEmpty || seenIds.contains(id)) {
        continue;
      }
      final name = _column(columns, 1);
      final description = _column(columns, 2);
      final remaining = columns.length > 3 ? columns.sublist(3) : const <String>[];
      final iconHint = _pickIconHint(remaining);
      final popularity = _pickPopularity(remaining);
      apps.add(
        AppModel(
          id: id,
          name: name.isEmpty ? _nameFromId(id) : name,
          description: description.isEmpty
              ? 'No description available.'
              : description,
          icon: iconHint ?? id,
          backend: 'flatpak',
          installState: InstallState.notInstalled,
          version: null,
          popularityScore: popularity ?? 0,
        ),
      );
      seenIds.add(id);
    }

    return apps;
  }

  Future<CommandResult?> _runFlatpakExploreList() async {
    final commandVariants = <List<String>>[
      ['remote-ls', '--app', '--columns=application,name,description,download-size'],
      ['remote-ls', '--app', '--columns=application,name,description,icon'],
      ['remote-ls', '--app', '--columns=application,name,description'],
      ['remote-ls', '--app', '--columns=application,name'],
    ];

    for (final args in commandVariants) {
      try {
        final result = await _commandRunner.run(
          'flatpak',
          args,
          timeout: _defaultTimeout,
        );
        if (result.success && result.stdout.trim().isNotEmpty) {
          return result;
        }
      } on CommandStartException {
        return null;
      }
    }

    return null;
  }

  @override
  Future<AppDetailModel?> getAppDetails(String id) async {
    final resolved = await _resolveFlatpakMetadata(id);
    if (resolved == null) {
      return null;
    }

    final metadata = _parseFlatpakMetadata(resolved.metadata);
    if (metadata.isEmpty) {
      return null;
    }

    final appSection = metadata['Application'] ?? const <String, String>{};
    final contextSection = metadata['Context'] ?? const <String, String>{};
    final remoteInfo = resolved.isInstalled
        ? null
        : await _loadRemoteInfoFields(resolved.origin, id);

    final appIdFromMetadata = _firstNonEmpty([
      appSection['id'],
      remoteInfo?['ID'],
      id,
    ]);
    final appId = _normalizeFlatpakAppId(appIdFromMetadata ?? id);

    final rawName = _firstNonEmpty([
      appSection['name'],
      remoteInfo?['Name'],
      _summaryName(remoteInfo?['SummaryLine']),
      _nameFromId(appId),
      remoteInfo?['ID'],
    ]);
    final name = _displayNameFromRaw(rawName, appId);
    final description = _firstNonEmpty([
      appSection['comment'],
      remoteInfo?['Comment'],
      remoteInfo?['Description'],
    ]);
    final version = appSection['version']?.trim();
    final license = appSection['project_license']?.trim();
    final developer = appSection['developer_name']?.trim();
    final homepage = appSection['homepage']?.trim();
    final issueTracker = appSection['bugtracker']?.trim();
    final help = appSection['help']?.trim();

    final originFromMetadata = appSection['origin']?.trim();
    final origin = (originFromMetadata != null && originFromMetadata.isNotEmpty)
        ? originFromMetadata
        : resolved.origin;
    final sourceLabel = origin == null || origin.isEmpty
        ? 'Flatpak'
        : 'Flatpak ($origin)';

    final links = <AppLink>[];
    _addLinkIfValid(links, 'Project Website', homepage);
    _addLinkIfValid(links, 'Issue Tracker', issueTracker);
    _addLinkIfValid(links, 'Help', help);

    final screenshots = <String>[];
    for (final entry in appSection.entries) {
      if (!entry.key.startsWith('screenshots')) {
        continue;
      }
      for (final value in entry.value.split(';')) {
        final trimmed = value.trim();
        if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
          screenshots.add(trimmed);
        }
      }
    }

    final extraInfo = <String, String>{};
    _addIfPresent(extraInfo, 'Runtime', appSection['runtime']);
    _addIfPresent(extraInfo, 'Sdk', appSection['sdk']);
    _addIfPresent(extraInfo, 'Command', appSection['command']);
    _addIfPresent(extraInfo, 'Required Devices', contextSection['devices']);
    _addIfPresent(extraInfo, 'Filesystem Access', contextSection['filesystems']);
    _addIfPresent(extraInfo, 'Network Access', contextSection['shared']);

    return AppDetailModel(
      app: AppModel(
        id: appId,
        name: name,
        description: description == null || description.isEmpty
            ? 'No description available.'
            : description,
        icon: appId,
        backend: sourceLabel,
        installState: resolved.isInstalled
            ? InstallState.installed
            : InstallState.notInstalled,
        version: version == null || version.isEmpty ? null : version,
      ),
      sourceLabel: sourceLabel,
      sourceKey: 'flatpak:${origin ?? ''}',
      longDescription: appSection['description']?.trim().isNotEmpty == true
          ? appSection['description']!.trim()
          : (description?.isNotEmpty == true
                ? description!
                : 'No long description available.'),
      developer: developer == null || developer.isEmpty ? null : developer,
      license: license == null || license.isEmpty ? null : license,
      ageRating: appSection['content_rating']?.trim(),
      downloadCount: null,
      installedSizeBytes: null,
      downloadSizeBytes: null,
      installDate: null,
      screenshots: screenshots,
      links: links,
      extraInfo: extraInfo,
    );
  }

  Future<Map<String, String>?> _loadRemoteInfoFields(String? remote, String id) async {
    if (remote == null || remote.isEmpty) {
      return null;
    }
    try {
      final result = await _commandRunner.run('flatpak', [
        'remote-info',
        remote,
        id,
      ], timeout: _defaultTimeout);
      if (!result.success || result.stdout.trim().isEmpty) {
        return null;
      }
      final fields = _parseColonFields(result.stdout);
      final lines = const LineSplitter().convert(result.stdout);
      if (lines.isNotEmpty) {
        final headline = lines.first.trim();
        if (headline.isNotEmpty) {
          fields.putIfAbsent('SummaryLine', () => headline);
        }
      }
      return fields.isEmpty ? null : fields;
    } on CommandStartException {
      return null;
    }
  }

  Future<_ResolvedFlatpakMetadata?> _resolveFlatpakMetadata(String id) async {
    try {
      final installedResult = await _commandRunner.run('flatpak', [
        'info',
        '--show-metadata',
        id,
      ], timeout: _defaultTimeout);
      if (installedResult.success && installedResult.stdout.trim().isNotEmpty) {
        return _ResolvedFlatpakMetadata(
          metadata: installedResult.stdout,
          origin: null,
          isInstalled: true,
        );
      }
    } on CommandStartException {
      return null;
    }

    final remotes = await _listFlatpakRemotes();
    for (final remote in remotes) {
      try {
        final remoteResult = await _commandRunner.run('flatpak', [
          'remote-info',
          '--show-metadata',
          remote,
          id,
        ], timeout: _defaultTimeout);
        if (!remoteResult.success || remoteResult.stdout.trim().isEmpty) {
          continue;
        }
        return _ResolvedFlatpakMetadata(
          metadata: remoteResult.stdout,
          origin: remote,
          isInstalled: false,
        );
      } on CommandStartException {
        return null;
      }
    }
    return null;
  }

  Future<List<String>> _listFlatpakRemotes() async {
    try {
      final result = await _commandRunner.run('flatpak', [
        'remotes',
        '--columns=name',
      ], timeout: _defaultTimeout);
      if (!result.success || result.stdout.trim().isEmpty) {
        return const [];
      }
      final remotes = <String>[];
      for (final line in const LineSplitter().convert(result.stdout)) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.toLowerCase() == 'name') {
          continue;
        }
        remotes.add(trimmed);
      }
      return remotes;
    } on CommandStartException {
      return const [];
    }
  }

  @override
  Future<List<UpdateModel>> getAvailableUpdates() async {
    CommandResult result;
    try {
      result = await _commandRunner.run('flatpak', [
        'remote-ls',
        '--updates',
        '--app',
        '--columns=application,name,version,download-size',
      ], timeout: _defaultTimeout);
    } on CommandStartException {
      return const [];
    }

    if (!result.success || result.stdout.trim().isEmpty) {
      return const [];
    }

    final updates = <UpdateModel>[];
    for (final line in const LineSplitter().convert(result.stdout)) {
      if (line.trim().isEmpty) {
        continue;
      }
      final columns = line.split('\t');
      final appId = _column(columns, 0);
      if (appId.isEmpty) {
        continue;
      }
      final name = _column(columns, 1);
      final version = _nullableColumn(columns, 2);
      final downloadSize = _parseByteCount(_column(columns, 3));
      updates.add(
        UpdateModel(
          id: 'flatpak:$appId',
          name: name.isEmpty ? _nameFromId(appId) : name,
          description: 'Flatpak application update',
          icon: appId,
          sourceKey: 'flatpak',
          appId: appId,
          downloadSizeBytes: downloadSize,
          version: version,
          isSystem: false,
          app: null,
        ),
      );
    }
    return updates;
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
      final args = ['update', '-y'];
      if (id != '__all__') {
        args.add(id);
      }
      result = await _commandRunner.run('flatpak', args, timeout: _defaultTimeout);
    } on CommandStartException {
      throw FlatpakServiceException('Flatpak is not available on this system.');
    }

    if (!result.success) {
      throw FlatpakServiceException('Failed to update "$id": ${result.stderr}');
    }
  }

  @override
  Future<void> open(String id) async {
    try {
      final result = await Process.run('setsid', ['flatpak', 'run', id], runInShell: false);
      if (result.exitCode != 0) {
        throw FlatpakServiceException(
          'Failed to open "$id": ${result.stderr.toString().trim()}',
        );
      }
    } on ProcessException catch (error) {
      throw FlatpakServiceException(
        'Failed to open "$id": ${error.message}',
      );
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
          icon: id,
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

  List<String> _splitColumns(String line) {
    if (line.contains('\t')) {
      return line.split('\t');
    }
    // Some Flatpak versions print aligned columns with spaces instead of tabs.
    return line.split(RegExp(r'\s{2,}'));
  }

  String? _pickIconHint(List<String> remainingColumns) {
    for (final raw in remainingColumns) {
      final value = raw.trim();
      if (value.isEmpty) {
        continue;
      }
      final lower = value.toLowerCase();
      if (lower.startsWith('http://') ||
          lower.startsWith('https://') ||
          lower.startsWith('/') ||
          lower.endsWith('.png') ||
          lower.endsWith('.svg') ||
          lower.endsWith('.jpg') ||
          lower.endsWith('.jpeg') ||
          lower.endsWith('.webp')) {
        return value;
      }
    }
    return null;
  }

  double? _pickPopularity(List<String> remainingColumns) {
    for (final raw in remainingColumns.reversed) {
      final value = raw.trim().replaceAll(',', '');
      if (value.isEmpty) {
        continue;
      }
      final parsed = double.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
      final bytes = _parseByteCount(value);
      if (bytes != null) {
        return bytes.toDouble();
      }
    }
    return null;
  }

  String _nameFromId(String id) {
    final parts = id.split('.');
    if (parts.isEmpty) {
      return id;
    }

    return parts.last;
  }

  String _displayNameFromRaw(String? rawName, String appId) {
    final trimmed = rawName?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return _nameFromId(appId);
    }
    if (trimmed == appId) {
      return _nameFromId(appId);
    }
    return trimmed;
  }

  String _normalizeFlatpakAppId(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }
    if (trimmed.startsWith('app/') || trimmed.startsWith('runtime/')) {
      final parts = trimmed.split('/');
      if (parts.length >= 2 && parts[1].trim().isNotEmpty) {
        return parts[1].trim();
      }
    }
    return trimmed;
  }

  String? _summaryName(String? summaryLine) {
    if (summaryLine == null) {
      return null;
    }
    final trimmed = summaryLine.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final separator = trimmed.indexOf(' - ');
    if (separator <= 0) {
      return null;
    }
    final maybeName = trimmed.substring(0, separator).trim();
    return maybeName.isEmpty ? null : maybeName;
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return null;
  }

  Map<String, String> _parseColonFields(String stdout) {
    final fields = <String, String>{};
    for (final line in const LineSplitter().convert(stdout)) {
      final separator = line.indexOf(':');
      if (separator <= 0) {
        continue;
      }
      final key = line.substring(0, separator).trim();
      final value = line.substring(separator + 1).trim();
      if (key.isEmpty || value.isEmpty) {
        continue;
      }
      fields[key] = value;
      if (key.startsWith('Name')) {
        fields.putIfAbsent('Name', () => value);
      } else if (key.startsWith('Comment')) {
        fields.putIfAbsent('Comment', () => value);
      } else if (key.startsWith('Description')) {
        fields.putIfAbsent('Description', () => value);
      } else if (key.startsWith('ID')) {
        fields.putIfAbsent('ID', () => value);
      }
    }
    return fields;
  }

  Map<String, Map<String, String>> _parseFlatpakMetadata(String stdout) {
    final sections = <String, Map<String, String>>{};
    String currentSection = '';

    for (final line in const LineSplitter().convert(stdout)) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) {
        continue;
      }

      if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
        currentSection = trimmed.substring(1, trimmed.length - 1).trim();
        sections.putIfAbsent(currentSection, () => <String, String>{});
        continue;
      }

      final separator = trimmed.indexOf('=');
      if (separator <= 0) {
        continue;
      }
      final key = trimmed.substring(0, separator).trim();
      final value = trimmed.substring(separator + 1).trim();
      sections.putIfAbsent(currentSection, () => <String, String>{})[key] =
          value;
    }

    return sections;
  }

  void _addIfPresent(Map<String, String> map, String key, String? value) {
    if (value == null || value.trim().isEmpty) {
      return;
    }
    map[key] = value.trim();
  }

  void _addLinkIfValid(List<AppLink> links, String label, String? value) {
    if (value == null) {
      return;
    }
    final trimmed = value.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      links.add(AppLink(label: label, url: trimmed));
    }
  }

  int? _parseByteCount(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      return null;
    }
    final match = RegExp(
      r'([0-9]+(?:\.[0-9]+)?)\s*([KMGTP]?i?B)',
      caseSensitive: false,
    ).firstMatch(value);
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
}

class _ResolvedFlatpakMetadata {
  final String metadata;
  final String? origin;
  final bool isInstalled;

  const _ResolvedFlatpakMetadata({
    required this.metadata,
    required this.origin,
    required this.isInstalled,
  });
}
