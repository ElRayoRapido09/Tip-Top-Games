import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/app_user.dart';
import '../models/chat_history.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Inicializar base de datos
  Future<Database> _initDatabase() async {
    String path;
    if (kIsWeb) {
      path = 'tip_top_games.db';
    } else {
      final databasePath = await getDatabasesPath();
      path = join(databasePath, 'tip_top_games.db');
    }

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  /// Crear tablas
  Future<void> _onCreate(Database db, int version) async {
    // Tabla de usuarios
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        gameUser TEXT UNIQUE NOT NULL,
        email TEXT UNIQUE NOT NULL,
        passwordHash TEXT NOT NULL,
        steamId TEXT,
        gamingPlatforms TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Tabla de historial de chats
    await db.execute('''
      CREATE TABLE chat_history(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        query TEXT NOT NULL,
        response TEXT NOT NULL,
        availableTime REAL NOT NULL,
        selectedGenres TEXT,
        recommendationsCount INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY(userId) REFERENCES users(id)
      )
    ''');
  }

  // ==================== USUARIO ====================

  /// Crear nuevo usuario
  Future<AppUser> createUser({
    required String gameUser,
    required String email,
    required String password,
    required List<String> gamingPlatforms,
  }) async {
    final db = await database;
    final passwordHash = _hashPassword(password);
    final now = DateTime.now();

    final user = AppUser(
      gameUser: gameUser,
      email: email,
      passwordHash: passwordHash,
      gamingPlatforms: gamingPlatforms,
      createdAt: now,
      updatedAt: now,
    );

    final id = await db.insert('users', user.toMap());
    return user.copyWith(id: id as int);
  }

  /// Obtener usuario por gameUser
  Future<AppUser?> getUserByGameUser(String gameUser) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'gameUser = ?',
      whereArgs: [gameUser],
    );

    if (result.isEmpty) return null;
    return AppUser.fromMap(result.first);
  }

  /// Obtener usuario por email
  Future<AppUser?> getUserByEmail(String email) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (result.isEmpty) return null;
    return AppUser.fromMap(result.first);
  }

  /// Obtener usuario por ID
  Future<AppUser?> getUserById(int id) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isEmpty) return null;
    return AppUser.fromMap(result.first);
  }

  /// Validar credenciales
  Future<AppUser?> validateCredentials(
    String usernameOrEmail,
    String password,
  ) async {
    AppUser? user = await getUserByGameUser(usernameOrEmail);
    user ??= await getUserByEmail(usernameOrEmail);

    if (user == null) return null;

    final passwordHash = _hashPassword(password);
    if (user.passwordHash == passwordHash) {
      return user;
    }
    return null;
  }

  /// Vincular Steam ID
  Future<void> linkSteamId(int userId, String steamId) async {
    final db = await database;
    await db.update(
      'users',
      {
        'steamId': steamId,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  /// Actualizar plataformas de juego
  Future<void> updateGamingPlatforms(
    int userId,
    List<String> platforms,
  ) async {
    final db = await database;
    await db.update(
      'users',
      {
        'gamingPlatforms': platforms.join(','),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // ==================== CHAT HISTORY ====================

  /// Guardar chat
  Future<ChatHistory> saveChatHistory({
    required int userId,
    required String query,
    required String response,
    required double availableTime,
    required List<String> selectedGenres,
    required int recommendationsCount,
  }) async {
    final db = await database;

    final chat = ChatHistory(
      userId: userId,
      query: query,
      response: response,
      availableTime: availableTime,
      selectedGenres: selectedGenres,
      recommendationsCount: recommendationsCount,
      createdAt: DateTime.now(),
    );

    final id = await db.insert('chat_history', chat.toMap());
    return chat.copyWith(id: id as int);
  }

  /// Obtener historial de chats del usuario
  Future<List<ChatHistory>> getChatHistory(int userId) async {
    final db = await database;
    final result = await db.query(
      'chat_history',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );

    return result.map((map) => ChatHistory.fromMap(map)).toList();
  }

  /// Obtener último chat del usuario
  Future<ChatHistory?> getLastChat(int userId) async {
    final db = await database;
    final result = await db.query(
      'chat_history',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
      limit: 1,
    );

    if (result.isEmpty) return null;
    return ChatHistory.fromMap(result.first);
  }

  /// Eliminar chat
  Future<void> deleteChat(int chatId) async {
    final db = await database;
    await db.delete(
      'chat_history',
      where: 'id = ?',
      whereArgs: [chatId],
    );
  }

  // ==================== UTILIDADES ====================

  /// Hashear contraseña
  static String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  /// Verificar si el gameUser ya existe
  Future<bool> gameUserExists(String gameUser) async {
    final user = await getUserByGameUser(gameUser);
    return user != null;
  }

  /// Verificar si el email ya existe
  Future<bool> emailExists(String email) async {
    final user = await getUserByEmail(email);
    return user != null;
  }

  /// Limpiar base de datos (para testing)
  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('chat_history');
    await db.delete('users');
  }
}
