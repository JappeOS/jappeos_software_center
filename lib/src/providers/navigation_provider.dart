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

import '../navigation/nav_item.dart';

class NavigationProvider extends ChangeNotifier {
  NavItem _current = NavItem.home;
  String? _selectedAppId;

  NavItem get current => _current;
  String? get selectedAppId => _selectedAppId;
  String get valueKey => current.toString() + (selectedAppId ?? '');

  void goHome() {
    _current = NavItem.home;
    _selectedAppId = null;
    notifyListeners();
  }

  void goExplore() {
    _current = NavItem.explore;
    notifyListeners();
  }

  void goInstalled() {
    _current = NavItem.installed;
    notifyListeners();
  }

  void goUpdates() {
    _current = NavItem.updates;
    notifyListeners();
  }

  void goPreferences() {
    _current = NavItem.preferences;
    notifyListeners();
  }

  void openApp(String appId) {
    _selectedAppId = appId;
    _current = NavItem.appDetail;
    notifyListeners();
  }
}