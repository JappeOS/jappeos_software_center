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

class SearchBar extends StatefulWidget {
  const SearchBar({super.key});

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  bool get _popoverShown => _overlay != null;
  OverlayCompleter? _overlay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      features: [
        InputFeature.leading(Icon(Icons.search)),
        InputFeature.trailing(Icon(Icons.arrow_forward)),
      ],
      placeholder: Text("Search software..."),
      onChanged: (s) {
        if (_popoverShown && s.isEmpty) {
          _overlay!.remove();
          _overlay!.dispose();
          _overlay = null;
          return;
        }
        if (!_popoverShown) {
          _overlay = showPopover(
            context: context,
            alignment: Alignment.topCenter,
            offset: const Offset(0, 8),
            widthConstraint: PopoverConstraint.anchorMaxSize,
            builder: (context) => ModalContainer(
              padding: EdgeInsets.all(8 * theme.scaling),
              child: Column(
                spacing: 4 * theme.scaling,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SearchItem(
                    icon: Icon(Icons.settings_applications),
                    name: "App 1",
                    installed: true,
                    onPressed: () {},
                  ),
                  _SearchItem(
                    icon: Icon(Icons.settings_applications),
                    name: "App 2",
                    installed: false,
                    onPressed: () {},
                  ),
                  _SearchItem(
                    icon: Icon(Icons.settings_applications),
                    name: "App 3",
                    installed: false,
                    onPressed: () {},
                  ),
                  _SearchItem(
                    icon: Icon(Icons.settings_applications),
                    name: "App 4",
                    installed: false,
                    onPressed: () {},
                  ),
                  const Divider(),
                  _SearchItem(
                    icon: Icon(Icons.more),
                    name: "See All",
                    installed: false,
                    onPressed: () {},
                  ),
                ],
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
  final VoidCallback? onPressed;

  const _SearchItem({
    super.key,
    required this.icon,
    required this.name,
    this.installed = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GhostButton(
      onPressed: onPressed,
      leading: icon,
      trailing: installed ? Row(
        spacing: 8 * Theme.of(context).scaling,
        children: [
          Text("Installed").muted(),
          Icon(Icons.open_in_new),
        ],
      ) : Icon(Icons.open_in_new),
      child: Text(name),
    );
  }
}