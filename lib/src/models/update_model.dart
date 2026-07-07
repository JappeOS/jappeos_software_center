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

import 'app_model.dart';

class UpdateModel {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String sourceKey;
  final String appId;
  final int? downloadSizeBytes;
  final String? version;
  final bool isSystem;
  final AppModel? app;

  const UpdateModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.sourceKey,
    required this.appId,
    required this.downloadSizeBytes,
    required this.version,
    required this.isSystem,
    required this.app,
  });
}
