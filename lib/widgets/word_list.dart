import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class WordList extends StatelessWidget {
  final List<String> words;
  final String? selectedWord;
  final void Function(String word)? onWordTap;

  const WordList({
    super.key,
    required this.words,
    this.selectedWord,
    this.onWordTap,
  });

  @override
  Widget build(BuildContext context) {
    if (words.isEmpty) {
      return const Center(
        child: Text(
          'Aucun mot trouvé',
          style: TextStyle(color: AppColors.grey, fontStyle: FontStyle.italic),
        ),
      );
    }

    return ListView.separated(
      itemCount: words.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final word = words[index];
        final selected = word == selectedWord;
        return ListTile(
          dense: true,
          selected: selected,
          title: Text(
            word,
            style: TextStyle(
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              letterSpacing: 1.5,
            ),
          ),
          trailing: Text(
            '${word.length} pts',
            style: TextStyle(
              color: selected ? AppColors.primary : AppColors.grey,
              fontSize: 12,
            ),
          ),
          onTap: onWordTap != null ? () => onWordTap!(word) : null,
        );
      },
    );
  }
}
