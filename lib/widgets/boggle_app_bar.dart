import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum BoggleScreen { game, edition, solver, stats }

class BoggleAppBar extends StatelessWidget implements PreferredSizeWidget {
  final BoggleScreen activeScreen;
  final List<Widget> contextual;
  final VoidCallback? onEdition;
  final VoidCallback? onGame;
  final VoidCallback? onStats;
  final VoidCallback? onSettings;

  const BoggleAppBar({
    super.key,
    required this.activeScreen,
    this.contextual = const [],
    this.onEdition,
    this.onGame,
    this.onStats,
    this.onSettings,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isGameArea =
        activeScreen == BoggleScreen.game ||
        activeScreen == BoggleScreen.solver;
    return AppBar(
      automaticallyImplyLeading: false,
      centerTitle: false,
      titleSpacing: 0,
      backgroundColor: AppColors.navBar,
      foregroundColor: Colors.white,
      elevation: 2,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (contextual.isNotEmpty) ...[
            ...contextual,
            Container(
              height: 20,
              width: 1,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              color: Colors.white24,
            ),
          ],
          _icon(
            Icons.grid_on,
            Icons.grid_on_outlined,
            'Grille',
            activeScreen == BoggleScreen.edition,
            onEdition,
          ),
          _icon(
            Icons.sports_esports,
            Icons.sports_esports_outlined,
            'Jouer',
            isGameArea,
            onGame,
          ),
          _icon(
            Icons.leaderboard,
            Icons.leaderboard_outlined,
            'Statistiques',
            activeScreen == BoggleScreen.stats,
            onStats,
          ),
          _icon(
            Icons.settings,
            Icons.settings_outlined,
            'Paramètres',
            false,
            onSettings,
          ),
        ],
      ),
    );
  }

  Widget _icon(
    IconData activeIcon,
    IconData inactiveIcon,
    String tooltip,
    bool isActive,
    VoidCallback? onTap,
  ) {
    return IconButton(
      icon: Icon(isActive ? activeIcon : inactiveIcon),
      tooltip: tooltip,
      color: isActive ? AppColors.primaryOnDark : null,
      disabledColor: isActive ? AppColors.primaryOnDark : null,
      onPressed: onTap,
    );
  }
}

// ─── BoggleHeaderRow ──────────────────────────────────────────────────────────

class BoggleHeaderRow extends StatelessWidget {
  final Widget? leading;
  final Widget? trailing;
  final int score;
  final int? maxScore;
  final int wordCount;
  final int? maxWordCount;

  const BoggleHeaderRow({
    super.key,
    this.leading,
    this.trailing,
    required this.score,
    this.maxScore,
    required this.wordCount,
    this.maxWordCount,
  });

  @override
  Widget build(BuildContext context) {
    final scoreLabel = maxScore != null ? '$score/$maxScore pts' : '$score pts';
    final wordLabel = maxWordCount != null
        ? '$wordCount/$maxWordCount mot${maxWordCount! > 1 ? 's' : ''}'
        : '$wordCount mot${wordCount > 1 ? 's' : ''}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      child: Row(
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 14,
            color: AppColors.primary,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              '$scoreLabel · $wordLabel',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          ?trailing,
          ?leading,
        ],
      ),
    );
  }
}
