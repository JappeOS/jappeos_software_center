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

import 'dart:io';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class AppIcon extends StatefulWidget {
  final String? icon;
  final double size;

  const AppIcon({super.key, required this.icon, this.size = 30});

  @override
  State<AppIcon> createState() => _AppIconState();
}

class _AppIconState extends State<AppIcon> {
  Future<String?>? _resolved;

  @override
  void initState() {
    super.initState();
    _resolved = _IconResolver.resolve(widget.icon);
  }

  @override
  void didUpdateWidget(covariant AppIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.icon != widget.icon) {
      _resolved = _IconResolver.resolve(widget.icon);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _resolved,
      builder: (context, snapshot) {
        final resolved = snapshot.data;
        if (resolved == null || resolved.isEmpty) {
          return _fallback();
        }

        if (resolved.startsWith('http://') || resolved.startsWith('https://')) {
          if (_isSvgPath(resolved)) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SvgPicture.network(
                resolved,
                width: widget.size,
                height: widget.size,
                fit: BoxFit.contain,
                placeholderBuilder: (context) => _fallback(),
              ),
            );
          }
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              resolved,
              width: widget.size,
              height: widget.size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _fallback(),
            ),
          );
        }

        if (_isSvgPath(resolved)) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SvgPicture.file(
              File(resolved),
              width: widget.size,
              height: widget.size,
              fit: BoxFit.contain,
              placeholderBuilder: (context) => _fallback(),
            ),
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(resolved),
            width: widget.size,
            height: widget.size,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _fallback(),
          ),
        );
      },
    );
  }

  Widget _fallback() {
    return SizedBox.square(
      dimension: widget.size,
      child: Icon(Icons.settings_applications, size: widget.size * 0.82),
    );
  }

  bool _isSvgPath(String path) {
    return path.toLowerCase().endsWith('.svg');
  }
}

class _IconResolver {
  static final Map<String, String?> _cache = <String, String?>{};
  static final Set<String> _scannedFlatpakRoots = <String>{};
  static final Set<String> _scannedFlatpakAppstreamRoots = <String>{};
  static final Map<String, String> _flatpakIconIndex = <String, String>{};
  static bool _desktopIndexBuilt = false;
  static final Map<String, String> _desktopIconByToken = <String, String>{};

  static Future<String?> resolve(String? rawIcon) async {
    final icon = rawIcon?.trim() ?? '';
    if (icon.isEmpty) {
      return null;
    }

    final cached = _cache[icon];
    if (cached != null || _cache.containsKey(icon)) {
      return cached;
    }

    if (_isRemote(icon)) {
      _cache[icon] = icon;
      return icon;
    }

    if (_isAbsolute(icon) && await File(icon).exists()) {
      _cache[icon] = icon;
      return icon;
    }

    final direct = await _firstExisting(_directCandidates(icon));
    if (direct != null) {
      _cache[icon] = direct;
      return direct;
    }

    final named = await _firstExisting(_nameCandidates(icon));
    if (named != null) {
      _cache[icon] = named;
      return named;
    }

    final flatpakTreeIcon = await _findFlatpakAppIcon(icon);
    if (flatpakTreeIcon != null) {
      _cache[icon] = flatpakTreeIcon;
      return flatpakTreeIcon;
    }

    final desktopIcon = await _findDesktopIcon(icon);
    if (desktopIcon != null) {
      final resolvedDesktopIcon = await resolve(desktopIcon);
      _cache[icon] = resolvedDesktopIcon;
      return resolvedDesktopIcon;
    }

    _cache[icon] = null;
    return null;
  }

  static bool _isRemote(String input) {
    return input.startsWith('http://') || input.startsWith('https://');
  }

  static bool _isAbsolute(String input) {
    return input.startsWith('/');
  }

  static List<String> _directCandidates(String icon) {
    final lower = icon.toLowerCase();
    if (lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.svg') ||
        lower.endsWith('.webp')) {
      return [icon];
    }
    return [];
  }

  static List<String> _nameCandidates(String name) {
    const sizes = ['512x512', '256x256', '128x128', '64x64', '48x48', '32x32'];
    const extensions = ['png', 'jpg', 'jpeg', 'webp', 'svg'];
    const bases = [
      '/usr/share/pixmaps',
      '/usr/share/icons/hicolor',
      '/var/lib/flatpak/exports/share/icons/hicolor',
    ];

    final home = Platform.environment['HOME'];
    final userBase = home == null
        ? const <String>[]
        : <String>[
            '$home/.local/share/flatpak/exports/share/icons/hicolor',
          ];

    final candidates = <String>[];

    for (final ext in extensions) {
      candidates.add('/usr/share/pixmaps/$name.$ext');
      if (home != null) {
        candidates.add('$home/.local/share/icons/hicolor/256x256/apps/$name.$ext');
      }
    }

    for (final base in [...bases, ...userBase]) {
      for (final ext in extensions) {
        candidates.add('$base/scalable/apps/$name.$ext');
        candidates.add('$base/symbolic/apps/$name.$ext');
      }
      for (final size in sizes) {
        for (final ext in extensions) {
          candidates.add('$base/$size/apps/$name.$ext');
          candidates.add('$base/$size@2/apps/$name.$ext');
        }
      }
    }

    return candidates;
  }

