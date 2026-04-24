import 'package:flutter/material.dart';
import '../models/app_settings.dart';

class SettingsResult {
  final int gridSize;
  final int gameDuration;
  final bool showTextInput;
  final bool showMaxStats;

  const SettingsResult({
    required this.gridSize,
    required this.gameDuration,
    required this.showTextInput,
    required this.showMaxStats,
  });

  void apply() {
    AppSettings.gridSize = gridSize;
    AppSettings.gameDuration = gameDuration;
    AppSettings.showTextInput = showTextInput;
    AppSettings.showMaxStats = showMaxStats;
    AppSettings.save();
  }
}

Future<SettingsResult?> showSettingsDialog(BuildContext context) {
  return showDialog<SettingsResult>(
    context: context,
    builder: (_) => const _SettingsDialog(),
  );
}

class _SettingsDialog extends StatefulWidget {
  const _SettingsDialog();

  @override
  State<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<_SettingsDialog> {
  late double _gridSize;
  late double _seconds;
  late bool _showTextInput;
  late bool _showMaxStats;

  @override
  void initState() {
    super.initState();
    _gridSize = AppSettings.gridSize.toDouble();
    _seconds = AppSettings.gameDuration.toDouble().clamp(10, 300);
    _showTextInput = AppSettings.showTextInput;
    _showMaxStats = AppSettings.showMaxStats;
  }

  String _formatDuration(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    if (m == 0) return '$s s';
    if (sec == 0) return '$m min';
    return '$m min $sec s';
  }

  void _confirm() {
    Navigator.pop(
      context,
      SettingsResult(
        gridSize: _gridSize.round(),
        gameDuration: _seconds.round(),
        showTextInput: _showTextInput,
        showMaxStats: _showMaxStats,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orange = Colors.orange.shade700;
    return AlertDialog(
      title: const Text('Paramètres'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SliderRow(
            label: 'Grille',
            value: '${_gridSize.round()}×${_gridSize.round()}',
            child: Slider(
              min: 2,
              max: 10,
              divisions: 8,
              value: _gridSize,
              activeColor: orange,
              onChanged: (v) => setState(() => _gridSize = v),
            ),
          ),
          _SliderRow(
            label: 'Durée',
            value: _formatDuration(_seconds.round()),
            child: Slider(
              min: 10,
              max: 300,
              divisions: 29,
              value: _seconds,
              activeColor: orange,
              onChanged: (v) => setState(() => _seconds = v),
            ),
          ),
          SwitchListTile(
            title: const Text('Champ de saisie texte'),
            subtitle: const Text('Désactiver sur mobile'),
            value: _showTextInput,
            onChanged: (v) => setState(() => _showTextInput = v),
            activeTrackColor: orange,
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: const Text('Afficher score et mots max'),
            value: _showMaxStats,
            onChanged: (v) => setState(() => _showMaxStats = v),
            activeTrackColor: orange,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(onPressed: _confirm, child: const Text('Appliquer')),
      ],
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final String value;
  final Widget child;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade700,
              ),
            ),
          ],
        ),
        child,
      ],
    );
  }
}
