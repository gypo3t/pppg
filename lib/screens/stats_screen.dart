import 'package:flutter/material.dart';
import '../models/session_stats.dart';
import '../theme/app_colors.dart';
import '../models/word_path.dart';
import '../services/dictionary_service.dart';
import '../route_observer.dart';
import '../widgets/app_card.dart';
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

class _StatsScreenState extends State<StatsScreen> with RouteAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: BoggleAppBar(
        activeScreen: BoggleScreen.stats,
        onEdition: () => Navigator.of(context).popUntil((r) => r.isFirst),
        onGame: widget.hasGameBelow
            ? () => Navigator.of(context).pop()
            : () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GameScreen()),
              ),
        onSettings: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        ),
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
                  _DictionarySection(),
                  const SizedBox(height: 28),
                  if (widget.words != null && widget.words!.isNotEmpty) ...[
                    _PartyStats(
                      words: widget.words!,
                      letters: widget.letters,
                      gridSize: widget.gridSize,
                    ),
                    const SizedBox(height: 28),
                  ],

                  _GameHistorySection(onReset: () => setState(() {})),
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
        AppCard.sectionTitle('Dernière partie', Icons.sports_esports_outlined),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Solutions possibles',
          icon: Icons.lightbulb_outline,
          total: words.length,
          score: allScore,
          color: AppColors.primary,
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Trouvés par le joueur',
          icon: Icons.check_circle_outline,
          total: found.length,
          score: foundScore,
          color: const Color(0xFF00695C),
          refTotal: words.length,
          refScore: allScore,
        ),
        const SizedBox(height: 12),
        _LengthBreakdown(lengths: lengths, byLength: byLength),
        if (canShowSolver) ...[
          const SizedBox(height: 12),
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
              side: BorderSide(color: AppColors.primaryBorder, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Game history ─────────────────────────────────────────────────────────────

class _GameHistorySection extends StatelessWidget {
  final VoidCallback onReset;
  const _GameHistorySection({required this.onReset});

  @override
  Widget build(BuildContext context) {
    final history = SessionStats.gameHistory.reversed.toList();
    // Les recentGames couvrent les N dernières entrées de gameHistory
    final recentCount = SessionStats.recentGames.length;
    final historyCount = history.length;
    // index i dans history (0 = plus récent) → recentGames[recentCount - 1 - i]
    RecentGame? recentFor(int i) {
      final ri = recentCount - 1 - i;
      if (ri < 0 || ri >= recentCount) return null;
      final hi = historyCount - 1 - i;
      if (hi < historyCount - recentCount) return null;
      return SessionStats.recentGames[ri];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard.sectionTitle('Historique', Icons.history_outlined),
        const SizedBox(height: 12),
        if (history.isEmpty)
          AppCard.card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Aucune partie enregistrée',
                  style: TextStyle(fontSize: 13, color: AppColors.black45),
                ),
              ),
            ),
          )
        else ...[
          AppCard.card(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Row(
                    children: const [
                      Expanded(flex: 3, child: _ColHeader('Date')),
                      Expanded(flex: 3, child: _ColHeader('Mots')),
                      Expanded(flex: 3, child: _ColHeader('Score')),
                      Expanded(flex: 2, child: _ColHeader('%')),
                      SizedBox(width: 16),
                    ],
                  ),
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFE0D8CC),
                ),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: history.length,
                  separatorBuilder: (_, _) => const Divider(
                    height: 1,
                    thickness: 1,
                    indent: 16,
                    endIndent: 16,
                    color: AppColors.cardDivider,
                  ),
                  itemBuilder: (context, i) {
                    final r = history[i];
                    final recent = recentFor(i);
                    final wordPct = r.solutionWords > 0
                        ? (r.playerWords / r.solutionWords * 100).round()
                        : 0;
                    final scorePct = r.totalScore > 0
                        ? (r.playerScore / r.totalScore * 100).round()
                        : 0;
                    final pct = ((wordPct + scorePct) / 2).round();
                    return InkWell(
                      borderRadius: BorderRadius.circular(4),
                      onTap: recent == null
                          ? null
                          : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SolverScreen(
                                  words: recent.words,
                                  letters: recent.letters,
                                  gridSize: recent.gridSize,
                                  showFoundIndicators: r.playerWords > 0,
                                ),
                              ),
                            ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                _formatDate(r.timestamp),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.black54,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                '${r.playerWords}/${r.solutionWords}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF00695C),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                '${r.playerScore}/${r.totalScore}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '$pct %',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _pctColor(pct),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: recent != null
                                  ? AppColors.black38
                                  : Colors.transparent,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              await SessionStats.resetGlobal();
              onReset();
            },
            icon: const Icon(Icons.restart_alt_outlined),
            label: const Text('Réinitialiser l\'historique'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.errorMid,
              side: BorderSide(color: AppColors.errorBorder, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ],
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'jan',
      'fév',
      'mar',
      'avr',
      'mai',
      'jun',
      'jul',
      'aoû',
      'sep',
      'oct',
      'nov',
      'déc',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.hour}h${dt.minute.toString().padLeft(2, '0')}';
  }

  Color _pctColor(int pct) {
    if (pct >= 70) return const Color(0xFF2E7D32);
    if (pct >= 40) return const Color(0xFFE65100);
    return AppColors.black45;
  }
}

// ─── Dictionary ───────────────────────────────────────────────────────────────

class _DictionarySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard.sectionTitle('Dictionnaire', Icons.menu_book_outlined),
        const SizedBox(height: 12),
        AppCard.card(
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
                    color: const Color(0xFF37474F),
                  ),
                ),
                Expanded(
                  child: _Stat(
                    value: 'ODS7',
                    label: 'Source',
                    color: const Color(0xFF37474F),
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

class _ColHeader extends StatelessWidget {
  final String text;
  const _ColHeader(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      color: AppColors.black38,
      letterSpacing: 0.5,
    ),
    textAlign: TextAlign.center,
  );
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
          Text(
            sub!,
            style: const TextStyle(fontSize: 12, color: AppColors.black45),
          ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.black54),
        ),
      ],
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
    final pctWords = refTotal != null && refTotal! > 0
        ? (total / refTotal! * 100).round()
        : null;
    final pctScore = refScore != null && refScore! > 0
        ? (score / refScore! * 100).round()
        : null;

    return AppCard.card(
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
                    fontWeight: FontWeight.w700,
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

// ─── Breakdown by length ──────────────────────────────────────────────────────

class _LengthBreakdown extends StatelessWidget {
  final List<int> lengths;
  final Map<int, ({int total, int found})> byLength;

  const _LengthBreakdown({required this.lengths, required this.byLength});

  @override
  Widget build(BuildContext context) {
    return AppCard.card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.bar_chart_outlined,
                  size: 16,
                  color: AppColors.black54,
                ),
                SizedBox(width: 6),
                Text(
                  'Détail par longueur',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black87,
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
                      _TableCell(
                        '${byLength[len]!.total}',
                        bold: false,
                        muted: true,
                      ),
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
        color: muted ? AppColors.black38 : AppColors.black87,
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
      backgroundColor: const Color(0xFFE8DFD0),
      color: const Color(0xFF00695C),
      minHeight: 6,
      borderRadius: BorderRadius.circular(3),
    ),
  );
}
