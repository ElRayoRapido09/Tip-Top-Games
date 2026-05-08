class AppUser {
  final int? id;
  final String gameUser;
  final String email;
  final String passwordHash;
  final String? steamId;
  final List<String> gamingPlatforms;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppUser({
    this.id,
    required this.gameUser,
    required this.email,
    required this.passwordHash,
    this.steamId,
    required this.gamingPlatforms,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convertir a mapa para SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'gameUser': gameUser,
      'email': email,
      'passwordHash': passwordHash,
      'steamId': steamId,
      'gamingPlatforms': gamingPlatforms.join(','), // Guardar como string separado por comas
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Crear desde mapa de SQLite
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as int?,
      gameUser: map['gameUser'] as String,
      email: map['email'] as String,
      passwordHash: map['passwordHash'] as String,
      steamId: map['steamId'] as String?,
      gamingPlatforms: (map['gamingPlatforms'] as String?)?.split(',') ?? [],
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  /// Copiar con modificaciones
  AppUser copyWith({
    int? id,
    String? gameUser,
    String? email,
    String? passwordHash,
    String? steamId,
    List<String>? gamingPlatforms,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      gameUser: gameUser ?? this.gameUser,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      steamId: steamId ?? this.steamId,
      gamingPlatforms: gamingPlatforms ?? this.gamingPlatforms,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
