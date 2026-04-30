// Model de Game
class Game {
  final String id;
  final String title;
  final String imageUrl;
  final double hours;
  final List<String> genres;
  final int appId; // Steam App ID

  Game({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.hours,
    required this.genres,
    required this.appId,
  });

  // Factory constructor para crear desde datos de Steam
  factory Game.fromSteamData(Map<String, dynamic> data) {
    return Game(
      id: data['appid'].toString(),
      appId: data['appid'] as int,
      title: data['name'] as String,
      imageUrl:
          'https://cdn.akamai.steamstatic.com/steam/apps/${data['appid']}/header.jpg',
      hours: (data['playtime_forever'] as int) / 60.0,
      genres: [],
    );
  }
}
