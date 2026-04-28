import 'dart:math';

const List<String> _officialDice = [
  'AAEEGN', 'ABBJOO', 'ACHOPS', 'AFFKPS',
  'AOOTTW', 'CIMOTU', 'DEILRX', 'DELRVY',
  'DISTTY', 'EEGHNW', 'EEINSU', 'EHRTVW',
  'EIOSST', 'ELRTTY', 'HIMNQU', 'HLNNRZ',
];

List<String> generateGrid(int size) {
  final rand = Random();
  final count = size * size;
  final dice = <String>[];
  while (dice.length < count) {
    final batch = [..._officialDice]..shuffle(rand);
    dice.addAll(batch);
  }
  return dice.take(count).map((die) => die[rand.nextInt(6)]).toList();
}
