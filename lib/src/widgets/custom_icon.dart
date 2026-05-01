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

import 'package:flutter_svg/svg.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class CustomIcon extends StatelessWidget {
  final CustomIconType icon;

  const CustomIcon({super.key, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = theme.iconTheme.medium.size;
    final colorFilter = ColorFilter.mode(
      theme.colorScheme.secondaryForeground,
      BlendMode.srcATop,
    );
    switch (icon) {
      case CustomIconType.arch:
        return SvgPicture.asset(
          'assets/icons/arch.svg',
          width: size,
          height: size,
          colorFilter: colorFilter,
        );
      case CustomIconType.flatpak:
        return SvgPicture.asset(
          'assets/icons/flatpak.svg',
          width: size,
          height: size,
          colorFilter: colorFilter,
        );
    }
    // ignore: dead_code
    assert(false, "Invalid icon.");
  }
}

enum CustomIconType {
  arch,
  flatpak,
}