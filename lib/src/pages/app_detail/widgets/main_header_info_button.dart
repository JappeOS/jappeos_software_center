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

class MainHeaderInfoButton extends StatelessWidget {
  final String label;
  final String value;
  final void Function()? onPressed;

  const MainHeaderInfoButton({
    super.key,
    required this.label,
    required this.value,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: 130 * theme.scaling),
      child: GhostButton(
        onPressed: onPressed,
        child: Column(
          spacing: 8 * theme.scaling,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.input,
                borderRadius: theme.borderRadiusXxl,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16 * theme.scaling, vertical: 8 * theme.scaling),
                child: Text(value).large(),
              ),
            ),
            Text(label).semiBold(),
          ],
        ),
      ),
    );
  }
}