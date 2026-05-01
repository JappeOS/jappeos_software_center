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
import 'package:provider/provider.dart';

import '../../providers/installed_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/app_tile.dart';
import '../../widgets/feedback_state.dart';
import '../../widgets/section_header.dart';
import '../shared/page_base.dart';

class InstalledPage extends StatefulWidget {
  const InstalledPage({super.key});

  @override
  State<InstalledPage> createState() => _InstalledPageState();
}

class _InstalledPageState extends State<InstalledPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InstalledProvider>().loadIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final installedProvider = context.watch<InstalledProvider>();
    final apps = installedProvider.apps;
    final children = <Widget>[];

    if (installedProvider.isLoading && apps.isEmpty) {
      children.add(
        FeedbackState(
          icon: Icons.refresh,
          title: 'Loading installed applications...',
          description: 'Collecting package data from configured backends.',
          action: const PrimaryButton(
            onPressed: null,
            leading: AspectRatio(
              aspectRatio: 1,
              child: CircularProgressIndicator(),
            ),
            child: Text('Loading'),
          ),
        ),
      );
    } else if (installedProvider.errorMessage != null && apps.isEmpty) {
      children.add(
        FeedbackState(
          icon: Icons.warning,
          iconForeground: Colors.yellow,
          title: 'Failed to load installed applications',
          description: 'This may be a bug worth reporting.\n\n${installedProvider.errorMessage!}',
          action: PrimaryButton(
            onPressed: () => context.read<InstalledProvider>().refresh(),
            child: const Text('Retry'),
          ),
        ),
      );
    } else if (apps.isEmpty) {
      children.add(
        FeedbackState(
          icon: Icons.search,
          title: 'No installed applications found',
          description: 'No application packages were returned by the active backends.',
          action: PrimaryButton(
            onPressed: () => context.read<InstalledProvider>().refresh(),
            child: const Text('Refresh'),
          ),
        ),
      );
    } else {
      children.add(
        SectionHeader(
          title: "Installed Applications (${apps.length})",
          onViewAll: installedProvider.isLoading
              ? null
              : () => context.read<InstalledProvider>().refresh(),
          actionLabel: installedProvider.isLoading ? "Refreshing..." : "Refresh",
          actionIcon: Icon(Icons.refresh),
        ),
      );
      children.add(
        ButtonGroup(
          direction: Axis.vertical,
          children: apps
              .map(
                (app) => AppTile(
                  icon: AppIcon(icon: app.icon, size: 30),
                  title: app.name,
                  description: app.description,
                  trailingText: _buildTrailingText(app.backend, app.version),
                  trailing: Icon(Icons.open_in_new),
                  onPressed: () =>
                      context.read<NavigationProvider>().openApp(app.id),
                ),
              )
              .toList(),
        ),
      );
    }

    if (installedProvider.errorMessage != null && apps.isNotEmpty) {
      children.add(
        AppTile(
          icon: Icon(Icons.warning),
          title: "Some sources failed to load",
          description: installedProvider.errorMessage!,
          trailing: PrimaryButton(
            child: const Text("Retry"),
            onPressed: () => context.read<InstalledProvider>().refresh(),
          ),
        ),
      );
    }

    return PageBase(
      itemCount: children.length,
      itemBuilder: (context, index) {
        return children[index];
      },
    );
  }

  String _buildTrailingText(String backend, String? version) {
    if (version == null || version.isEmpty) {
      return backend;
    }
    return '$backend • $version';
  }
}
