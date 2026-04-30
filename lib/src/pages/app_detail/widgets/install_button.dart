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

class InstallButton extends StatelessWidget {
  final InstallButtonState state;
  final double? progress;
  final String? progressText;
  final VoidCallback? onInstallOrUpdate;
  final VoidCallback? onOpen;
  final VoidCallback? onUninstall;

  const InstallButton({
    super.key,
    required this.state,
    this.progress,
    this.progressText,
    this.onInstallOrUpdate,
    this.onOpen,
    this.onUninstall,
  });

  @override
  Widget build(BuildContext context) {
    bool updateAvailable = state == InstallButtonState.updateAvailable;
    switch (state) {
      case InstallButtonState.notInstalled:
        return PrimaryButton(
          onPressed: onInstallOrUpdate,
          child: const Text("Install"),
        );
      case InstallButtonState.updateAvailable:
      case InstallButtonState.installed:
        return ButtonGroup(
          children: [
            PrimaryButton(
              onPressed: updateAvailable ? onInstallOrUpdate : onOpen,
              child: Text(updateAvailable ? "Update" : "Open"),
            ),
            IconButton.destructive(
              icon: Icon(Icons.delete),
              onPressed: onUninstall,
            ),
          ],
        );
      case InstallButtonState.progress:
        return PrimaryButton(
          onPressed: null,
          leading: AspectRatio(
            aspectRatio: 1,
            child: CircularProgressIndicator(
              value: progress,
            ),
          ),
          child: Text(progressText ?? "Installing..."),
        );
    }
  }
}

enum InstallButtonState {
  notInstalled,
  installed,
  updateAvailable,
  progress,
}