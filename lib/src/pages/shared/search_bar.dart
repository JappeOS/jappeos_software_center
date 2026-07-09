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

import 'dart:async';

import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../models/app_model.dart';
import '../../models/install_state.dart';
import '../../providers/explore_provider.dart';
import '../../providers/installed_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/search_provider.dart';
import '../../utils.dart';
import '../../widgets/app_icon.dart';

class SearchBar extends StatefulWidget {
  const SearchBar({super.key});

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  bool get _popoverShown => _overlay != null;
  OverlayCompleter? _overlay;
  final _controller = TextEditingController();
  Timer? _searchTimer;
  int _searchGeneration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InstalledProvider>().loadIfNeeded();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();
    final theme = Theme.of(context);
    final iconSize = 27.5 * theme.scaling;
    return TextField(
      controller: _controller,
      features: [
        InputFeature.leading(Icon(Icons.search)),
        InputFeature.trailing(Icon(Icons.arrow_forward)),
      ],
      placeholder: Text("Search software..."),
      onChanged: (s) async {
        final generation = ++_searchGeneration;
        _searchTimer?.cancel();
        _searchTimer = Timer(const Duration(milliseconds: 300), () async {
          try {
            await provider.search(context.read<ExploreProvider>(), name: s);
          } finally {
            if (!mounted || generation != _searchGeneration) {
              return; // stale search
            }
          }
        });
        if (_popoverShown && s.trim().isEmpty) {
          _overlay!.remove();
          _overlay!.dispose();
          _overlay = null;
          return;
        }
        if (!_popoverShown) {
          _overlay?.remove();
          _overlay?.dispose();
          _overlay = showPopover(
            context: context,
            alignment: Alignment.topCenter,
            offset: const Offset(0, 8),
            widthConstraint: PopoverConstraint.anchorMaxSize,
            builder: (context) => Consumer<SearchProvider>(
              builder: (context, provider, _) => ModalContainer(
                padding: EdgeInsets.all(8 * theme.scaling),
                child: Column(
                  spacing: 4 * theme.scaling,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (provider.isLoading)
                      for (int i = 0; i < 4; i++)
                        _SearchItem(
                          icon: Icon(Icons.settings_applications),
                          name: "This is an app",
                          installed: false,
                          skeleton: true,
                          onPressed: () {},
                        )
                    else if (provider.searchResult.isEmpty)
                      Padding(
                        padding: EdgeInsets.all(32),
                        child: Text("No search results found.").center(),
                      )
                    else ...[
                      for (final app in provider.searchResult.take(5))
                        _SearchItem.fromAppModel(
                          model: app,
                          iconSize: iconSize,
                          installed: () {
                            final isInstalledByList = context.read<InstalledProvider>().apps.any(
                              (a) => normalizeAppId(a.id) == normalizeAppId(app.id),
                            );
                            return isInstalledByList ||
                                app.installState == InstallState.installed;
                          }(),
                          onPressed: () {
                            context.read<NavigationProvider>().openApp(app.id);
                            closeOverlay(context);
                            _controller.clear();
                          },
                        ),
                      const Divider(),
                      _SearchItem(
                        icon: Icon(Icons.more, size: iconSize),
                        name: "See All (${provider.searchResult.length})",
                        installed: false,
                        onPressed: () {
                          context.read<NavigationProvider>().goSearch();
                          closeOverlay(context);
                          _controller.clear();
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
          _overlay!.future.then((_) => _overlay = null);
        }
      },
    );
  }
}

class _SearchItem extends StatelessWidget {
  final Widget icon;
  final String name;
  final bool installed;
  final bool skeleton;
  final VoidCallback? onPressed;

  factory _SearchItem.fromAppModel({
    required AppModel model,
    double iconSize = 30,
    bool installed = false,
    void Function()? onPressed,
  }) => _SearchItem(
    icon: AppIcon(icon: model.icon, size: iconSize),
    name: model.name,
    installed: installed,
    onPressed: onPressed,
  );

  const _SearchItem({
    required this.icon,
    required this.name,
    this.installed = false,
    this.skeleton = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GhostButton(
      onPressed: onPressed,
      leading: icon.asSkeleton(enabled: skeleton),
      trailing: installed ? Row(
        spacing: 8 * Theme.of(context).scaling,
        children: [
          Text("Installed").muted().asSkeleton(enabled: skeleton),
          Icon(Icons.open_in_new).asSkeleton(enabled: skeleton),
        ],
      ) : Icon(Icons.open_in_new).asSkeleton(enabled: skeleton),
      child: Text(name).asSkeleton(enabled: skeleton),
    );
  }
}