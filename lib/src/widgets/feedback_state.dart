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

class FeedbackState extends StatelessWidget {
  final IconData icon;
  final Color iconForeground;
  final String title;
  final String? description;
  final Widget? action;

  const FeedbackState({
    super.key,
    required this.icon,
    this.iconForeground = Colors.white,
    required this.title,
    this.description,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    //final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: iconForeground.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Icon(icon, size: 70, color: iconForeground),
            ),
          ),
          const Gap(16),
          Text(title).x4Large(),
          if (description != null) ...[
            const Gap(8),
            Text(
              description!,
              maxLines: 10,
              textAlign: TextAlign.center,
            ).muted().ellipsis(),
          ],
          if (action != null) ...[
            const Gap(16),
            action!,
          ],
        ],
      ),
    );
  }
}