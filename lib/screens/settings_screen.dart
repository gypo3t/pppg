import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/app_settings.dart';
import '../theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late double _gridSize;
  late double _seconds;
  late bool _showTextInput;
  late bool _showMaxStats;
  String? _version;

  @override
  void initState() {
    super.initState();
    _gridSize = AppSettings.gridSize.toDouble();
    _seconds = AppSettings.gameDuration.toDouble().clamp(10.0, 300.0);
    _showTextInput = AppSettings.showTextInput;
    _showMaxStats = AppSettings.showMaxStats;
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = info.version);
    });
  }

  String _formatDuration(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    if (m == 0) return '$s s';
    if (sec == 0) return '$m min';
    return '$m min $sec s';
  }

  @override
  Widget build(BuildContext context) {
    final orange = AppColors.primary;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: AppColors.navBar,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: ListView(
        children: [
          _SectionHeader('Jeu'),
          _SliderTile(
            label: 'Taille de grille',
            value: '${_gridSize.round()}×${_gridSize.round()}',
            child: Slider(
              min: 2,
              max: 10,
              divisions: 8,
              value: _gridSize,
              activeColor: orange,
              onChanged: (v) => setState(() => _gridSize = v),
              onChangeEnd: (v) {
                AppSettings.gridSize = v.round();
                AppSettings.save();
              },
            ),
          ),
          _SliderTile(
            label: 'Durée de partie',
            value: _formatDuration(_seconds.round()),
            child: Slider(
              min: 10,
              max: 300,
              divisions: 29,
              value: _seconds,
              activeColor: orange,
              onChanged: (v) => setState(() => _seconds = v),
              onChangeEnd: (v) {
                AppSettings.gameDuration = v.round();
                AppSettings.save();
              },
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _SectionHeader('Affichage'),
          SwitchListTile(
            title: const Text('Champ de saisie texte'),
            subtitle: const Text('Désactiver sur mobile'),
            value: _showTextInput,
            activeTrackColor: orange,
            onChanged: (v) {
              setState(() => _showTextInput = v);
              AppSettings.showTextInput = v;
              AppSettings.save();
            },
          ),
          SwitchListTile(
            title: const Text('Afficher score et mots max'),
            value: _showMaxStats,
            activeTrackColor: orange,
            onChanged: (v) {
              setState(() => _showMaxStats = v);
              AppSettings.showMaxStats = v;
              AppSettings.save();
            },
          ),
          const SizedBox(height: 40),
          if (_version != null)
            Text(
              'v$_version',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.black38, fontSize: 12),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 2),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  final String label;
  final String value;
  final Widget child;

  const _SliderTile({
    required this.label,
    required this.value,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(label, style: const TextStyle(fontSize: 14)),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          child,
        ],
      ),
    );
  }
}
