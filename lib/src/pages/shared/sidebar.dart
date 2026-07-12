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

import '../../navigation/nav_item.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/updates_provider.dart';

class Sidebar extends StatefulWidget {
  const Sidebar({super.key});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  int _selected = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UpdatesProvider>().loadIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();
    final updates = context.watch<UpdatesProvider>();
    final theme = Theme.of(context);
    final selectedStyle = ButtonStyle.secondary();
    if (nav.current == NavItem.search) {
      _selected = 2;
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: NavigationSidebar(
            spacing: 2 * theme.scaling,
            backgroundColor: theme.colorScheme.sidebar,
            index: _selected < 6 ? _selected : null,
            onSelected: (key) {
              _selected = key;
              switch (_selected) {
                case 0: nav.goHome();
                case 1: nav.goExplore();
                case 2: nav.goSearch();
                case 3: nav.goInstalled();
                case 4: nav.goUpdates();
              }
              setState(() {});
            },
            children: [
              NavigationItem(
                index: 0,
                selectedStyle: selectedStyle,
                label: Text("Home"),
                child: Icon(Icons.home),
              ),
              NavigationItem(
                index: 1,
                selectedStyle: selectedStyle,
                label: Text("Explore"),
                child: Icon(Icons.explore),
              ),
              if (_selected == 2)
                NavigationItem(
                  index: 2,
                  selectedStyle: selectedStyle,
                  label: Text("Search Results"),
                  child: Icon(Icons.search),
                ),
              NavigationItem(
                index: 3,
                selectedStyle: selectedStyle,
                label: Text("Installed"),
                child: Icon(Icons.system_update_alt),
              ),
              NavigationItem(
                index: 4,
                selectedStyle: selectedStyle,
                label: Text("Updates"),
                child: _buildRedCircle(Icon(Icons.cached), updates.updates.isNotEmpty),
              ),
            ],
          ),
        ),
        NavigationSidebar(
          spacing: 2 * theme.scaling,
          backgroundColor: theme.colorScheme.sidebar,
          index: _selected != 6 ? null : _selected,
          keepMainAxisSize: true,
          onSelected: (key) {
            _selected = key;
            switch (_selected) {
              case 6: nav.goPreferences();
            }
            setState(() {});
          },
          children: [
            NavigationItem(
              index: 6,
              selectedStyle: selectedStyle,
              label: Text("Preferences"),
              child: Icon(Icons.settings),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRedCircle(Widget child, bool enable) {
    if (!enable) return child;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        child,
        Positioned(
          bottom: 0,
          right: 0,
          child: SizedBox.square(
            dimension: 7,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(100),
                border: BoxBorder.all(
                  width: 1,
                  strokeAlign: BorderSide.strokeAlignOutside,
                  color: Theme.of(context).colorScheme.background,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}