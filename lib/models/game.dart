// Model de Game
class Game {
  final String id;
  final String title;
  final String imageUrl;
  final double hours;
  final List<String> genres;

  Game({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.hours,
    required this.genres,
  });
}