  static Future<String?> _firstExisting(List<String> paths) async {
    for (final path in paths) {
      try {
        if (await File(path).exists()) {
          return path;
        }
      } catch (_) {
        // Ignore bad paths and continue.
      }
    }
    return null;
  }

  static Future<String?> _findFlatpakAppIcon(String name) async {
    await _scanFlatpakRoot('/var/lib/flatpak/app');
    await _scanFlatpakAppstreamRoot('/var/lib/flatpak/appstream');
    final home = Platform.environment['HOME'];
    if (home != null && home.isNotEmpty) {
      await _scanFlatpakRoot('$home/.local/share/flatpak/app');
      await _scanFlatpakAppstreamRoot('$home/.local/share/flatpak/appstream');
    }

    final direct = _flatpakIconIndex[name.toLowerCase()];
    if (direct != null) {
      return direct;
    }

    const extensions = ['png', 'jpg', 'jpeg', 'webp', 'svg'];
    for (final candidate in <String>[
      ...extensions.map((ext) => '$name.$ext'),
      ...extensions.map((ext) => '$name-symbolic.$ext'),
    ]) {
      final match = _flatpakIconIndex[candidate.toLowerCase()];
      if (match != null) {
        return match;
      }
    }
    return null;
  }

  static Future<void> _scanFlatpakRoot(String rootPath) async {
    if (_scannedFlatpakRoots.contains(rootPath)) {
      return;
    }
    _scannedFlatpakRoots.add(rootPath);

    final root = Directory(rootPath);
    if (!await root.exists()) {
      return;
    }

    try {
      await for (final entity in root.list(recursive: true, followLinks: false)) {
        if (entity is! File) {
          continue;
        }
        final path = entity.path;
        if (!path.contains('/files/share/icons/')) {
          continue;
        }
        _indexIconFile(entity);
      }
    } catch (_) {
      // Ignore permission/path failures and keep best-effort behavior.
    }
  }

  static Future<void> _scanFlatpakAppstreamRoot(String rootPath) async {
    if (_scannedFlatpakAppstreamRoots.contains(rootPath)) {
      return;
    }
    _scannedFlatpakAppstreamRoots.add(rootPath);

    final root = Directory(rootPath);
    if (!await root.exists()) {
      return;
    }

    try {
      await for (final entity in root.list(recursive: true, followLinks: false)) {
        if (entity is! File) {
          continue;
        }
        final path = entity.path;
        if (!path.contains('/icons/')) {
          continue;
        }
        _indexIconFile(entity);
      }
    } catch (_) {
      // Ignore permission/path failures and keep best-effort behavior.
    }
  }

  static void _indexIconFile(File entity) {
    final path = entity.path;
    final lower = path.toLowerCase();
    if (!(lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.svg'))) {
      return;
    }

    final fileName = path.split('/').last.toLowerCase();
    _flatpakIconIndex.putIfAbsent(fileName, () => path);
  }

  static Future<String?> _findDesktopIcon(String hint) async {
    await _buildDesktopIndex();
    final normalized = hint.toLowerCase();
    return _desktopIconByToken[normalized];
  }

  static Future<void> _buildDesktopIndex() async {
    if (_desktopIndexBuilt) {
      return;
    }
    _desktopIndexBuilt = true;

    final home = Platform.environment['HOME'];
    final desktopDirs = <String>[
      '/usr/share/applications',
      '/var/lib/flatpak/exports/share/applications',
      if (home != null) '$home/.local/share/applications',
      if (home != null) '$home/.local/share/flatpak/exports/share/applications',
    ];

    for (final dirPath in desktopDirs) {
      final dir = Directory(dirPath);
      if (!await dir.exists()) {
        continue;
      }

      try {
        await for (final entity in dir.list(recursive: false, followLinks: false)) {
          if (entity is! File || !entity.path.endsWith('.desktop')) {
            continue;
          }
          final content = await entity.readAsString();
          final icon = _desktopValue(content, 'Icon');
          if (icon == null || icon.trim().isEmpty) {
            continue;
          }
          final iconValue = icon.trim();

          final filename = entity.path.split('/').last.replaceAll('.desktop', '').toLowerCase();
          _desktopIconByToken.putIfAbsent(filename, () => iconValue);

          final name = _desktopValue(content, 'Name');
          if (name != null && name.trim().isNotEmpty) {
            _desktopIconByToken.putIfAbsent(name.trim().toLowerCase(), () => iconValue);
          }

          final exec = _desktopValue(content, 'Exec');
          if (exec != null && exec.trim().isNotEmpty) {
            final first = exec.trim().split(' ').first;
            final execName = first.split('/').last.trim().toLowerCase();
            if (execName.isNotEmpty) {
              _desktopIconByToken.putIfAbsent(execName, () => iconValue);
            }
          }
        }
      } catch (_) {
        // Best effort index; ignore failures.
      }
    }
  }

  static String? _desktopValue(String content, String key) {
    final pattern = RegExp('^$key=(.+)\$', multiLine: true);
    final match = pattern.firstMatch(content);
    if (match == null) {
      return null;
    }
    return match.group(1);
  }
}
