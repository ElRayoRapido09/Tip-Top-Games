import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/game.dart';
import '../models/game_details.dart';

class SteamApiService {
  static const String _steamApiBase = 'https://api.steampowered.com';
  static const String _communityUrl = 'https://steamcommunity.com/profiles';
  static const String _proxyUrl = String.fromEnvironment(
    'STEAM_PROXY_URL',
    defaultValue: 'http://localhost:8765',
  );
  static const String _storeApiBase = 'https://store.steampowered.com/api';
  static const String _apiKey = String.fromEnvironment(
    'STEAM_API_KEY',
    defaultValue: '',
  );

  /// En web el navegador bloquea Steam por CORS; móvil/escritorio van directo.
  static bool get usesProxy => kIsWeb;

  static void _ensureApiKey() {
    if (!usesProxy && _apiKey.isEmpty) {
      throw Exception(
        'Falta STEAM_API_KEY. Compila con: '
        'flutter run --dart-define=STEAM_API_KEY=tu_clave_steam',
      );
    }
  }

  /// Obtener la biblioteca de juegos del usuario
  Future<List<Game>> getUserLibrary(String steamId) async {
    try {
      final url = usesProxy
          ? Uri.parse('$_proxyUrl/library?steamid=$steamId')
          : Uri.parse(
              '$_steamApiBase/IPlayerService/GetOwnedGames/v1/'
              '?steamid=$steamId'
              '&include_appinfo=true'
              '&include_played_free_games=true'
              '&key=$_apiKey',
            );

      _ensureApiKey();
      final response = await http.get(url).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final games = (data['response']['games'] ?? []) as List;

        return games
            .map(
              (gameData) =>
                  Game.fromSteamData(gameData as Map<String, dynamic>),
            )
            .toList();
      } else {
        throw Exception('Error al obtener biblioteca (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error al conectar con Steam API: $e');
    }
  }

