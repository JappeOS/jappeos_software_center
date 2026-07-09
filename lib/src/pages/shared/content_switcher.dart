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

import '../../providers/navigation_provider.dart';
import '../../navigation/nav_item.dart';

import '../explore/explore_page.dart';
import '../home/home_page.dart';
import '../installed/installed_page.dart';
import '../search_results/search_results_page.dart';
import '../updates/updates_page.dart';
import '../preferences/preferences_page.dart';
import '../app_detail/app_detail_page.dart';

class ContentSwitcher extends StatelessWidget {
  const ContentSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();

    Widget page;

    switch (nav.current) {
      case NavItem.home:
        page = const HomePage();
        break;

      case NavItem.explore:
        page = const ExplorePage();
        break;

      case NavItem.search:
        page = const SearchResultsPage();
        break;

      case NavItem.installed:
        page = const InstalledPage();
        break;

      case NavItem.updates:
        page = const UpdatesPage();
        break;

      case NavItem.preferences:
        page = const PreferencesPage();
        break;

      case NavItem.appDetail:
        page = AppDetailPage(
          appId: nav.selectedAppId!,
          install: nav.installSelectedApp,
        );
        break;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          //key: ValueKey<Key?>(child.key),
          scale: animation.drive(
            Tween(begin: 0.9, end: 1.0),
          ),
          child: FadeTransition(
            //key: ValueKey<Key?>(child.key),
            opacity: animation,
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(nav.valueKey),
        child: page,
      ),
    );
  }
}