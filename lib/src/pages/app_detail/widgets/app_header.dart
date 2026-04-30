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

import '../../../models/app_detail_model.dart';
import '../../../widgets/app_icon.dart';
import 'install_button.dart';
import 'source_selector.dart';

class AppHeader extends StatelessWidget {
  final AppDetailModel detail;
  final List<String> sources;
  final ValueChanged<String> onSourceChanged;
  final InstallButtonState installButtonState;
  final VoidCallback? onInstallOrUpdate;
  final VoidCallback? onOpen;
  final VoidCallback? onUninstall;
  final String? progressText;

  const AppHeader({
    super.key,
    required this.detail,
    required this.sources,
    required this.onSourceChanged,
    required this.installButtonState,
    this.onInstallOrUpdate,
    this.onOpen,
    this.onUninstall,
    this.progressText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      spacing: 16 * theme.scaling,
      children: [
        AppIcon(icon: detail.app.icon, size: 95 * theme.scaling),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4 * theme.scaling,
            children: [
              Text(detail.app.name).h3().ellipsis(),
              Text(
                detail.developer ?? detail.app.id,
              ).muted().ellipsis(),
              Gap(0),
              Text(
                detail.app.version == null
                    ? detail.app.backend
                    : '${detail.app.backend} • ${detail.app.version}',
              ).small().muted(),
            ],
          ),
        ),
        SizedBox(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              spacing: 8 * theme.scaling,
              children: [
              InstallButton(
                state: installButtonState,
                progressText: progressText,
                onInstallOrUpdate: onInstallOrUpdate,
                onOpen: onOpen,
                onUninstall: onUninstall,
              ),
              SourceSelector(
                sources: sources,
                selectedValue: detail.sourceLabel,
                onChanged: onSourceChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
