import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/app_settings.dart';
import '../theme/app_colors.dart';
import '../widgets/app_card.dart';

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
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: AppColors.navBar,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppCard.sectionTitle('Jeu', Icons.sports_esports_outlined),
                  const SizedBox(height: 12),
                  AppCard.card(
                    child: Column(
                      children: [
                        _SliderTile(
                          label: 'Taille de grille',
                          value: '${_gridSize.round()}×${_gridSize.round()}',
                          child: Slider(
                            min: 2,
                            max: 10,
                            divisions: 8,
                            value: _gridSize,
                            activeColor: AppColors.primary,
                            onChanged: (v) => setState(() => _gridSize = v),
                            onChangeEnd: (v) {
                              AppSettings.gridSize = v.round();
                              AppSettings.save();
                            },
                          ),
                        ),
                        const Divider(
                          height: 1,
                          indent: 20,
                          endIndent: 20,
                          color: AppColors.cardDivider,
                        ),
                        _SliderTile(
                          label: 'Durée de partie',
                          value: _formatDuration(_seconds.round()),
                          child: Slider(
                            min: 10,
                            max: 300,
                            divisions: 29,
                            value: _seconds,
                            activeColor: AppColors.primary,
                            onChanged: (v) => setState(() => _seconds = v),
                            onChangeEnd: (v) {
                              AppSettings.gameDuration = v.round();
                              AppSettings.save();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  AppCard.sectionTitle('Affichage', Icons.tune_outlined),
                  const SizedBox(height: 12),
                  AppCard.card(
                    child: Column(
                      children: [
                        _SwitchTile(
                          label: 'Champ de saisie texte',
                          subtitle: 'Désactiver sur mobile',
                          value: _showTextInput,
                          onChanged: (v) {
                            setState(() => _showTextInput = v);
                            AppSettings.showTextInput = v;
                            AppSettings.save();
                          },
                        ),
                        const Divider(
                          height: 1,
                          indent: 20,
                          endIndent: 20,
                          color: AppColors.cardDivider,
                        ),
                        _SwitchTile(
                          label: 'Afficher score et mots max',
                          value: _showMaxStats,
                          onChanged: (v) {
                            setState(() => _showMaxStats = v);
                            AppSettings.showMaxStats = v;
                            AppSettings.save();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  if (_version != null)
                    Text(
                      'v$_version',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.black38,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.black87,
                ),
              ),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(
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

class _SwitchTile extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.black87,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.black45,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            activeTrackColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
