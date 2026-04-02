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

class AppTile extends StatelessWidget {
  final Widget? icon;
  final String title;
  final String description;
  final String? trailingText;
  final Widget trailing;
  final void Function()? onPressed;

  const AppTile({
    super.key,
    this.icon,
    required this.title,
    required this.description,
    this.trailingText,
    required this.trailing,
    this.onPressed
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Button(
      style: ButtonStyle.outline().copyWith(
        decoration: (context, states, value) => (value as BoxDecoration).copyWith(
          borderRadius: theme.borderRadiusLg,
          color: states.contains(WidgetState.hovered)
              ? theme.colorScheme.muted
              : theme.colorScheme.sidebar,
          boxShadow: [
            BoxShadow(
              color: theme.brightness == Brightness.light
                  ? Colors.gray[300]
                  : Colors.black,
              blurRadius: 0,
              spreadRadius: 1,
              offset: Offset(0, 2),
            ),
          ],
        ),
      ),
      onPressed: onPressed,
      leading: icon != null ? SizedBox.square(
        dimension: 30 * theme.scaling,
        child: icon,
      ) : null,
      trailing: Row(
        spacing: 16 * theme.scaling,
        children: [
          if (trailingText != null) Text(trailingText!).small().muted().ellipsis(),
          ButtonStyleOverride(
            decoration: (context, states, decoration)
                => (decoration as BoxDecoration).copyWith(
              borderRadius: Theme.of(context).borderRadiusMd,
            ),
            child: trailing,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        //spacing: 2 * theme.scaling,
        children: [
          Text(title).large().ellipsis(),
          Text(description).small().muted().ellipsis(),
        ],
      ),
    );
  }
}