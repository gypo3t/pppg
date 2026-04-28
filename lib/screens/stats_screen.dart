import 'package:flutter/material.dart';
import '../models/session_stats.dart';
import '../theme/app_colors.dart';
import '../models/word_path.dart';
import '../services/dictionary_service.dart';
import '../widgets/boggle_app_bar.dart';
import 'settings_screen.dart';
import 'game_screen.dart';
import 'solver_screen.dart';

class StatsScreen extends StatefulWidget {
  final List<WordPath>? words;
  final List<String>? letters;
  final int? gridSize;
  final bool hasGameBelow;

  const StatsScreen({
    super.key,
    this.words,
    this.letters,
    this.gridSize,
    this.hasGameBelow = false,
  });

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BoggleAppBar(
        activeScreen: BoggleScreen.stats,
        onEdition: () => Navigator.of(context).popUntil((r) => r.isFirst),
        onGame: widget.hasGameBelow
            ? () => Navigator.of(context).pop()
            : () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GameScreen()),
                ),
        onSettings: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
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
                  if (widget.words != null && widget.words!.isNotEmpty) ...[
                    _PartyStats(
                      words: widget.words!,
                      letters: widget.letters,
                      gridSize: widget.gridSize,
                    ),
                    const SizedBox(height: 28),
                  ],
                  _SessionGlobalStats(onReset: () => setState(() {})),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Party stats ──────────────────────────────────────────────────────────────

class _PartyStats extends StatelessWidget {
  final List<WordPath> words;
  final List<String>? letters;
  final int? gridSize;

  const _PartyStats({required this.words, this.letters, this.gridSize});

  @override
  Widget build(BuildContext context) {
    final allScore = words.fold<int>(0, (s, w) => s + w.score);
    final found = words.where((w) => w.foundByPlayer).toList();
    final foundScore = found.fold<int>(0, (s, w) => s + w.score);

    final byLength = <int, ({int total, int found})>{};
    for (final w in words) {
      final cur = byLength[w.word.length] ?? (total: 0, found: 0);
      byLength[w.word.length] = (
        total: cur.total + 1,
        found: cur.found + (w.foundByPlayer ? 1 : 0),
      );
    }
    final lengths = byLength.keys.toList()..sort();

    final canShowSolver = letters != null && gridSize != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle('Dernière partie', Icons.sports_esports_outlined),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Solutions possibles',
          icon: Icons.lightbulb_outline,
          total: words.length,
          score: allScore,
          color: AppColors.primary,
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Trouvés par le joueur',
          icon: Icons.check_circle_outline,
          total: found.length,
          score: foundScore,
          color: Colors.teal.shade600,
          refTotal: words.length,
          refScore: allScore,
        ),
        const SizedBox(height: 16),
        _LengthBreakdown(lengths: lengths, byLength: byLength),
        if (canShowSolver) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SolverScreen(
                  words: words,
                  letters: letters!,
                  gridSize: gridSize!,
                  showFoundIndicators: found.isNotEmpty,
                ),
              ),
            ),
            icon: const Icon(Icons.list_alt_outlined),
            label: const Text('Voir les solutions'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primaryBorder),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Session + global stats ───────────────────────────────────────────────────

class _SessionGlobalStats extends StatelessWidget {
  final VoidCallback onReset;
  const _SessionGlobalStats({required this.onReset});

