import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/game.dart';

class SteamApiService {
  // URLs
  static const String _communityUrl = 'https://steamcommunity.com/profiles';
  static const String _configuredProxyUrl = String.fromEnvironment(
    'STEAM_PROXY_URL',
    defaultValue: 'http://localhost:8080',
  );
  static String get _proxyUrl => _configuredProxyUrl;

  /// Obtener la biblioteca de juegos del usuario
  Future<List<Game>> getUserLibrary(String steamId) async {
    try {
      final url = Uri.parse('$_proxyUrl/library?steamid=$steamId');

      final response = await http.get(url).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final games = data['response']['games'] as List;

        return games
            .map(
              (gameData) =>
                  Game.fromSteamData(gameData as Map<String, dynamic>),
            )
            .toList();
      } else {
        throw Exception(
          'Error al obtener biblioteca (${response.statusCode}). '
          'Verifica que el proxy Steam esté activo en $_proxyUrl',
        );
      }
    } catch (e) {
      throw Exception('Error al conectar con Steam API: $e');
    }
  }

  /// Obtener información del usuario de Steam
  Future<Map<String, dynamic>> getUserInfo(String steamId) async {
    try {
      final url = Uri.parse('$_proxyUrl/userinfo?steamid=$steamId');

      final response = await http.get(url).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final players = data['response']['players'] as List;

        if (players.isNotEmpty) {
          return players[0] as Map<String, dynamic>;
        }
        throw Exception('Usuario no encontrado');
      } else {
        throw Exception(
          'Error al obtener información del usuario (${response.statusCode}). '
          'Verifica que el proxy Steam esté activo en $_proxyUrl',
        );
      }
    } catch (e) {
      throw Exception('Error al conectar con Steam API: $e');
    }
  }

  /// Resolver vanity URL de Steam a Steam ID
  Future<String?> resolveVanityUrl(String vanityUrl) async {
    try {
      final url = Uri.parse('$_proxyUrl/vanityurl?vanityurl=$vanityUrl');

      final response = await http.get(url).timeout(const Duration(seconds: 12));

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

  /// Obtener estado del servidor proxy (solo para web)
  static Future<bool> checkProxyHealth() async {
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
