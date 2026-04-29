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

import 'source_selector.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      spacing: 16 * theme.scaling,
      children: [
        Icon(Icons.apps, size: 95 * theme.scaling),
        Flexible(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4 * theme.scaling,
            children: [
              Text("App Name").h3().ellipsis(),
              Text(
                "App creator's name",
              ).muted().ellipsis(),
              Gap(0),
              Row(
                spacing: 6 * theme.scaling,
                children: [
                  StarRating(
                    starSize: 14,
                    value: 5,
                  ),
                  Text("(123)").muted(),
                ],
              ),
            ],
          ),
        ),
        Flexible(
          flex: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8 * theme.scaling,
            children: [
              PrimaryButton(child: Text("Install"), onPressed: () {}),
              SourceSelector(),
            ],
          ),
        ),
      ],
    );
  }
}