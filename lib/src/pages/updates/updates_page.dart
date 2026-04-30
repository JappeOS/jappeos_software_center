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

import '../../widgets/app_tile.dart';
import '../../widgets/section_header.dart';
import '../shared/page_base.dart';

class UpdatesPage extends StatefulWidget {
  const UpdatesPage({super.key});

  @override
  State<UpdatesPage> createState() => _UpdatesPageState();
}

class _UpdatesPageState extends State<UpdatesPage> {
  @override
  Widget build(BuildContext context) {
    final children = [
      SectionHeader(
        title: "Updates Available (2)",
        onViewAll: () {},
        actionLabel: "Update All",
        actionIcon: Icon(Icons.cached),
      ),
      ButtonGroup(
        direction: Axis.vertical,
        children: [
          AppTile(
            icon: Icon(Icons.settings),
            title: "Settings",
            description: "Manage your application settings",
            trailing: PrimaryButton(
              child: const Text("Update"),
              onPressed: () {},
            ),
            trailingText: "66 MB",
            onPressed: () {},
          ),
          AppTile(
            icon: Icon(Icons.settings),
            title: "Settings",
            description: "Manage your application settings",
            trailing: PrimaryButton(
              child: const Text("Update"),
              onPressed: () {},
            ),
            trailingText: "66 MB",
            onPressed: () {},
          ),
        ],
      ),
    ];

    return PageBase(
      itemCount: children.length,
      itemBuilder: (context, index) {
        return children[index];
      },
    );
  }
}