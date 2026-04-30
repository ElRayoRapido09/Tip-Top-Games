import 'package:flutter/material.dart';
import '../models/game.dart';
import '../services/steam_auth_service.dart';
import '../services/steam_api_service.dart';

class SteamProvider extends ChangeNotifier {
  final SteamAuthService _authService = SteamAuthService();
  final SteamApiService _apiService = SteamApiService();

  List<Game> _games = [];
  Map<String, dynamic>? _userInfo;
  bool _isLoading = false;
  String? _error;
  String? _steamId;

  // Getters
  List<Game> get games => _games;
  Map<String, dynamic>? get userInfo => _userInfo;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get steamId => _steamId;
  bool get isAuthenticated => _steamId != null;

  /// Inicializar - comprobar si hay sesión anterior
  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final savedSteamId = await _authService.getSavedSteamId();
      if (savedSteamId != null) {
        _steamId = savedSteamId;
        await _loadUserLibrary();
      }
    } catch (e) {
      _error = 'Error al inicializar: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Conectar con Steam (simulado)
  /// En una app real, implementarías el flujo OpenID de Steam
  Future<void> loginWithSteamId(String steamId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Validar que el ID de Steam sea válido
      if (!_isValidSteamId(steamId)) {
        throw Exception('ID de Steam inválido');
      }

      // Obtener información del usuario
      _userInfo = await _apiService.getUserInfo(steamId);
      _steamId = steamId;

      // Guardar sesión
      await _authService.saveSteamUser(
        steamId: steamId,
        steamName: _userInfo?['personaname'] ?? 'Usuario',
        steamAvatar: _userInfo?['avatarfull'] ?? '',
      );

      // Cargar biblioteca
      await _loadUserLibrary();
    } catch (e) {
      _error = 'Error al conectar con Steam: $e';
      _steamId = null;
      _games = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cargar biblioteca de juegos
  Future<void> _loadUserLibrary() async {
    if (_steamId == null) return;

    try {
      _games = await _apiService.getUserLibrary(_steamId!);
      _error = null;
    } catch (e) {
      _error = 'Error al cargar biblioteca: $e';
      _games = [];
    }
    notifyListeners();
  }

  /// Cerrar sesión
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
      _steamId = null;
      _games = [];
      _userInfo = null;
      _error = null;
    } catch (e) {
      _error = 'Error al cerrar sesión: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Validar formato de Steam ID
  bool _isValidSteamId(String steamId) {
    // Steam IDs son números de 17 dígitos
    return RegExp(r'^\d{17}$').hasMatch(steamId.trim());
  }

  /// Filtrar juegos por género (se implementará cuando tengas géneros)
  List<Game> filterByGenres(List<String> genres) {
    if (genres.isEmpty) return _games;
    return _games
        .where((game) => game.genres.any((g) => genres.contains(g)))
        .toList();
  }

  /// Filtrar juegos por tiempo de juego
  List<Game> filterByPlaytime(double minHours, double maxHours) {
    return _games
        .where((game) => game.hours >= minHours && game.hours <= maxHours)
        .toList();
  }

  /// Buscar juegos
  List<Game> searchGames(String query) {
    if (query.isEmpty) return _games;
    final lowerQuery = query.toLowerCase();
    return _games
        .where((game) => game.title.toLowerCase().contains(lowerQuery))
        .toList();
  }
}
