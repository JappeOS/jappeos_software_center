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

enum CategoryColor {
  red,
  orange,
  yellow,
  green,
  blue,
  purple,
  gray,
}

enum Category {
  development,
  multimedia,
  productivity,
  games,
  education,
  utilities,
}

class CategoryGrid extends StatelessWidget {
  const CategoryGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8 * theme.scaling,
      runSpacing: 10 * theme.scaling,
      children: [
        _buildCategoryButton(theme, "Development", Icons.code, CategoryColor.blue),
        _buildCategoryButton(theme, "Multimedia", Icons.movie, CategoryColor.green),
        _buildCategoryButton(theme, "Productivity", Icons.work, CategoryColor.orange),
        _buildCategoryButton(theme, "Games", Icons.videogame_asset, CategoryColor.purple),
        _buildCategoryButton(theme, "Education", Icons.school, CategoryColor.yellow),
        _buildCategoryButton(theme, "Utilities", Icons.build, CategoryColor.gray),
      ],
    );
  }

  Widget _buildCategoryButton(ThemeData theme, String title, IconData icon, CategoryColor color) {
    return Theme(
      data: theme.copyWith(
        colorScheme: () => theme.colorScheme.copyWith(
          primary: () => _getBackgroundColor(theme, color),
          primaryForeground: () => _getForegroundColor(theme, color),
        ),
        radius: () => 2,
      ),
      child: PrimaryButton(
        onPressed: () {},
        leading: Icon(icon),
        child: Text(title),
      ),
    );
  }

  Color _getBackgroundColor(ThemeData theme, CategoryColor color) {
    return theme.brightness == Brightness.light
        ? _getBackgroundColorLight(color)
        : _getBackgroundColorDark(color);
  }

  Color _getBackgroundColorLight(CategoryColor color) {
    switch (color) {
      case CategoryColor.red:
        return Colors.red[100];
      case CategoryColor.orange:
        return Colors.orange[100];
      case CategoryColor.yellow:
        return Colors.yellow[100];
      case CategoryColor.green:
        return Colors.green[100];
      case CategoryColor.blue:
        return Colors.blue[100];
      case CategoryColor.purple:
        return Colors.purple[100];
      case CategoryColor.gray:
        return Colors.gray[100];
    }
  }

  Color _getBackgroundColorDark(CategoryColor color) {
    switch (color) {
      case CategoryColor.red:
        return Colors.red[300];
      case CategoryColor.orange:
        return Colors.orange[300];
      case CategoryColor.yellow:
        return Colors.yellow[300];
      case CategoryColor.green:
        return Colors.green[300];
      case CategoryColor.blue:
        return Colors.blue[300];
      case CategoryColor.purple:
        return Colors.purple[300];
      case CategoryColor.gray:
        return Colors.gray[300];
    }
  }

  Color _getForegroundColor(ThemeData theme, CategoryColor color) {
    return theme.brightness == Brightness.light
        ? _getForegroundColorLight(color)
        : _getForegroundColorDark(color);
  }

  Color _getForegroundColorLight(CategoryColor color) {
    switch (color) {
      case CategoryColor.red:
        return Colors.red[800];
      case CategoryColor.orange:
        return Colors.orange[800];
      case CategoryColor.yellow:
        return Colors.yellow[800];
      case CategoryColor.green:
        return Colors.green[800];
      case CategoryColor.blue:
        return Colors.blue[800];
      case CategoryColor.purple:
        return Colors.purple[800];
      case CategoryColor.gray:
        return Colors.gray[800];
    }
  }

  Color _getForegroundColorDark(CategoryColor color) {
    switch (color) {
      case CategoryColor.red:
        return Colors.red[950];
      case CategoryColor.orange:
        return Colors.orange[950];
      case CategoryColor.yellow:
        return Colors.yellow[950];
      case CategoryColor.green:
        return Colors.green[950];
      case CategoryColor.blue:
        return Colors.blue[950];
      case CategoryColor.purple:
        return Colors.purple[950];
      case CategoryColor.gray:
        return Colors.gray[950];
    }
  }
}