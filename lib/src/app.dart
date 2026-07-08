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

import 'package:provider/provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'core/services/package_service.dart';
import 'pages/shared/main_scaffold.dart';
import 'core/services/command_runner.dart';
import 'core/services/flatpak_service.dart';
import 'core/services/pacman_service.dart';
import 'providers/navigation_provider.dart';
import 'providers/explore_provider.dart';
import 'providers/installed_provider.dart';
import 'providers/search_provider.dart';
import 'providers/updates_provider.dart';

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

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final commandRunner = ProcessCommandRunner();
  late List<PackageService> services;

  @override
  void initState() {
    super.initState();
    services = [
      FlatpakService(commandRunner: commandRunner),
      PacmanService(commandRunner: commandRunner),
    ];
  }

  @override
  Widget build(BuildContext context) {
    const title = 'Software Center';
    return  MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(
          create: (_) {
            return InstalledProvider(sources: services);
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            return ExploreProvider(sources: services);
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            return UpdatesProvider(sources: services);
          },
        ),
      ],
      child: ShadcnApp(
        title: title,
        theme: kThemeLight,
        darkTheme: kThemeDark,
        themeMode: ThemeMode.dark,
        debugShowCheckedModeBanner: false,
        home: MainScaffold(title: title),
      ),
    );
  }
}
