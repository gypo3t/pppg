import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/dictionary_service.dart';
import '../widgets/menu_row.dart' show popItem;
import '../widgets/settings_dialog.dart';
import '../widgets/stats_card.dart';
import 'edition_screen.dart';
import 'game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _version;

  @override
  void initState() {
    super.initState();
    DictionaryService.load().then((_) {
      if (mounted) setState(() {});
    });
    PackageInfo.fromPlatform().then((info) {
      if (mounted) {
        setState(() {
          _version = kDebugMode
              ? 'v${info.version} (build ${info.buildNumber})'
              : 'v${info.version}';
        });
      }
    });
  }

  Future<void> _openSettings() async {
    final result = await showSettingsDialog(context);
    if (result != null) {
      result.apply();
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.grid_4x4, size: 18),
            SizedBox(width: 8),
            Text('Boggle'),
          ],
        ),
        actions: [
          PopupMenuButton<void>(
            icon: const Icon(Icons.menu),
            itemBuilder: (_) => [
              popItem(Icons.sports_esports_outlined, 'Jouer', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GameScreen()),
                ).then((_) { if (mounted) setState(() {}); });
              }),
              popItem(Icons.grid_on_outlined, 'Éditer la grille', () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditionScreen()),
              )),
              const PopupMenuDivider(),
              popItem(Icons.settings_outlined, 'Paramètres', _openSettings),
            ],
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StatsCard(),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GameScreen()),
                  ).then((_) {
                    if (mounted) setState(() {});
                  }),
                  icon: const Icon(Icons.sports_esports),
                  label: const Text('Jouer'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditionScreen()),
                  ),
                  icon: const Icon(Icons.grid_on_outlined),
                  label: const Text('Éditer la grille'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: Colors.orange.shade700,
                    side: BorderSide(color: Colors.orange.shade300),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
                if (_version != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _version!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, color: Colors.black38),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
