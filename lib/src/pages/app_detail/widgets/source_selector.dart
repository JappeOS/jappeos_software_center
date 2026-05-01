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

import 'package:material_symbols_icons/symbols.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../../widgets/custom_icon.dart';

class SourceSelector extends StatelessWidget {
  final List<String> sources;
  final String selectedValue;
  final ValueChanged<String> onChanged;

  const SourceSelector({
    super.key,
    required this.sources,
    required this.selectedValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Select<String>(
      itemBuilder: (context, item) => _buildItem(context, item),
      popupConstraints: const BoxConstraints(maxHeight: 300, maxWidth: 280),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
      value: selectedValue,
      placeholder: const Text('Select source'),
      popup: SelectPopup(
        items: SelectItemList(
          children: sources
              .map((source) => SelectItemButton(
                value: source,
                child: _buildItem(context, source),
              ))
              .toList(),
        ),
      ).call,
    );
  }

  Widget _buildItem(BuildContext context, String source) {
    final theme = Theme.of(context);
    Widget icon = Icon(Symbols.deployed_code);
    if (source.startsWith("Flatpak")) {
      icon = CustomIcon(icon: CustomIconType.flatpak);
    } else if (source.startsWith("Pacman")) {
      icon = CustomIcon(icon: CustomIconType.arch);
    }
    return Row(
      spacing: 8 * theme.scaling,
      children: [
        icon,
        Text(source),
      ],
    );
  }
}
