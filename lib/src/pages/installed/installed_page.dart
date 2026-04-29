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
import '../../widgets/app_tile.dart';
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
    final children = <Widget>[
      SectionHeader(
        title: "Installed Applications (${apps.length})",
        onViewAll: installedProvider.isLoading
            ? null
            : () => context.read<InstalledProvider>().refresh(),
        actionLabel: installedProvider.isLoading ? "Refreshing..." : "Refresh",
      ),
    ];

    if (installedProvider.isLoading && apps.isEmpty) {
      children.add(
        AppTile(
          icon: Icon(Icons.refresh),
          title: "Loading installed applications",
          description: "Collecting package data from configured backends.",
          trailing: PrimaryButton(
            onPressed: null,
            child: const Text("Loading"),
          ),
        ),
      );
    } else if (installedProvider.errorMessage != null && apps.isEmpty) {
      children.add(
        AppTile(
          icon: Icon(Icons.warning),
          title: "Failed to load installed applications",
          description: installedProvider.errorMessage!,
          trailing: PrimaryButton(
            child: const Text("Retry"),
            onPressed: () => context.read<InstalledProvider>().refresh(),
          ),
        ),
      );
    } else if (apps.isEmpty) {
      children.add(
        AppTile(
          icon: Icon(Icons.search),
          title: "No installed applications found",
          description:
              "No application packages were returned by the active backends.",
          trailing: PrimaryButton(
            child: const Text("Refresh"),
            onPressed: () => context.read<InstalledProvider>().refresh(),
          ),
        ),
      );
    } else {
      children.add(
        ButtonGroup(
          direction: Axis.vertical,
          children: apps
              .map(
                (app) => AppTile(
                  icon: Icon(Icons.apps),
                  title: app.name,
                  description: app.description,
                  trailingText: _buildTrailingText(app.backend, app.version),
                  trailing: PrimaryButton(
                    onPressed: null,
                    child: const Text("Installed"),
                  ),
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
