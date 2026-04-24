import 'package:flutter/material.dart';
import '../models/session_stats.dart';
import '../services/dictionary_service.dart';

class StatsCard extends StatefulWidget {
  const StatsCard({super.key});

  @override
  State<StatsCard> createState() => _StatsCardState();
}

class _StatsCardState extends State<StatsCard> {
  @override
  void initState() {
    super.initState();
    if (!DictionaryService.loaded) {
      DictionaryService.load().then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            _sectionLabel('Session'),
            const SizedBox(height: 12),
            _statsRow(
              games: SessionStats.sessionGames,
              playerWords: SessionStats.sessionPlayerWords,
              solutionWords: SessionStats.sessionSolutionWords,
            ),
            const Divider(height: 24),
            _sectionLabel('Total'),
            const SizedBox(height: 12),
            _statsRow(
              games: SessionStats.globalGames,
              playerWords: SessionStats.globalPlayerWords,
              solutionWords: SessionStats.globalSolutionWords,
            ),
            const Divider(height: 24),
            if (DictionaryService.loaded)
              Text(
                'Dictionnaire : ${DictionaryService.wordCount} mots',
                style: const TextStyle(fontSize: 12, color: Colors.black45),
              )
            else
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox.square(
                    dimension: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Chargement du dictionnaire…',
                    style: TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: Colors.black54,
      ),
    );
  }

  Widget _statsRow({
    required int games,
    required int playerWords,
    required int solutionWords,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _StatItem(
          label: 'Parties',
          value: '$games',
          icon: Icons.sports_esports_outlined,
        ),
        _StatItem(
          label: 'Mots trouvés',
          value: '$playerWords',
          icon: Icons.check_circle_outline,
        ),
        _StatItem(
          label: 'Solutions',
          value: games > 0 ? '$solutionWords' : '—',
          icon: Icons.lightbulb_outline,
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Colors.orange.shade600),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
      ],
    );
  }
}