  /// Obtener información del usuario de Steam
  Future<Map<String, dynamic>> getUserInfo(String steamId) async {
    try {
      final url = usesProxy
          ? Uri.parse('$_proxyUrl/userinfo?steamid=$steamId')
          : Uri.parse(
              '$_steamApiBase/ISteamUser/GetPlayerSummaries/v2/'
              '?steamids=$steamId'
              '&key=$_apiKey',
            );

      _ensureApiKey();
      final response = await http.get(url).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final players = (data['response']['players'] ?? []) as List;

        if (players.isNotEmpty) {
          return players[0] as Map<String, dynamic>;
        }
        throw Exception('Usuario no encontrado');
      } else {
        throw Exception(
          'Error al obtener información del usuario (${response.statusCode})',
        );
      }
    } catch (e) {
      throw Exception('Error al conectar con Steam API: $e');
    }
  }

  /// Resolver vanity URL de Steam a Steam ID
  Future<String?> resolveVanityUrl(String vanityUrl) async {
    try {
      final url = usesProxy
          ? Uri.parse('$_proxyUrl/vanityurl?vanityurl=$vanityUrl')
          : Uri.parse(
              '$_steamApiBase/ISteamUser/ResolveVanityURL/v1/'
              '?vanityurl=$vanityUrl'
              '&key=$_apiKey',
            );

      _ensureApiKey();
      final response = await http.get(url).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['response']['success'] == 1) {
          return data['response']['steamid'].toString();
        }
      }
      return null;
    } catch (e) {
      throw Exception('Error al resolver vanity URL: $e');
    }
  }

  /// Obtener URL del perfil de Steam
  static String getProfileUrl(String steamId) {
    return '$_communityUrl/$steamId';
  }

  /// Descripción, espacio en disco y logros del juego.
  /// La descripción y el tamaño no dependen del perfil público.
  /// La lista de logros se obtiene por API de Steam; el progreso personal
  /// solo si el perfil es público.
  Future<GameExtendedDetails> getGameExtendedDetails({
    required String steamId,
    required int appId,
  }) async {
    final storeData = await _fetchStoreAppData(appId);
    var store = _parseStoreAppData(storeData);

    if (store.storageRequirement == null) {
      final fullStore = await _fetchFullStoreData(appId);
      if (fullStore != null) {
        final pcReq = fullStore['pc_requirements'] as Map<String, dynamic>?;
        final storage = _parseStorageRequirement(
              pcReq?['minimum'] as String?,
            ) ??
            _parseStorageRequirement(pcReq?['recommended'] as String?);
        if (storage != null) {
          store = _StoreDetails(
            description: store.description,
            storageRequirement: storage,
            storeAchievements: store.storeAchievements ??
                (fullStore['achievements'] is Map<String, dynamic>
                    ? _AchievementBundle.fromStoreAchievements(
                        fullStore['achievements'] as Map<String, dynamic>,
                      )
                    : null),
          );
        }
      }
    }

    var achievements = await _fetchAchievements(steamId, appId);

    // Lista completa desde API; si falla, usar logros de la tienda (gamedetails).
    if (!achievements.hasItems && store.storeAchievements != null) {
      achievements = store.storeAchievements!;
    }

    if (!achievements.hasItems) {
      achievements = const _AchievementBundle(
        note: 'Este juego no tiene logros en Steam',
      );
    }

    return GameExtendedDetails(
      description: store.description,
      storageRequirement: store.storageRequirement,
      achievements: achievements.items,
      unlockedCount: achievements.unlockedCount,
      totalCount: achievements.totalCount,
      achievementsNote: achievements.note,
    );
  }

  /// Tienda Steam (proxy nuevo o llamada directa; no requiere perfil público).
  Future<Map<String, dynamic>?> _fetchStoreAppData(int appId) async {
    final urls = <String>[
      if (usesProxy) '$_proxyUrl/gamedetails?appid=$appId',
      '$_storeApiBase/appdetails?appids=$appId&l=spanish',
      '$_storeApiBase/appdetails?appids=$appId&l=english',
    ];

    for (final url in urls) {
      try {
        final response =
            await http.get(Uri.parse(url)).timeout(const Duration(seconds: 20));
        if (response.statusCode != 200) continue;

        final root = jsonDecode(response.body) as Map<String, dynamic>;

        if (root.containsKey('description') ||
            root.containsKey('storageRequirement') ||
            root.containsKey('achievements')) {
          return root;
        }

        final app = root[appId.toString()] as Map<String, dynamic>?;
        if (app != null && app['success'] == true) {
          return app['data'] as Map<String, dynamic>?;
        }
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  /// Datos completos de la tienda (incluye pc_requirements).
  Future<Map<String, dynamic>?> _fetchFullStoreData(int appId) async {
    for (final lang in ['spanish', 'english']) {
      try {
        final response = await http
            .get(
              Uri.parse(
                '$_storeApiBase/appdetails?appids=$appId&l=$lang',
              ),
            )
            .timeout(const Duration(seconds: 20));
        if (response.statusCode != 200) continue;
        final root = jsonDecode(response.body) as Map<String, dynamic>;
        final app = root[appId.toString()] as Map<String, dynamic>?;
        if (app != null && app['success'] == true) {
          return app['data'] as Map<String, dynamic>?;
        }
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  _StoreDetails _parseStoreAppData(Map<String, dynamic>? data) {
    if (data == null) return const _StoreDetails();

    String? description = data['description'] as String?;
    String? storage = data['storageRequirement'] as String?;

    if (description == null && data.containsKey('short_description')) {
      final short = data['short_description'] as String? ?? '';
      final about = data['about_the_game'] as String? ?? '';
      description = short.trim().isNotEmpty ? short.trim() : _stripHtml(about);
      if (description.isEmpty) description = null;
    }

    if (storage == null) {
      final pcReq = data['pc_requirements'] as Map<String, dynamic>?;
      storage = _parseStorageRequirement(pcReq?['minimum'] as String?) ??
          _parseStorageRequirement(pcReq?['recommended'] as String?);
    }

    _AchievementBundle? storeAchievements;
    final achRaw = data['achievements'];
    if (achRaw is Map<String, dynamic>) {
      storeAchievements = _AchievementBundle.fromStoreAchievements(achRaw);
    }

    return _StoreDetails(
      description: description,
      storageRequirement: storage,
      storeAchievements: storeAchievements,
    );
  }

  Future<_AchievementBundle> _fetchAchievements(String steamId, int appId) async {
    try {
      if (usesProxy) {
        final url = Uri.parse(
          '$_proxyUrl/achievements?steamid=$steamId&appid=$appId',
        );
        final response =
            await http.get(url).timeout(const Duration(seconds: 20));
        if (response.statusCode == 200) {
          final bundle = _AchievementBundle.fromProxyJson(
            jsonDecode(response.body) as Map<String, dynamic>,
          );
          if (bundle.hasItems) return bundle;
        }
      } else {
        _ensureApiKey();
        final schemaUrl = Uri.parse(
          '$_steamApiBase/ISteamUserStats/GetSchemaForGame/v2/'
          '?key=$_apiKey&appid=$appId&l=spanish',
        );
        final playerUrl = Uri.parse(
          '$_steamApiBase/ISteamUserStats/GetPlayerAchievements/v1/'
          '?key=$_apiKey&steamid=$steamId&appid=$appId&l=spanish',
        );

        final responses = await Future.wait([
          http.get(schemaUrl).timeout(const Duration(seconds: 20)),
          http.get(playerUrl).timeout(const Duration(seconds: 20)),
        ]);

        final bundle = _AchievementBundle.mergeSchemaAndPlayer(
          schemaBody: responses[0].statusCode == 200
              ? jsonDecode(responses[0].body) as Map<String, dynamic>
              : null,
          playerBody: responses[1].statusCode == 200
              ? jsonDecode(responses[1].body) as Map<String, dynamic>
              : null,
        );
        if (bundle.hasItems) return bundle;
      }
    } catch (_) {
      // Continuar al respaldo de la tienda
    }

    return const _AchievementBundle();
  }

  static String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>', multiLine: true), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String? _parseStorageRequirement(String? html) {
    if (html == null || html.isEmpty) return null;
    final plain = _stripHtml(html);
    final match = RegExp(
      r'(?:Almacenamiento|Storage)\s*:\s*(.+?)(?:\s{2,}|$)',
      caseSensitive: false,
    ).firstMatch(plain);
    return match?.group(1)?.trim();
  }

  /// Comprueba proxy (solo aplica en web).
  static Future<bool> checkProxyHealth() async {
    if (!usesProxy) return true;

    try {
      final response = await http
          .get(Uri.parse('$_proxyUrl/health'))
          .timeout(const Duration(seconds: 2));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

class _StoreDetails {
  final String? description;
  final String? storageRequirement;
  final _AchievementBundle? storeAchievements;

  const _StoreDetails({
    this.description,
    this.storageRequirement,
    this.storeAchievements,
  });
}

class _AchievementBundle {
  final List<GameAchievement> items;
  final int unlockedCount;
  final int totalCount;
  final String? note;

  const _AchievementBundle({
    this.items = const [],
    this.unlockedCount = 0,
    this.totalCount = 0,
    this.note,
  });

  bool get hasItems => totalCount > 0 || items.isNotEmpty;

  factory _AchievementBundle.fromStoreAchievements(Map<String, dynamic> data) {
    final total = data['total'] as int? ?? 0;
    final highlighted =
        (data['highlighted'] as List? ?? []).cast<Map<String, dynamic>>();

    if (total <= 0) return const _AchievementBundle();

    if (highlighted.isEmpty) {
      return _AchievementBundle(
        totalCount: total,
        note:
            'Este juego tiene $total logros en Steam. Con perfil privado no se muestra la lista completa; pon el perfil en público o reinicia el proxy actualizado.',
      );
    }

    final items = highlighted
        .map(
          (h) => GameAchievement(
            apiName: h['name'] as String? ?? '',
            displayName: (h['localized_name'] as String? ??
                    h['name'] as String? ??
                    '')
                .trim(),
            description: '',
            unlocked: false,
          ),
        )
        .toList();

    String? note;
    if (total > items.length) {
      note =
          'Perfil privado: no se puede ver cuántos llevas desbloqueados. '
          'Mostrando ${items.length} logros destacados de $total en total.';
    } else {
      note =
          'Perfil privado: no se puede ver tu progreso de logros desbloqueados.';
    }

    return _AchievementBundle(
      items: items,
      unlockedCount: 0,
      totalCount: total,
      note: note,
    );
  }

  factory _AchievementBundle.fromProxyJson(Map<String, dynamic> data) {
    final list = (data['achievements'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    final items = list
        .map(
          (a) => GameAchievement(
            apiName: a['apiName'] as String? ?? '',
            displayName: a['displayName'] as String? ?? '',
            description: a['description'] as String? ?? '',
            unlocked: a['unlocked'] as bool? ?? false,
            hidden: a['hidden'] as bool? ?? false,
          ),
        )
        .toList();
    return _AchievementBundle(
      items: items,
      unlockedCount: data['unlockedCount'] as int? ?? 0,
      totalCount: data['totalCount'] as int? ?? items.length,
      note: data['note'] as String?,
    );
  }

  factory _AchievementBundle.mergeSchemaAndPlayer({
    Map<String, dynamic>? schemaBody,
    Map<String, dynamic>? playerBody,
  }) {
    final schemaList =
        (schemaBody?['game']?['availableGameStats']?['achievements']
                as List? ??
            [])
            .cast<Map<String, dynamic>>();

    if (schemaList.isEmpty) {
      return const _AchievementBundle();
    }

    final unlockedByApi = <String, bool>{};
    String? note =
        'Perfil privado: puedes ver los logros del juego, pero no cuántos tienes desbloqueados.';

    final stats = playerBody?['playerstats'] as Map<String, dynamic>?;
    if (stats != null && stats['success'] == true) {
      note = null;
      for (final a
          in (stats['achievements'] as List? ?? []).cast<Map<String, dynamic>>()) {
        final api = a['apiname'] as String? ?? '';
        unlockedByApi[api] = (a['achieved'] as int? ?? 0) == 1;
      }
    } else if (stats != null && stats['success'] != true) {
      final error = stats['error'] as String? ?? '';
      if (error.toLowerCase().contains('not public')) {
        note =
            'Steam aún bloquea tus logros. En Privacidad pon en público: '
            'Perfil y también Detalles de los juegos.';
      } else if (error.isNotEmpty) {
        note = error;
      }
    }

    final items = schemaList
        .map(
          (a) => GameAchievement(
            apiName: a['name'] as String? ?? '',
            displayName: a['displayName'] as String? ?? '',
            description: a['description'] as String? ?? '',
            hidden: (a['hidden'] as int? ?? 0) == 1,
            unlocked: unlockedByApi[a['name'] as String? ?? ''] ?? false,
          ),
        )
        .toList();

    final unlocked = items.where((a) => a.unlocked).length;
    return _AchievementBundle(
      items: items,
      unlockedCount: unlocked,
      totalCount: items.length,
      note: note,
    );
  }
}