  @override
  Widget build(BuildContext context) {
    final sg = SessionStats.sessionGames;
    final spw = SessionStats.sessionPlayerWords;
    final ssw = SessionStats.sessionSolutionWords;
    final gg = SessionStats.globalGames;
    final gpw = SessionStats.globalPlayerWords;
    final gsw = SessionStats.globalSolutionWords;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle('Session', Icons.history_outlined),
        const SizedBox(height: 12),
        _StatsRow(games: sg, playerWords: spw, solutionWords: ssw),
        const SizedBox(height: 28),
        _sectionTitle('Global', Icons.public_outlined),
        const SizedBox(height: 12),
        _StatsRow(games: gg, playerWords: gpw, solutionWords: gsw),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () async {
            await SessionStats.resetGlobal();
            onReset();
          },
          icon: const Icon(Icons.restart_alt_outlined),
          label: const Text('Réinitialiser les stats globales'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.errorMid,
            side: BorderSide(color: AppColors.errorBorder),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 28),
        _sectionTitle('Dictionnaire', Icons.menu_book_outlined),
        const SizedBox(height: 12),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
            child: Row(
              children: [
                Expanded(
                  child: _Stat(
                    value: DictionaryService.loaded
                        ? '${DictionaryService.wordCount}'
                        : '—',
                    label: 'Mots (3–15 L)',
                    color: Colors.blueGrey.shade600,
                  ),
                ),
                Expanded(
                  child: _Stat(
                    value: 'ODS7',
                    label: 'Source',
                    color: Colors.blueGrey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

Widget _sectionTitle(String title, IconData icon) {
  return Row(
    children: [
      Icon(icon, size: 15, color: AppColors.black45),
      const SizedBox(width: 6),
      Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.black54,
          letterSpacing: 0.5,
        ),
      ),
      const SizedBox(width: 8),
      const Expanded(child: Divider()),
    ],
  );
}

class _StatsRow extends StatelessWidget {
  final int games;
  final int playerWords;
  final int solutionWords;

  const _StatsRow({
    required this.games,
    required this.playerWords,
    required this.solutionWords,
  });

  @override
  Widget build(BuildContext context) {
    final pct = solutionWords > 0
        ? (playerWords / solutionWords * 100).round()
        : null;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
        child: Row(
          children: [
            Expanded(
              child: _Stat(
                value: '$games',
                label: 'Parties',
                color: Colors.blueGrey.shade600,
              ),
            ),
            Expanded(
              child: _Stat(
                value: '$playerWords',
                sub: pct != null ? '$pct %' : null,
                label: 'Mots trouvés',
                color: Colors.teal.shade600,
              ),
            ),
            Expanded(
              child: _Stat(
                value: '$solutionWords',
                label: 'Solutions',
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Cards ────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final int total;
  final int score;
  final Color color;
  final int? refTotal;
  final int? refScore;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.total,
    required this.score,
    required this.color,
    this.refTotal,
    this.refScore,
  });

  @override
  Widget build(BuildContext context) {
    final pctWords =
        refTotal != null && refTotal! > 0 ? (total / refTotal! * 100).round() : null;
    final pctScore =
        refScore != null && refScore! > 0 ? (score / refScore! * 100).round() : null;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    value: '$total',
                    sub: pctWords != null ? '$pctWords %' : null,
                    label: 'Mots',
                    color: color,
                  ),
                ),
                Expanded(
                  child: _Stat(
                    value: '$score pts',
                    sub: pctScore != null ? '$pctScore %' : null,
                    label: 'Score',
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String? sub;
  final String label;
  final Color color;

  const _Stat({
    required this.value,
    required this.label,
    required this.color,
    this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        if (sub != null)
          Text(sub!, style: const TextStyle(fontSize: 12, color: AppColors.black45)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.black54)),
      ],
    );
  }
}

// ─── Breakdown by length ──────────────────────────────────────────────────────

class _LengthBreakdown extends StatelessWidget {
  final List<int> lengths;
  final Map<int, ({int total, int found})> byLength;

  const _LengthBreakdown({required this.lengths, required this.byLength});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bar_chart_outlined, size: 16, color: AppColors.black45),
                SizedBox(width: 6),
                Text(
                  'Détail par longueur',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Table(
              columnWidths: const {
                0: IntrinsicColumnWidth(),
                1: FlexColumnWidth(),
                2: IntrinsicColumnWidth(),
                3: IntrinsicColumnWidth(),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                const TableRow(
                  children: [
                    _TableHeader('Lettres'),
                    _TableHeader(''),
                    _TableHeader('Joueur'),
                    _TableHeader('Total'),
                  ],
                ),
                for (final len in lengths)
                  TableRow(
                    children: [
                      _TableCell('$len L', bold: false),
                      _ProgressCell(
                        value: byLength[len]!.found,
                        max: byLength[len]!.total,
                      ),
                      _TableCell('${byLength[len]!.found}', bold: true),
                      _TableCell('${byLength[len]!.total}',
                          bold: false, muted: true),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String text;
  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(fontSize: 11, color: AppColors.black38),
          textAlign: TextAlign.center,
        ),
      );
}

class _TableCell extends StatelessWidget {
  final String text;
  final bool bold;
  final bool muted;
  const _TableCell(this.text, {required this.bold, this.muted = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: muted ? AppColors.black38 : null,
          ),
        ),
      );
}

class _ProgressCell extends StatelessWidget {
  final int value;
  final int max;
  const _ProgressCell({required this.value, required this.max});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: LinearProgressIndicator(
          value: max > 0 ? value / max : 0,
          backgroundColor: AppColors.primarySurface,
          color: Colors.teal.shade400,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      );
}
