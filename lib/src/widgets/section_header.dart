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

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAll;
  final String actionLabel;
  final Icon actionIcon;

  const SectionHeader({
    super.key,
    required this.title,
    this.onViewAll,
    this.actionLabel = "View All",
    this.actionIcon = const Icon(Icons.chevron_right),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headerStyle = theme.typography.h4;
    return Padding(
      padding: EdgeInsets.only(
        top: 16 * theme.scaling,
        bottom: 8 * theme.scaling,
      ),
      child: SizedBox(
        height: headerStyle.fontSize!,
        child: Row(
          children: [
            Text(
              title,
              style: headerStyle,
            ),
            const Spacer(),
            if (onViewAll != null)
              LinkButton(
                onPressed: onViewAll,
                density: ButtonDensity.compact,
                trailing: actionIcon,
                child: Text(actionLabel),
              ),
          ],
        ),
      ),
    );
  }
}