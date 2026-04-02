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

import 'content_switcher.dart';
import 'sidebar.dart';

class MainScaffold extends StatelessWidget {
  final String title;

  const MainScaffold({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      headers: [
        WindowHeaderBar(
          title: title,
          backgroundColor: Theme.of(context).colorScheme.sidebar,
          actions: [
            Spacer(),
            Flexible(
              flex: 2,
              child: TextField(
                features: [
                  InputFeature.leading(Icon(Icons.search)),
                  InputFeature.trailing(Icon(Icons.arrow_forward))
                ],
                placeholder: Text("Search software..."),
              ),
            ),
            Spacer(),
          ],
        ),
      ],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Sidebar(),
          const VerticalDivider(),
          Expanded(
            child: Column(
              children: [
                //const Topbar(),
                const Expanded(child: ContentSwitcher()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}