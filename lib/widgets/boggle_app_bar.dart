import 'package:flutter/material.dart';

class BoggleHeaderRow extends StatelessWidget {
  final Widget leading;
  final int score;
  final int? maxScore;
  final int wordCount;
  final int? maxWordCount;

  const BoggleHeaderRow({
    super.key,
    required this.leading,
    required this.score,
    this.maxScore,
    required this.wordCount,
    this.maxWordCount,
  });

  @override
  Widget build(BuildContext context) {
    final scoreLabel =
        maxScore != null ? '$score/$maxScore pts' : '$score pts';
    final wordLabel = maxWordCount != null
        ? '$wordCount/$maxWordCount mot${maxWordCount! > 1 ? 's' : ''}'
        : '$wordCount mot${wordCount > 1 ? 's' : ''}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          leading,
          const Spacer(),
          Icon(Icons.emoji_events_outlined,
              size: 14, color: Colors.orange.shade600),
          const SizedBox(width: 4),
          Text(
            '$scoreLabel  ·  $wordLabel',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
