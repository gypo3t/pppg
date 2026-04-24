import 'package:flutter/material.dart';

class MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const MenuRow(this.icon, this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}

/// Compact [PopupMenuItem] with height 40 and a [MenuRow] child.
PopupMenuItem<void> popItem(
  IconData icon,
  String label,
  VoidCallback? onTap, {
  bool enabled = true,
}) =>
    PopupMenuItem<void>(
      onTap: onTap,
      enabled: enabled,
      height: 40,
      child: MenuRow(icon, label),
    );
