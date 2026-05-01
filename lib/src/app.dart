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

import 'package:jappeos_software_center/src/core/services/command_runner.dart';
import 'package:jappeos_software_center/src/core/services/flatpak_service.dart';
import 'package:jappeos_software_center/src/core/services/pacman_service.dart';
import 'package:jappeos_software_center/src/providers/navigation_provider.dart';
import 'package:jappeos_software_center/src/providers/installed_provider.dart';
import 'package:jappeos_software_center/src/providers/updates_provider.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'pages/shared/main_scaffold.dart';

final kThemeLight = _getTheme(false);
final kThemeDark = _getTheme(true);

ThemeData _getTheme(bool dark) => ThemeData(
  colorScheme: dark
      ? ColorSchemes.darkDefaultColor
      : ColorSchemes.lightDefaultColor,
  radius: 0.9,
  surfaceOpacity: 0.85,
  surfaceBlur: 9,
);

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    const title = 'Software Center';
    return ShadcnApp(
      title: title,
      theme: kThemeLight,
      darkTheme: kThemeDark,
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => NavigationProvider()),
          ChangeNotifierProvider(
            create: (_) {
              const commandRunner = ProcessCommandRunner();
              final services = [
                FlatpakService(commandRunner: commandRunner),
                PacmanService(commandRunner: commandRunner),
              ];
              return InstalledProvider(
                sources: services,
              );
            },
          ),
          ChangeNotifierProvider(
            create: (_) {
              const commandRunner = ProcessCommandRunner();
              final services = [
                FlatpakService(commandRunner: commandRunner),
                PacmanService(commandRunner: commandRunner),
              ];
              return UpdatesProvider(sources: services);
            },
          ),
        ],
        child: MainScaffold(title: title),
      ),
    );
  }
}
