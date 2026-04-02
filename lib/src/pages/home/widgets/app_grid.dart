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

import 'app_card.dart';

class AppGrid extends StatelessWidget {
  //final List<AppModel> apps;

  const AppGrid({super.key, /*required this.apps*/});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final spacing = 12 * theme.scaling;

        int columns = width ~/ 175;
        columns = columns.clamp(1, 6);

        final itemWidth =
            (width - (columns - 1) * spacing) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          /*children: apps.map((app) {
            return SizedBox(
              width: itemWidth,
              child: AppCard(app: app),
            );
          }).toList(),*/

          children: [
            SizedBox(
              width: itemWidth,
              child: AppCard(),
            ),
            SizedBox(
              width: itemWidth,
              child: AppCard(),
            ),
            SizedBox(
              width: itemWidth,
              child: AppCard(),
            ),
            SizedBox(
              width: itemWidth,
              child: AppCard(),
            ),
          ],
        );
      },
    );
  }
}