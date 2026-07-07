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

import 'package:jappeos_software_center/src/widgets/app_tile.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../models/update_model.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/updates_provider.dart';
import '../../utils.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/feedback_state.dart';
import '../../widgets/section_header.dart';
import '../shared/page_base.dart';
import 'widgets/app_grid.dart';
import 'widgets/category_grid.dart';
import 'widgets/featured_banner.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UpdatesProvider>().loadIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final updateProvider = context.watch<UpdatesProvider>();
    final updates = updateProvider.updates;

    final children = [
      FeaturedBanner(
        item: FeatuedItem(
          title: "Visual Studio Code",
          description: "Powerful, open-source code editor with built-in support for debugging and Git.",
          imageUrl: "https://upload.wikimedia.org/wikipedia/commons/thumb/9/9a/Visual_Studio_Code_1.35_icon.svg/960px-Visual_Studio_Code_1.35_icon.svg.png",
          onInstall: () {
            // Handle install action
          },
          onLearnMore: () {
            // Handle learn more action
          },
        ),
      ),
      SectionHeader(
        title: "Recommended for you",
        onViewAll: () {
          // Handle view all action
        },
      ),
      AppGrid(),
      SectionHeader(
        title: "Categories",
      ),
      CategoryGrid(),
      SectionHeader(
        title: "Recent Updates",
        actionLabel: "Show All (${updates.length})",
        onViewAll: updates.isNotEmpty
            ? () => context.read<NavigationProvider>().goUpdates()
            : null,
      ),
    ];

    if (updateProvider.isLoading && updates.isEmpty) {
      children.add(
        FeedbackStateCard(
          icon: Icons.refresh,
          title: 'Loading updates...',
          description: 'Checking all package sources for available updates.',
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
    } else if (updateProvider.errorMessage != null && updates.isEmpty) {
      children.add(
        FeedbackStateCard(
          icon: Icons.warning,
          iconForeground: Colors.yellow,
          title: 'Failed to load updates',
          description: 'Please check your network connection and try again.\n\n${updateProvider.errorMessage!}',
          action: PrimaryButton(onPressed: _refresh, child: const Text('Retry')),
        ),
      );
    } else if (updates.isEmpty) {
      children.add(
        FeedbackStateCard(
          icon: Icons.check,
          iconForeground: Colors.green,
          title: 'Your system is up to date',
          description: 'No updates are available from active package sources.',
          action: PrimaryButton(onPressed: _refresh, child: const Text('Refresh')),
        ),
      );
    } else {
      children.add(
        ButtonGroup(
          direction: Axis.vertical,
          children: updates.take(3).map((update) {
            final busy = updateProvider.currentUpdateIds.contains(update.id);
            return AppTile(
              icon: update.isSystem
                  ? const Icon(Icons.system_update_alt)
                  : AppIcon(icon: update.icon, size: 30),
              title: update.name,
              description: update.description,
              trailingText: formatBytes(update.downloadSizeBytes),
              trailing: PrimaryButton(
                onPressed: busy ? null : () => _updateOne(update),
                child: Text(busy ? 'Updating...' : 'Update'),
              ),
              onPressed: update.isSystem || update.appId == '__all__'
                  ? null
                  : () => context.read<NavigationProvider>().openApp(update.appId),
            );
          }).toList(),
        ),
      );
    }

    if (updateProvider.errorMessage != null && updates.isNotEmpty) {
      children.add(
        AppTile(
          icon: const Icon(Icons.warning),
          title: 'Some sources failed to load',
          description: updateProvider.errorMessage!,
          trailing: PrimaryButton(onPressed: _refresh, child: const Text('Retry')),
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

  Future<void> _refresh() async {
    try {
      await context.read<UpdatesProvider>().refresh();
    } catch (error) {
      _showError(error.toString());
    }
  }

  Future<void> _updateOne(UpdateModel update) async {
    try {
      await context.read<UpdatesProvider>().updateById(update.id);
    } catch (error) {
      _showError(error.toString());
    }
  }

  void _showError(String message) => showError(
    context: context,
    title: "Update failed",
    message: message,
  );
}