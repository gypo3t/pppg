import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:flutter/services.dart';
import 'settings_screen.dart';

class ExportScreen extends StatefulWidget {
  final List<String> letters;
  final int gridSize;

  const ExportScreen({
    super.key,
    required this.letters,
    required this.gridSize,
  });

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  late final TextEditingController _pathCtrl;
  bool _saved = false;
  String? _savedPath;
  String? _error;

  @override
  void initState() {
    super.initState();
    final home = Platform.environment['HOME'] ?? '.';
    final now = DateTime.now();
    final ts = '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}'
        '_${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}';
    _pathCtrl = TextEditingController(text: '$home/boggle_$ts.txt');
  }

  @override
  void dispose() {
    _pathCtrl.dispose();
    super.dispose();
  }

  String get _gridContent {
    final n = widget.gridSize;
    final rows = List.generate(
      n,
      (r) => widget.letters.sublist(r * n, r * n + n).join(),
    );
    return rows.join('\n');
  }

  Future<void> _save() async {
    final raw = _pathCtrl.text.trim();
    if (raw.isEmpty) return;
    final path = raw.startsWith('~')
        ? raw.replaceFirst('~', Platform.environment['HOME'] ?? '')
        : raw;
    try {
      await File(path).writeAsString(_gridContent);
      setState(() {
        _saved = true;
        _savedPath = path;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur : $e';
        _saved = false;
      });
    }
  }

  Future<void> _openSettings() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exporter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Paramètres',
            onPressed: _openSettings,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Contenu de la grille :',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                border: Border.all(color: AppColors.grey300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _gridContent,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 22,
                  letterSpacing: 6,
                  height: 1.8,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _pathCtrl,
              decoration: const InputDecoration(
                labelText: 'Chemin de sauvegarde',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save),
                    label: const Text('Sauvegarder'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => Clipboard.setData(
                    ClipboardData(text: _gridContent),
                  ),
                  icon: const Icon(Icons.copy),
                  label: const Text('Copier'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primaryBorder),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.error_outline, color: AppColors.errorMid, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ],
            if (_saved && _savedPath != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sauvegardé : $_savedPath',
                      style: TextStyle(
                        color: AppColors.successDark,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
