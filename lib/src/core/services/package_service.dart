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

import '../../models/app_detail_model.dart';
import '../../models/app_model.dart';
import '../../models/update_model.dart';

abstract class PackageService {
  String get sourceId;
  Future<List<AppModel>> getInstalledApps();
  Future<List<UpdateModel>> getAvailableUpdates();
  Future<AppDetailModel?> getAppDetails(String id);
  Future<void> install(String id);
  Future<void> uninstall(String id);
  Future<void> update(String id);
  Future<void> open(String id);
}
