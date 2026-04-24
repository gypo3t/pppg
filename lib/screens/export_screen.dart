import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/settings_dialog.dart';

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
    final result = await showSettingsDialog(context);
    if (result != null) result.apply();
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
                color: Colors.grey.shade100,
                border: Border.all(color: Colors.grey.shade300),
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
                      backgroundColor: Colors.orange.shade700,
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
                    foregroundColor: Colors.orange.shade700,
                    side: BorderSide(color: Colors.orange.shade300),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade600, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red.shade700),
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
                    color: Colors.green.shade600,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sauvegardé : $_savedPath',
                      style: TextStyle(
                        color: Colors.green.shade700,
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
