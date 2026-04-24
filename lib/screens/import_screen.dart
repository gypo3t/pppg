import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../widgets/settings_dialog.dart';

class ImportScreen extends StatefulWidget {
  final int expectedSize;
  final int gridN;

  const ImportScreen({
    super.key,
    required this.expectedSize,
    required this.gridN,
  });

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final _pathCtrl = TextEditingController();
  List<String>? _preview;
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _pathCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final raw = _pathCtrl.text.trim();
    if (raw.isEmpty) return;
    final path = raw.startsWith('~')
        ? raw.replaceFirst('~', Platform.environment['HOME'] ?? '')
        : raw;

    setState(() {
      _loading = true;
      _error = null;
      _preview = null;
    });

    final file = File(path);
    if (!file.existsSync()) {
      setState(() {
        _loading = false;
        _error = 'Fichier introuvable : $path';
      });
      return;
    }

    String content;
    try {
      content = await file.readAsString();
    } catch (_) {
      try {
        content = await file.readAsString(encoding: latin1);
      } catch (e) {
        setState(() {
          _loading = false;
          _error = 'Erreur de lecture : $e';
        });
        return;
      }
    }

    final letters = content
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z]'), '')
        .split('');

    if (letters.length < widget.expectedSize) {
      setState(() {
        _loading = false;
        _error =
            'Pas assez de lettres'
            ' (${letters.length} / ${widget.expectedSize} attendues)';
      });
      return;
    }

    setState(() {
      _loading = false;
      _preview = letters.sublist(0, widget.expectedSize);
    });
  }

  void _confirm() {
    if (_preview != null) Navigator.pop(context, _preview);
  }

  Future<void> _openSettings() async {
    final result = await showSettingsDialog(context);
    if (result != null) result.apply();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Importer'),
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
            TextField(
              controller: _pathCtrl,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Chemin du fichier',
                hintText: '~/grille.txt',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _loading ? null : _load,
                ),
              ),
              onSubmitted: (_) => _load(),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loading ? null : _load,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _loading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Charger'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Colors.red.shade700),
              ),
            ],
            if (_preview != null) ...[
              const SizedBox(height: 28),
              const Text(
                'Aperçu :',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 12),
              Center(
                child: _GridPreview(
                  letters: _preview!,
                  gridN: widget.gridN,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _confirm,
                icon: const Icon(Icons.check),
                label: const Text('Importer cette grille'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GridPreview extends StatelessWidget {
  final List<String> letters;
  final int gridN;

  const _GridPreview({required this.letters, required this.gridN});

  int _guessN(int count) {
    for (int n = 2; n <= 10; n++) {
      if (n * n == count) return n;
    }
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    final n = gridN > 0 ? gridN : _guessN(letters.length);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: n,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
        ),
        itemCount: letters.length,
        itemBuilder: (_, i) => Container(
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            border: Border.all(color: Colors.orange.shade300),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Text(
            letters[i],
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }
}
