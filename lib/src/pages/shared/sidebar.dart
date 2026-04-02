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

import '../../providers/navigation_provider.dart';

class Sidebar extends StatefulWidget {
  const Sidebar({super.key});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();
    final theme = Theme.of(context);
    final selectedStyle = ButtonStyle.secondary().copyWith(
      textStyle: (context, states, value) => value.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
    return NavigationSidebar(
      spacing: 2 * theme.scaling,
      backgroundColor: theme.colorScheme.sidebar,
      index: _selected,
      onSelected: (key) {
        _selected = key;
        switch (_selected) {
          case 0: nav.goHome();
          case 1: nav.goExplore();
          case 2: nav.goInstalled();
          case 3: nav.goUpdates();
          case 4: nav.goPreferences();
        }
        setState(() {});
      },
      children: [
        NavigationItem(
          selectedStyle: selectedStyle,
          label: Text("Home"),
          child: Icon(Icons.home),
        ),
        NavigationItem(
          selectedStyle: selectedStyle,
          label: Text("Explore"),
          child: Icon(Icons.explore),
        ),
        NavigationItem(
          selectedStyle: selectedStyle,
          label: Text("Installed"),
          child: Icon(Icons.system_update_alt),
        ),
        NavigationItem(
          selectedStyle: selectedStyle,
          label: Text("Updates"),
          child: Icon(Icons.cached),
        ),
        NavigationItem(
          selectedStyle: selectedStyle,
          label: Text("Preferences"),
          child: Icon(Icons.settings),
        ),
      ],
    );
  }
}