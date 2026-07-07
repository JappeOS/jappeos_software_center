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

class AppLink {
  final String label;
  final String url;

  const AppLink({required this.label, required this.url});
}

class AppDetailModel {
  final AppModel app;
  final String sourceLabel;
  final String sourceKey;
  final String longDescription;
  final String? developer;
  final String? license;
  final String? ageRating;
  final int? downloadCount;
  final int? installedSizeBytes;
  final int? downloadSizeBytes;
  final DateTime? installDate;
  final List<String> screenshots;
  final List<AppLink> links;
  final Map<String, String> extraInfo;

  const AppDetailModel({
    required this.app,
    required this.sourceLabel,
    required this.sourceKey,
    required this.longDescription,
    required this.developer,
    required this.license,
    required this.ageRating,
    required this.downloadCount,
    required this.installedSizeBytes,
    required this.downloadSizeBytes,
    required this.installDate,
    required this.screenshots,
    required this.links,
    required this.extraInfo,
  });
}
