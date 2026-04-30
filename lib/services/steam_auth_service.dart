import 'package:shared_preferences/shared_preferences.dart';

class SteamAuthService {
  static const String _steamIdKey = 'steam_id';
  static const String _steamNameKey = 'steam_name';
  static const String _steamAvatarKey = 'steam_avatar';

  // Obtener el Steam ID guardado localmente
  Future<String?> getSavedSteamId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_steamIdKey);
  }

  // Guardar datos del usuario autenticado
  Future<void> saveSteamUser({
    required String steamId,
    required String steamName,
    required String steamAvatar,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_steamIdKey, steamId);
    await prefs.setString(_steamNameKey, steamName);
    await prefs.setString(_steamAvatarKey, steamAvatar);
  }

  // Obtener datos del usuario guardado
  Future<Map<String, String>?> getSavedSteamUser() async {
    final prefs = await SharedPreferences.getInstance();
    final steamId = prefs.getString(_steamIdKey);

    if (steamId == null) return null;

    return {
      'steamId': steamId,
      'steamName': prefs.getString(_steamNameKey) ?? 'Usuario',
      'steamAvatar': prefs.getString(_steamAvatarKey) ?? '',
    };
  }

  // Cerrar sesión
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_steamIdKey);
    await prefs.remove(_steamNameKey);
    await prefs.remove(_steamAvatarKey);
  }

  // Verificar si está autenticado
  Future<bool> isAuthenticated() async {
    final steamId = await getSavedSteamId();
    return steamId != null;
  }

  // Generar URL de login de Steam
  String getSteamLoginUrl({String? returnUrl}) {
    // Este es el endpoint de OpenID de Steam
    // En producción, necesitarías implementar el flujo OpenID completo
    return 'https://steamcommunity.com/openid/login';
  }
}
