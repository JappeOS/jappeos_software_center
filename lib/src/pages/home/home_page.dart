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
import 'package:shadcn_flutter/shadcn_flutter.dart';

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
  Widget build(BuildContext context) {
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
        actionLabel: "Update All (2)",
        onViewAll: () {
          // Handle view all action
        },
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