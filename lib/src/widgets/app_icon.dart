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
  static final Map<String, String> _flatpakIconIndex = <String, String>{};

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
    final home = Platform.environment['HOME'];
    if (home != null && home.isNotEmpty) {
      await _scanFlatpakRoot('$home/.local/share/flatpak/app');
    }

    const extensions = ['png', 'jpg', 'jpeg', 'webp', 'svg'];
    for (final ext in extensions) {
      final key = '$name.$ext'.toLowerCase();
      final match = _flatpakIconIndex[key];
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

        final lower = path.toLowerCase();
        if (!(lower.endsWith('.png') ||
            lower.endsWith('.jpg') ||
            lower.endsWith('.jpeg') ||
            lower.endsWith('.webp') ||
            lower.endsWith('.svg'))) {
          continue;
        }

        final fileName = path.split('/').last.toLowerCase();
        _flatpakIconIndex.putIfAbsent(fileName, () => path);
      }
    } catch (_) {
      // Ignore permission/path failures and keep best-effort behavior.
    }
  }
}
