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

import 'dart:math' as math;

import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../models/app_model.dart';
import '../../providers/explore_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/app_tile.dart';
import '../../widgets/feedback_state.dart';
import '../../widgets/section_header.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  static const _estimatedTileHeight = 74.0;

  final ScrollController _scrollController = ScrollController();
  int _visibleCount = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExploreProvider>().loadIfNeeded();
      _recalculateVisibleCount();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final threshold = _scrollController.position.maxScrollExtent - 500;
    if (_scrollController.position.pixels >= threshold) {
      _increaseVisibleCount();
    }
  }

  void _recalculateVisibleCount() {
    final viewportHeight = MediaQuery.of(context).size.height;
    final tilesPerScreen = math.max(6, (viewportHeight / _estimatedTileHeight).ceil());
    final target = tilesPerScreen * 2;
    if (!mounted) {
      return;
    }
    setState(() {
      _visibleCount = math.max(_visibleCount, target);
    });
  }

  void _increaseVisibleCount() {
    final provider = context.read<ExploreProvider>();
    if (_visibleCount >= provider.apps.length) {
      return;
    }

    final viewportHeight = MediaQuery.of(context).size.height;
    final tilesPerScreen = math.max(6, (viewportHeight / _estimatedTileHeight).ceil());
    final step = tilesPerScreen;

    setState(() {
      _visibleCount = math.min(provider.apps.length, _visibleCount + step);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExploreProvider>();
    final apps = provider.apps;
    final displayCount = math.min(_visibleCount, apps.length);
    final theme = Theme.of(context);

    final rows = <Widget>[];

    if (provider.isLoading && apps.isEmpty) {
      rows.add(
        FeedbackState(
          icon: Icons.refresh,
          title: 'Loading applications...',
          description: 'Collecting available packages from active sources.',
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
    } else if (provider.errorMessage != null && apps.isEmpty) {
      rows.add(
        FeedbackState(
          icon: Icons.warning,
          iconForeground: Colors.yellow,
          title: 'Failed to load applications',
          description: 'Make sure that you have an active network connection.\n\n${provider.errorMessage!}',
          action: PrimaryButton(
            onPressed: () => () => provider.refresh(),
            child: const Text('Retry'),
          ),
        ),
      );
    } else if (apps.isEmpty) {
      rows.add(
        FeedbackState(
          icon: Icons.search,
          title: 'No applications found',
          description: 'No application packages were returned by the active backends.',
          action: PrimaryButton(
            onPressed: () => provider.refresh(),
            child: const Text('Refresh'),
          ),
        ),
      );
    } else {
      rows.add(
        SectionHeader(
          title: 'Explore Applications (${apps.length})',
          onViewAll: provider.isLoading ? null : () => provider.refresh(),
          actionLabel: provider.isLoading ? 'Refreshing...' : 'Refresh',
          actionIcon: Icon(Icons.refresh),
        ),
      );
      rows.add(
        ButtonGroup(
          direction: Axis.vertical,
          children: [
            for (var i = 0; i < displayCount; i++)
              AppTile(
                icon: AppIcon(icon: apps[i].icon, size: 30),
                title: apps[i].name,
                description: apps[i].description,
                trailingText: _buildTrailingText(apps[i]),
                trailing: Icon(Icons.open_in_new),
                onPressed: () =>
                    context.read<NavigationProvider>().openApp(apps[i].id),
              ),
          ],
        ),
      );

      if (displayCount < apps.length) {
        rows.add(
          OutlinedContainer(
            padding: EdgeInsets.symmetric(
              horizontal: 12 * theme.scaling,
              vertical: 8 * theme.scaling,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Showing $displayCount of ${apps.length} applications').muted(),
                GhostButton(onPressed: _increaseVisibleCount, child: const Text('Load More')),
              ],
            ),
          ),
        );
      }
    }

    if (provider.errorMessage != null && apps.isNotEmpty) {
      rows.add(
        AppTile(
          icon: const Icon(Icons.warning),
          title: 'Some sources failed to load',
          description: provider.errorMessage!,
          trailing: PrimaryButton(
            onPressed: () => provider.refresh(),
            child: const Text('Retry'),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _recalculateVisibleCount();
        });

        return ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.symmetric(
            horizontal: 14 * theme.scaling,
            vertical: 8 * theme.scaling,
          ),
          itemCount: rows.length,
          itemBuilder: (context, index) {
            final built = rows[index];
            return Align(
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 750, maxWidth: 750),
                child: built,
              ),
            );
          },
        );
      },
    );
  }

  String _buildTrailingText(AppModel app) {
    final popularity = app.popularityScore;
    if (popularity > 0) {
      return '${app.backend} • pop ${popularity.toStringAsFixed(2)}';
    }
    return app.backend;
  }
}
