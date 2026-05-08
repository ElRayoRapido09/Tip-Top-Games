class ChatHistory {
  final int? id;
  final int userId;
  final String query;
  final String response;
  final double availableTime;
  final List<String> selectedGenres;
  final int recommendationsCount;
  final DateTime createdAt;

  ChatHistory({
    this.id,
    required this.userId,
    required this.query,
    required this.response,
    required this.availableTime,
    required this.selectedGenres,
    required this.recommendationsCount,
    required this.createdAt,
  });

  /// Convertir a mapa para SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'query': query,
      'response': response,
      'availableTime': availableTime,
      'selectedGenres': selectedGenres.join(','),
      'recommendationsCount': recommendationsCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Crear desde mapa de SQLite
  factory ChatHistory.fromMap(Map<String, dynamic> map) {
    return ChatHistory(
      id: map['id'] as int?,
      userId: map['userId'] as int,
      query: map['query'] as String,
      response: map['response'] as String,
      availableTime: (map['availableTime'] as num).toDouble(),
      selectedGenres: (map['selectedGenres'] as String?)?.split(',') ?? [],
      recommendationsCount: map['recommendationsCount'] as int,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  /// Copiar con modificaciones
  ChatHistory copyWith({
    int? id,
    int? userId,
    String? query,
    String? response,
    double? availableTime,
    List<String>? selectedGenres,
    int? recommendationsCount,
    DateTime? createdAt,
  }) {
    return ChatHistory(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      query: query ?? this.query,
      response: response ?? this.response,
      availableTime: availableTime ?? this.availableTime,
      selectedGenres: selectedGenres ?? this.selectedGenres,
      recommendationsCount: recommendationsCount ?? this.recommendationsCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
