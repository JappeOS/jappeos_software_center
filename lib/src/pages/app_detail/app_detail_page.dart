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

import '../shared/page_base.dart';
import 'widgets/app_header.dart';
import 'widgets/main_header_info_button.dart';
import 'widgets/screenshots_carousel.dart';

class AppDetailPage extends StatefulWidget {
  final String appId;

  const AppDetailPage({super.key, required this.appId});

  @override
  State<AppDetailPage> createState() => _AppDetailPageState();
}

class _AppDetailPageState extends State<AppDetailPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final children = [
      Gap(16 * theme.scaling),
      AppHeader(),
      Gap(16 * theme.scaling),
      Divider(),
      Gap(16 * theme.scaling),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          MainHeaderInfoButton(
            label: "Size",
            value: "10 MB",
            onPressed: () {},
          ),
          MainHeaderInfoButton(
            label: "Age Rating",
            value: "Unknown",
            onPressed: () {},
          ),
          MainHeaderInfoButton(
            label: "Safe to use",
            value: "Yes",
            onPressed: () {},
          ),
          MainHeaderInfoButton(
            label: "Downloads",
            value: "100K+",
            onPressed: () {},
          ),
        ],
      ),
      Gap(16 * theme.scaling),
      IgnorePageBaseLayout(child: ScreenshotsCarousel()),
      Gap(16 * theme.scaling),

      Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16 * theme.scaling,
        children: [
          Flexible(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text("Description").x3Large(),
                Gap(8 * theme.scaling),
                Text(
                  "This is a description of the app. It can be quite long and should wrap properly in the UI.",
                  softWrap: true,
                ),
              ],
            ),
          ),
          Flexible(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Gap(8 * theme.scaling),
                LinkButton(
                  leading: const Icon(Icons.link),
                  trailing: const Icon(Icons.open_in_new),
                  child: Text("Project Website", textAlign: TextAlign.start),
                  onPressed: () {},
                ),
                LinkButton(
                  leading: const Icon(Icons.code),
                  trailing: const Icon(Icons.open_in_new),
                  child: Text("Source Code", textAlign: TextAlign.start),
                  onPressed: () {},
                ),
                LinkButton(
                  leading: const Icon(Icons.bug_report),
                  trailing: const Icon(Icons.open_in_new),
                  child: Text("Report an issue", textAlign: TextAlign.start),
                  onPressed: () {},
                ),
                LinkButton(
                  leading: const Icon(Icons.help),
                  trailing: const Icon(Icons.open_in_new),
                  child: Text("Help", textAlign: TextAlign.start),
                  onPressed: () {},
                ),
              ],
            ),
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