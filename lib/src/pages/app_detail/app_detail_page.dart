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

import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../models/app_detail_model.dart';
import '../../models/app_model.dart';
import '../../models/install_state.dart';
import '../../providers/explore_provider.dart';
import '../../providers/installed_provider.dart';
import '../../utils.dart';
import '../shared/page_base.dart';
import 'widgets/app_header.dart';
import 'widgets/install_button.dart';
import 'widgets/main_header_info_button.dart';
import 'widgets/screenshots_carousel.dart';

class AppDetailPage extends StatefulWidget {
  final String appId;

  const AppDetailPage({super.key, required this.appId});

  @override
  State<AppDetailPage> createState() => _AppDetailPageState();
}

class _AppDetailPageState extends State<AppDetailPage> {
  bool _isLoading = true;
  String? _error;
  List<AppDetailModel> _details = const [];
  int _selectedIndex = 0;
  bool _actionInProgress = false;
  String? _actionLabel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDetails();
    });
  }

  Future<void> _loadDetails() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final installedProvider = context.read<InstalledProvider>();
      await installedProvider.loadIfNeeded();
      final details = await installedProvider.getAppDetails(widget.appId);
      if (!mounted) {
        return;
      }

      setState(() {
        _details = details;
        _selectedIndex = 0;
        _isLoading = false;
        if (_details.isEmpty) {
          _error = 'No detail data is available from the current package sources.';
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final installedProvider = context.watch<InstalledProvider>();
    final exploreProvider = context.watch<ExploreProvider>();

    if (_isLoading) {
      return PageBase(
        itemCount: 1,
        itemBuilder: (_, _) => AppHeader(
          detail: _loadingDetail(widget.appId),
          sources: const ['Loading...'],
          onSourceChanged: (_) {},
          installButtonState: InstallButtonState.progress,
          progressText: 'Loading...',
        ),
      );
    }

    if (_error != null) {
      return PageBase(
        itemCount: 1,
        itemBuilder: (_, _) => OutlinedContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12 * theme.scaling,
            children: [
              Text('Failed to load app details').x2Large(),
              Text(_error!),
              PrimaryButton(
                onPressed: _loadDetails,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final selected = _details[_selectedIndex];
    final displayName = _resolveDisplayName(
      selected,
      exploreProvider.apps,
      installedProvider.apps,
    );
    final sources = _details.map((detail) => detail.sourceLabel).toList();
    final isInstalledByList = installedProvider.apps.any(
      (app) => _normalizeAppId(app.id) == _normalizeAppId(selected.app.id),
    );
    final isInstalled = isInstalledByList ||
        selected.app.installState == InstallState.installed;
    final installButtonState = _actionInProgress
        ? InstallButtonState.progress
        : (isInstalled ? InstallButtonState.installed : InstallButtonState.notInstalled);

    final children = [
      Gap(16 * theme.scaling),
      AppHeader(
        detail: _withDisplayName(selected, displayName),
        sources: sources,
        onSourceChanged: (source) {
          final index = sources.indexOf(source);
          if (index < 0) {
            return;
          }
          setState(() {
            _selectedIndex = index;
          });
        },
        installButtonState: installButtonState,
        progressText: _actionLabel,
        onInstallOrUpdate: _actionInProgress
            ? null
            : () => _performInstallOrUpdate(selected, isInstalled),
        onOpen: _actionInProgress ? null : () => _performOpen(selected),
        onUninstall: _actionInProgress ? null : () => _performUninstall(selected),
      ),
      Gap(16 * theme.scaling),
      Divider(),
      Gap(16 * theme.scaling),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          MainHeaderInfoButton(
            label: 'Installed Size',
            value: formatBytes(selected.installedSizeBytes),
          ),
          MainHeaderInfoButton(
            label: 'Age Rating',
            value: selected.ageRating?.isNotEmpty == true
                ? selected.ageRating!
                : 'Unknown',
          ),
          MainHeaderInfoButton(
            label: 'License',
            value: selected.license?.isNotEmpty == true
                ? selected.license!
                : 'Unknown',
          ),
          MainHeaderInfoButton(
            label: 'Downloads',
            value: formatDownloadCount(selected.downloadCount),
          ),
        ],
      ),
      Gap(16 * theme.scaling),
      if (selected.screenshots.isNotEmpty)
        IgnorePageBaseLayout(
          child: ScreenshotsCarousel(screenshots: selected.screenshots),
        ),
      Gap(16 * theme.scaling),
      Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16 * theme.scaling,
        children: [
          Flexible(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Description').x3Large(),
                Gap(8 * theme.scaling),
                Text(selected.longDescription, softWrap: true),
                Gap(16 * theme.scaling),
                if (selected.extraInfo.isNotEmpty) ...[
                  Text('Package Details').x2Large(),
                  Gap(8 * theme.scaling),
                  ...selected.extraInfo.entries.map(
                    (entry) => Text('${entry.key}: ${entry.value}'),
                  ),
                ],
              ],
            ),
          ),
          Flexible(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Gap(8 * theme.scaling),
                ..._buildLinkButtons(context, selected),
              ],
            ),
          ),
        ],
      ),
    ];

    return PageBase(
      itemCount: children.length,
      itemBuilder: (context, index) {
        return children[index];
      },
    );
  }

  Future<void> _performInstallOrUpdate(AppDetailModel selected, bool isInstalled) async {
    setState(() {
      _actionInProgress = true;
      _actionLabel = isInstalled ? 'Updating...' : 'Installing...';
    });

    try {
      final provider = context.read<InstalledProvider>();
      if (isInstalled) {
        await provider.updateApp(sourceKey: selected.sourceKey, appId: selected.app.id);
      } else {
        await provider.installApp(sourceKey: selected.sourceKey, appId: selected.app.id);
      }
      await provider.refresh();
      await _loadDetails();
    } catch (error) {
      _showActionError(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _actionInProgress = false;
          _actionLabel = null;
        });
      }
    }
  }

  Future<void> _performOpen(AppDetailModel selected) async {
    try {
      await context.read<InstalledProvider>().openAppBySource(
        sourceKey: selected.sourceKey,
        appId: selected.app.id,
      );
    } catch (error) {
      _showActionError(error.toString());
    }
  }

  Future<void> _performUninstall(AppDetailModel selected) async {
    final confirmed = await _confirmUninstall(selected.app.name);
    if (!mounted) {
      return;
    }
    if (confirmed != true) {
      return;
    }

    setState(() {
      _actionInProgress = true;
      _actionLabel = 'Uninstalling...';
    });

    try {
      final provider = context.read<InstalledProvider>();
      await provider.uninstallApp(sourceKey: selected.sourceKey, appId: selected.app.id);
      await provider.refresh();
      await _loadDetails();
    } catch (error) {
      _showActionError(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _actionInProgress = false;
          _actionLabel = null;
        });
      }
    }
  }

  Future<bool?> _confirmUninstall(String appName) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm uninstall'),
          content: Text('Uninstall "$appName"?'),
          actions: [
            SecondaryButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            DestructiveButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Uninstall'),
            ),
          ],
        );
      },
    );
  }

  void _showActionError(String message) => showError(
    context: context,
    title: "Action failed",
    message: message,
  );

  String _normalizeAppId(String id) {
    final trimmed = id.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }
    if (trimmed.startsWith('app/') || trimmed.startsWith('runtime/')) {
      final parts = trimmed.split('/');
      if (parts.length >= 2 && parts[1].trim().isNotEmpty) {
        return parts[1].trim();
      }
    }
    final branchSep = trimmed.indexOf('//');
    if (branchSep > 0) {
      return trimmed.substring(0, branchSep);
    }
    return trimmed;
  }

  String _resolveDisplayName(
    AppDetailModel detail,
    List<AppModel> exploreApps,
    List<AppModel> installedApps,
  ) {
    final current = detail.app.name.trim();
    if (current.isEmpty) {
      return _nameFromId(detail.app.id);
    }

    final normalizedId = _normalizeAppId(detail.app.id);
    final fromInstalled = installedApps
        .where((app) => _normalizeAppId(app.id) == normalizedId)
        .map((app) => app.name.trim())
        .where((name) => name.isNotEmpty)
        .cast<String?>()
        .firstWhere((_) => true, orElse: () => null);
    if (_isBetterName(fromInstalled, current, normalizedId)) {
      return fromInstalled!;
    }

    final fromExplore = exploreApps
        .where((app) => _normalizeAppId(app.id) == normalizedId)
        .map((app) => app.name.trim())
        .where((name) => name.isNotEmpty)
        .cast<String?>()
        .firstWhere((_) => true, orElse: () => null);
    if (_isBetterName(fromExplore, current, normalizedId)) {
      return fromExplore!;
    }

    return current;
  }

  bool _isBetterName(String? candidate, String current, String appId) {
    if (candidate == null || candidate.isEmpty) {
      return false;
    }
    if (candidate == current) {
      return false;
    }
    final currentLooksFallback = current == _nameFromId(appId) || current == appId;
    if (!currentLooksFallback) {
      return false;
    }
    return candidate != appId;
  }

  String _nameFromId(String id) {
    final normalized = _normalizeAppId(id);
    final parts = normalized.split('.');
    return parts.isEmpty ? normalized : parts.last;
  }

  AppDetailModel _withDisplayName(AppDetailModel detail, String displayName) {
    if (displayName == detail.app.name) {
      return detail;
    }
    final app = AppModel(
      id: detail.app.id,
      name: displayName,
      description: detail.app.description,
      icon: detail.app.icon,
      backend: detail.app.backend,
      installState: detail.app.installState,
      version: detail.app.version,
      popularityScore: detail.app.popularityScore,
    );
    return AppDetailModel(
      app: app,
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

  List<Widget> _buildLinkButtons(BuildContext context, AppDetailModel selected) {
    final theme = Theme.of(context);
    if (selected.links.isEmpty) {
      return [
        OutlinedContainer(
          padding: EdgeInsets.all(12 * theme.scaling),
          child: Text('No external links available.').muted(),
        ),
      ];
    }

    return selected.links
        .map(
          (link) => LinkButton(
            leading: const Icon(Icons.link),
            trailing: const Icon(Icons.open_in_new),
            child: Text(link.label, textAlign: TextAlign.start),
            onPressed: () {
              showToast(
                context: context,
                builder: (context, overlay) {
                  return SurfaceCard(
                    child: Basic(
                      title: const Text('Link URL'),
                      content: Text(link.url),
                      trailing: const Icon(Icons.link),
                    ),
                  );
                },
              );
            },
          ),
        )
        .toList();
  }

  AppDetailModel _loadingDetail(String appId) {
    return AppDetailModel(
      app: AppModel(
        id: appId,
        name: 'Loading...',
        description: 'Loading details',
        icon: '',
        backend: 'Loading',
        installState: InstallState.installed,
        version: null,
      ),
      sourceLabel: 'Loading...',
      sourceKey: 'loading',
      longDescription: '',
      developer: null,
      license: null,
      ageRating: null,
      downloadCount: null,
      installedSizeBytes: null,
      downloadSizeBytes: null,
      installDate: null,
      screenshots: const [],
      links: const [],
      extraInfo: const {},
    );
  }
}
