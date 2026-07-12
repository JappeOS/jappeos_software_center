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

class AppCard extends StatefulWidget {
  const AppCard({super.key});

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OutlinedContainer(
      padding: EdgeInsets.all(8 * theme.scaling),
      borderRadius: theme.borderRadiusLg,
      child: Column(
        spacing: 8 * theme.scaling,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox.square(
                dimension: 48,
                child: Icon(Icons.apps, size: 42),
              ),
              const Gap(8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text("Coming soon").h4().ellipsis(),
                    Text(
                      "Short description of the app.",
                      softWrap: true,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ).small(),
                  ],
                ),
              ),
            ],
          ),
          OutlineButton(onPressed: null, child: const Text("Install")),
        ],
      ),
    );
  }
}