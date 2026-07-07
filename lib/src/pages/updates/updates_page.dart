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

import '../../models/update_model.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/updates_provider.dart';
import '../../utils.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/app_tile.dart';
import '../../widgets/feedback_state.dart';
import '../../widgets/section_header.dart';
import '../shared/page_base.dart';

class UpdatesPage extends StatefulWidget {
  const UpdatesPage({super.key});

  @override
  State<UpdatesPage> createState() => _UpdatesPageState();
}

class _UpdatesPageState extends State<UpdatesPage> {
  String? _activeUpdateId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UpdatesProvider>().loadIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UpdatesProvider>();
    final updates = provider.updates;

    final children = <Widget>[];

    if (provider.isLoading && updates.isEmpty) {
      children.add(
        FeedbackState(
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
    } else if (provider.errorMessage != null && updates.isEmpty) {
      children.add(
        FeedbackState(
          icon: Icons.warning,
          iconForeground: Colors.yellow,
          title: 'Failed to load updates',
          description: 'Please check your network connection and try again.\n\n${provider.errorMessage!}',
          action: PrimaryButton(onPressed: _refresh, child: const Text('Retry')),
        ),
      );
    } else if (updates.isEmpty) {
      children.add(
        FeedbackState(
          icon: Icons.check,
          iconForeground: Colors.green,
          title: 'Your system is up to date',
          description: 'No updates are available from active package sources.',
          action: PrimaryButton(onPressed: _refresh, child: const Text('Refresh')),
        ),
      );
    } else {
      children.add(
        SectionHeader(
          title: 'Updates Available (${updates.length})',
          onViewAll: (provider.isLoading || provider.isUpdatingAll || updates.isEmpty)
              ? null
              : _updateAll,
          actionLabel: provider.isUpdatingAll ? 'Updating...' : 'Update All',
          actionIcon: const Icon(Icons.cached),
        ),
      );
      children.add(
        ButtonGroup(
          direction: Axis.vertical,
          children: updates.map((update) {
            final busy = _activeUpdateId == update.id;
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

    if (provider.errorMessage != null && updates.isNotEmpty) {
      children.add(
        AppTile(
          icon: const Icon(Icons.warning),
          title: 'Some sources failed to load',
          description: provider.errorMessage!,
          trailing: PrimaryButton(onPressed: _refresh, child: const Text('Retry')),
        ),
      );
    }

    return PageBase(
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }

  Future<void> _refresh() async {
    try {
      await context.read<UpdatesProvider>().refresh();
    } catch (error) {
      _showError(error.toString());
    }
  }

  Future<void> _updateAll() async {
    try {
      await context.read<UpdatesProvider>().updateAll();
    } catch (error) {
      _showError(error.toString());
    }
  }

  Future<void> _updateOne(UpdateModel update) async {
    setState(() {
      _activeUpdateId = update.id;
    });
    try {
      await context.read<UpdatesProvider>().updateById(update.id);
    } catch (error) {
      _showError(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _activeUpdateId = null;
        });
      }
    }
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    showToast(
      context: context,
      builder: (context, overlay) {
        return SurfaceCard(
          child: Basic(
            title: const Text('Update failed'),
            content: Text(message),
            trailing: const Icon(Icons.warning),
          ),
        );
      },
    );
  }
}
