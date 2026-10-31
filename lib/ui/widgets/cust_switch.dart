import 'package:flutter/material.dart';

class CustSwitch extends StatelessWidget {
  const CustSwitch({super.key, this.onChanged, required this.value});
  final void Function(bool)? onChanged;
  final bool value;

  @override
  Widget build(BuildContext context) {
    // Use the active theme's own roles instead of guessing the mode from
    // `primaryColor == Colors.white`, which broke in the dynamic and player
    // themes and left the thumb/track invisible.
    final scheme = Theme.of(context).colorScheme;
    return Switch(
      activeThumbColor: scheme.onPrimary,
      activeTrackColor: scheme.primary,
      inactiveThumbColor: scheme.onSurfaceVariant,
      inactiveTrackColor: scheme.onSurface.withValues(alpha: 0.15),
      value: value,
      onChanged: onChanged,
    );
  }
}
