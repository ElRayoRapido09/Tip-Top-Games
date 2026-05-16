import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/game.dart';

class SteamApiService {
  static const String _steamApiBase = 'https://api.steampowered.com';
  static const String _communityUrl = 'https://steamcommunity.com/profiles';
  static const String _proxyUrl = String.fromEnvironment(
    'STEAM_PROXY_URL',
    defaultValue: 'http://localhost:8080',
  );
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
