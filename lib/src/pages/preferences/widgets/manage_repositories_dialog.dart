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

import 'package:material_symbols_icons/symbols.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../../widgets/custom_icon.dart';

class ManageRepositoriesDialog extends StatefulWidget {
  const ManageRepositoriesDialog({super.key});

  @override
  State<ManageRepositoriesDialog> createState() => _ManageRepositoriesDialogState();
}

class _ManageRepositoriesDialogState extends State<ManageRepositoriesDialog> {
  int _tab = 0;
  int? _item;
  final List<String> _providers = ["Flatpak", "Pacman"];
  final Map<String, List<String>> _repos = {
    "Flatpak": [
      "https://dl.flathub.org/repo/flathub.flatpakrepo"
    ],
    "Pacman": [
      "multilib",
      "myrepo",
    ],
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = _repos[_providers[_tab]]?.length ?? 0;
    return AlertDialog(
      title: Text("Manage Repositories"),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: 250,
          maxWidth: 400,
          minHeight: 200,
          maxHeight: 300,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("You can add and remove repositories for your Pacman or Flatpak packages here. Only edit them if you know what you're doing."),
            const Gap(16),
            Tabs(
              expand: true,
              index: _tab,
              onChanged: (value) {
                setState(() {
                  _tab = value;
                });
              },
              children: [
                for (final provider in _providers)
                  TabItem(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 8 * theme.scaling,
                      children: [
                        if (provider == "Pacman")
                          CustomIcon(icon: CustomIconType.arch)
                        else if (provider == "Flatpak")
                          CustomIcon(icon: CustomIconType.flatpak)
                        else
                          Icon(Symbols.deployed_code),
                        Text(provider),
                      ],
                    ),
                  ),
              ],
            ),
            const Gap(8),
            Expanded(
              child: OutlinedContainer(
                child: items > 0 ? ListView.builder(
                  padding: EdgeInsets.all(8 * theme.scaling),
                  itemCount: items,
                  itemBuilder: (context, index) {
                    final it = _repos[_providers[_tab]]![index];
                    return SelectedButton(
                      style: const ButtonStyle.ghost(),
                      selectedStyle: const ButtonStyle.primary(),
                      alignment: Alignment.topLeft,
                      value: _item == index,
                      onChanged: (value) => value
                          ? setState(() => _item = index)
                          : setState(() => _item = null),
                      child: Text(it, textAlign: TextAlign.start),
                    );
                  },
                ) : SizedBox.expand(
                  child: Center(
                    child: Text("No repositories yet. Press the 'add' button to get started."),
                  ),
                ),
              ),
            ),
            const Gap(8),
            Row(
              spacing: 8 * theme.scaling,
              children: [
                SecondaryButton(
                  onPressed: _item != null ? () async {
                    final provider = _providers[_tab];
                    final repo = _repos[provider];
                    assert(repo != null);
                    final val = await _editRepository(repo![_item!]);
                    if (val == null || !mounted) return;
                    setState(() => repo[_item!] = val);
                  } : null,
                  size: ButtonSize.small,
                  child: Icon(Icons.edit),
                ),
                Spacer(),
                SecondaryButton(
                  onPressed: _item != null ? () async {
                    final provider = _providers[_tab];
                    final repo = _repos[provider];
                    assert(repo != null);
                    final val = await _removeRepository(repo![_item!]);
                    if (!val || !mounted) return;
                    setState(() {
                      repo.removeAt(_item!);
                      _item = null;
                    });
                  } : null,
                  size: ButtonSize.small,
                  child: Icon(Icons.remove),
                ),
                SecondaryButton(
                  onPressed: () async {
                    final provider = _providers[_tab];
                    final repo = _repos[provider];
                    assert(repo != null);
                    final val = await _addRepository();
                    if (val?.trim().isEmpty ?? true) return;
                    setState(() => repo!.add(val!));
                  },
                  size: ButtonSize.small,
                  child: Icon(Icons.add),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        PrimaryButton(
          child: const Text("Close"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  Future<String?> _addRepository() => showDialog(
    context: context,
    builder: (context) => _AddRepositoryDialog(),
  );

  Future<bool> _removeRepository(String repository) async => await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text("Remove repository"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Are you sure you want to remove the following repository?"),
            const Gap(16),
            SizedBox(
              width: 350,
              child: TextField(
                readOnly: true,
                initialValue: repository,
              ),
            ),
          ],
        ),
        actions: [
          OutlineButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel"),
          ),
          DestructiveButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Remove"),
          )
        ],
      );
    },
  ) ?? false;

  Future<String?> _editRepository(String repository) => showDialog(
    context: context,
    builder: (context) => _EditRepositoryDialog(oldName: repository),
  );
}

class _AddRepositoryDialog extends StatefulWidget {
  const _AddRepositoryDialog();

  @override
  State<_AddRepositoryDialog> createState() => _AddRepositoryDialogState();
}

class _AddRepositoryDialogState extends State<_AddRepositoryDialog> {
  final _controller = TextEditingController(text: "https://");

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Add repository"),
      content: SizedBox(
        width: 350,
        child: TextField(
          controller: _controller,
          placeholder: Text("Repository"),
          autofocus: true,
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
      ),
      actions: [
        OutlineButton(
          child: Text("Cancel"),
          onPressed: () => Navigator.pop(context, null),
        ),
        PrimaryButton(
          child: Text("Add"),
          onPressed: () => Navigator.pop(context, _controller.text),
        ),
      ],
    );
  }
}

class _EditRepositoryDialog extends StatefulWidget {
  final String oldName;

  const _EditRepositoryDialog({required this.oldName});

  @override
  State<_EditRepositoryDialog> createState() => _EditRepositoryDialogState();
}

class _EditRepositoryDialogState extends State<_EditRepositoryDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.oldName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Edit repository"),
      content: SizedBox(
        width: 350,
        child: TextField(
          controller: _controller,
          placeholder: Text("Repository"),
          autofocus: true,
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
      ),
      actions: [
        OutlineButton(
          child: Text("Cancel"),
          onPressed: () => Navigator.pop(context, null),
        ),
        DestructiveButton(
          child: Text("Change"),
          onPressed: () => Navigator.pop(context, _controller.text),
        ),
      ],
    );
  }
}