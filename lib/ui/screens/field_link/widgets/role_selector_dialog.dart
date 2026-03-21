import 'package:flutter/material.dart';
import 'package:red_grid_link/data/models/team_role.dart';
import 'package:red_grid_link/ui/common/role_icon.dart';

/// Result returned by [RoleSelectorDialog] on confirm.
class RoleSelection {
  final TeamRole role;
  final String? customLabel;

  const RoleSelection({required this.role, this.customLabel});
}

/// Dialog that lets the user pick a [TeamRole] with radio buttons.
///
/// If [TeamRole.custom] is selected, a text field appears for the custom label.
/// Returns a [RoleSelection] on confirm, or `null` on cancel.
class RoleSelectorDialog extends StatefulWidget {
  final TeamRole initialRole;
  final String? initialCustomLabel;

  const RoleSelectorDialog({
    super.key,
    this.initialRole = TeamRole.scout,
    this.initialCustomLabel,
  });

  @override
  State<RoleSelectorDialog> createState() => _RoleSelectorDialogState();
}

class _RoleSelectorDialogState extends State<RoleSelectorDialog> {
  late TeamRole _selected;
  late TextEditingController _customController;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialRole;
    _customController =
        TextEditingController(text: widget.initialCustomLabel ?? '');
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text('SELECT ROLE', style: theme.textTheme.titleMedium),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final role in TeamRole.values)
            RadioListTile<TeamRole>(
              value: role,
              groupValue: _selected,
              onChanged: (value) {
                if (value != null) setState(() => _selected = value);
              },
              title: Row(
                children: [
                  Icon(iconForRole(role), size: 20),
                  const SizedBox(width: 8),
                  Text(role.displayName),
                ],
              ),
              dense: true,
            ),
          if (_selected == TeamRole.custom) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _customController,
              decoration: const InputDecoration(
                labelText: 'Custom role label',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              maxLength: 20,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('CANCEL'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(
              RoleSelection(
                role: _selected,
                customLabel: _selected == TeamRole.custom
                    ? _customController.text
                    : null,
              ),
            );
          },
          child: const Text('CONFIRM'),
        ),
      ],
    );
  }
}
