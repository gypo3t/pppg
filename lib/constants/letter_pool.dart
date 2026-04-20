import 'dart:math';

const String letterPool =
    'EEEEEEEEEEAAAAAAAIIIIIIOOOOOONNNNNNSSSSSSTTTTTTRRRRRRLLLLLUUUDDDDGGGBBCCMMPPFFHHVVWWYYKJXQZ';

List<String> generateGrid(int size) {
  final rand = Random();
  return List.generate(size * size, (_) => letterPool[rand.nextInt(letterPool.length)]);
}
