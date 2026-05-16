class AppUser {
  final int? id;
  final String gameUser;
  final String email;
  final String passwordHash;
  final String? steamId;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppUser({
    this.id,
    required this.gameUser,
    required this.email,
    required this.passwordHash,
    this.steamId,
    this.profileImageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'gameUser': gameUser,
      'email': email,
      'passwordHash': passwordHash,
      'steamId': steamId,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as int?,
      gameUser: map['gameUser'] as String,
      email: map['email'] as String,
      passwordHash: map['passwordHash'] as String,
      steamId: map['steamId'] as String?,
      profileImageUrl: map['profileImageUrl'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  AppUser copyWith({
    int? id,
    String? gameUser,
    String? email,
    String? passwordHash,
    String? steamId,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      gameUser: gameUser ?? this.gameUser,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      steamId: steamId ?? this.steamId,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
