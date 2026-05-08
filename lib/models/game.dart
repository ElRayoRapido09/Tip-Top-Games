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
    final appId = data['appid'] as int;
    final title = data['name'] as String;
    final hours = (data['playtime_forever'] as int) / 60.0;

    // Clasificar géneros automáticamente basado en nombre y tiempo
    final genres = _classifyGenres(title, hours);

    return Game(
      id: appId.toString(),
      appId: appId,
      title: title,
      imageUrl:
          'https://cdn.akamai.steamstatic.com/steam/apps/$appId/header.jpg',
      hours: hours,
      genres: genres,
    );
  }

  /// Clasificar géneros automáticamente basado en el nombre del juego y tiempo jugado
  static List<String> _classifyGenres(String title, double hours) {
    final genres = <String>{};
    final titleLower = title.toLowerCase();

    // Mapeo de palabras clave a géneros
    final genreKeywords = {
      'Acción': [
        'call of duty',
        'battlefield',
        'counter-strike',
        'valorant',
        'apex',
        'fortnite',
        'doom',
        'dying light',
        'action',
        'shooting',
        'combat',
        'fps',
      ],
      'Relajante': [
        'stardew',
        'animal crossing',
        'slime rancher',
        'cozy',
        'chill',
        'relaxing',
        'puzzle',
        'pastel',
        'zen',
      ],
      'Competitivo': [
        'league of legends',
        'dota 2',
        'overwatch',
        'rocket league',
        'csgo',
        'competitive',
        'esports',
        'ranked',
        'pvp',
      ],
      'Shooter': [
        'call of duty',
        'battlefield',
        'counter-strike',
        'valorant',
        'destiny',
        'borderlands',
        'halo',
        'apex',
        'fortnite',
        'shooter',
        'fps',
        'battle royale',
        'gun',
        'weapon',
      ],
      'RPG': [
        'the witcher',
        'baldur\'s gate',
        'elden ring',
        'dark souls',
        'skyrim',
        'fallout',
        'final fantasy',
        'kingdom hearts',
        'dragon quest',
        'persona',
        'fire emblem',
        'rpg',
        'fantasy',
        'quest',
        'adventure',
        'role-playing',
      ],
      'Plataformas': [
        'super mario',
        'sonic',
        'hollow knight',
        'celeste',
        'platformer',
        'platform',
        'jumping',
        'jump',
        'side-scroller',
      ],
    };

    // Buscar palabras clave en el título
    for (final entry in genreKeywords.entries) {
      for (final keyword in entry.value) {
        if (titleLower.contains(keyword)) {
          genres.add(entry.key);
        }
      }
    }

    // Si no se detectó ningún género, clasificar por tiempo de juego
    if (genres.isEmpty) {
      if (hours < 5) {
        genres.add('Relajante');
      } else if (hours < 20) {
        genres.add('Plataformas');
      } else if (hours < 100) {
        genres.add('RPG');
      } else {
        genres.add('Competitivo');
      }
    }

    return genres.toList();
  }
}
