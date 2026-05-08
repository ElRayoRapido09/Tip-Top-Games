import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/game.dart';

class GeminiService {
  // Reemplaza esto con tu API key de Google Gemini
  static const String _apiKey = 'API_GEMINI_KEY_A';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  /// Obtener recomendaciones de juegos usando Gemini AI
  ///
  /// [games] - Lista de juegos disponibles en la biblioteca
  /// [availableTime] - Tiempo disponible en minutos
  /// [preferredGenres] - Géneros preferidos (lista vacía significa sin preferencias)
  ///
  /// Retorna lista de juegos recomendados con explicación
  static Future<List<GameRecommendation>> getRecommendations({
    required List<Game> games,
    required double availableTime,
    required List<String> preferredGenres,
  }) async {
    try {
      if (_apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
        throw Exception(
          'API Key de Gemini no configurada. Por favor, agrega tu clave en lib/services/gemini_service.dart',
        );
      }

      // Preparar información de juegos
      final gamesInfo = games
          .map(
            (g) =>
                '- ${g.title}: ${g.hours.toStringAsFixed(1)}h jugadas, Géneros: ${g.genres.isEmpty ? 'No especificados' : g.genres.join(', ')}',
          )
          .join('\n');

      // Construir el prompt
      final prompt = _buildPrompt(gamesInfo, availableTime, preferredGenres);

      // Llamar a la API de Gemini
      final response = await http
          .post(
            Uri.parse('$_baseUrl?key=$_apiKey'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt},
                  ],
                },
              ],
              'generationConfig': {
                'temperature': 0.7,
                'topK': 40,
                'topP': 0.95,
                'maxOutputTokens': 2048,
              },
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final textResponse =
            data['candidates'][0]['content']['parts'][0]['text'] as String;

        print('📝 Respuesta de Gemini: $textResponse');

        // Parsear la respuesta y extraer recomendaciones
        final recommendations = _parseRecommendations(textResponse, games);

        if (recommendations.isEmpty) {
          throw Exception(
            'No se encontraron recomendaciones en el formato esperado. Respuesta: $textResponse',
          );
        }

        return recommendations;
      } else {
        throw Exception(
          'Error en Gemini API: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error al obtener recomendaciones: $e');
    }
  }

  /// Construir el prompt para Gemini
  static String _buildPrompt(
    String gamesInfo,
    double availableTime,
    List<String> preferredGenres,
  ) {
    final genresText = preferredGenres.isEmpty
        ? 'sin preferencia por género específico'
        : 'interesado en: ${preferredGenres.join(', ')}';

    return '''Eres un experto recomendador de videojuegos profesional. Tu tarea es recomendar juegos de la biblioteca del usuario.

BIBLIOTECA DE JUEGOS DEL USUARIO:
$gamesInfo

CRITERIOS DEL USUARIO:
- Tiempo disponible: ${availableTime.toStringAsFixed(0)} minutos
- Preferencias de género: $genresText

TAREA:
Recomienda TODOS los juegos de la biblioteca que sean apropiados para el tiempo disponible. Ordénalos por ranking (mejor opción primero).

REQUISITOS:
1. SOLO recomienda juegos de la lista anterior
2. Los juegos deben ser disfrutables en aprox. ${availableTime.toStringAsFixed(0)} minutos
3. Prioriza los géneros preferidos si se especifican
4. Ordena por ranking: primero el mejor, último el menos recomendado
5. Incluye TODOS los juegos que cumplan los criterios

FORMATO DE RESPUESTA (REQUERIDO):
Una línea por juego, EXACTAMENTE en este formato:
RANK: [número] | GAME: [nombre exacto] | REASON: [razón breve] | SCORE: [1-10]

EJEMPLOS:
RANK: 1 | GAME: Hades | REASON: Perfecto para sesiones de 30-45 minutos, muy adictivo | SCORE: 9
RANK: 2 | GAME: Stardew Valley | REASON: Relajante, sin presión de tiempo | SCORE: 7
RANK: 3 | GAME: Portal 2 | REASON: Puzzles de 20-30 minutos por nivel | SCORE: 6

INSTRUCCIONES FINALES:
- NO escribas explicaciones adicionales
- NO escribas títulos o introducciones
- SOLO las líneas con RANK:, GAME:, REASON: y SCORE:
- Incluye TODOS los juegos que cumplan criterios
- Ordena por relevancia (mejor ranking = número más bajo)''';
  }

  /// Formatear tiempo en minutos a formato legible
  static String _formatTime(double minutes) {
    if (minutes < 60) {
      return '${minutes.toStringAsFixed(0)} minutos';
    } else if (minutes < 120) {
      final hours = minutes / 60;
      return '${hours.toStringAsFixed(1)} hora(s)';
    } else {
      return '${(minutes / 60).toStringAsFixed(0)}+ horas';
    }
  }

  /// Parsear las recomendaciones de la respuesta de Gemini
  static List<GameRecommendation> _parseRecommendations(
    String response,
    List<Game> availableGames,
  ) {
    final recommendations = <GameRecommendation>[];

    print('📊 Parseando respuesta de Gemini...');

    // Dividir por líneas y filtrar las que contienen el formato esperado
    final lines = response.split('\n');

    for (final line in lines) {
      // Buscar líneas con formato: RANK: X | GAME: ... | REASON: ... | SCORE: X
      if (!line.contains('GAME:') ||
          !line.contains('REASON:') ||
          !line.contains('SCORE:')) {
        continue;
      }

      try {
        // Extraer RANK
        int rank = recommendations.length + 1;
        final rankMatch = RegExp(r'RANK:\s*(\d+)').firstMatch(line);
        if (rankMatch != null) {
          rank = int.parse(
            rankMatch.group(1) ?? '${recommendations.length + 1}',
          );
        }

        // Extraer nombre del juego
        final gameMatch = RegExp(r'GAME:\s*(.+?)\s*\|').firstMatch(line);
        if (gameMatch == null) continue;
        final gameName = gameMatch.group(1)?.trim() ?? '';

        // Extraer razón
        final reasonMatch = RegExp(r'REASON:\s*(.+?)\s*\|').firstMatch(line);
        if (reasonMatch == null) continue;
        final reason = reasonMatch.group(1)?.trim() ?? '';

        // Extraer SCORE
        double score = 5.0;
        final scoreMatch = RegExp(r'SCORE:\s*(\d+(?:\.\d+)?)').firstMatch(line);
        if (scoreMatch != null) {
          score = double.parse(scoreMatch.group(1) ?? '5');
        }

        if (gameName.isEmpty || reason.isEmpty) {
          print('⚠️ Línea incompleta: $line');
          continue;
        }

        print('🎮 Detectado: $gameName (Rank: $rank, Score: $score)');

        // Buscar el juego en la biblioteca
        final game = _findGameByName(gameName, availableGames);

        if (game != null) {
          recommendations.add(
            GameRecommendation(
              game: game,
              reason: reason,
              matchScore: score,
              rank: rank,
            ),
          );
        } else {
          print('❌ No se encontró en biblioteca: $gameName');
        }
      } catch (e) {
        print('⚠️ Error parseando línea: $line - Error: $e');
        continue;
      }
    }

    print('✅ Total de recomendaciones encontradas: ${recommendations.length}');

    // Ordenar por rank
    recommendations.sort((a, b) => a.rank.compareTo(b.rank));

    return recommendations;
  }

  /// Buscar un juego por nombre (búsqueda tolerante)
  static Game? _findGameByName(String name, List<Game> games) {
    final lowerName = name.toLowerCase().trim();

    // Búsqueda exacta
    try {
      return games.firstWhere((g) => g.title.toLowerCase() == lowerName);
    } catch (_) {}

    // Búsqueda parcial (contiene)
    try {
      return games.firstWhere(
        (g) =>
            g.title.toLowerCase().contains(lowerName) ||
            lowerName.contains(g.title.toLowerCase()),
      );
    } catch (_) {}

    // Búsqueda por similitud de palabras
    for (final game in games) {
      final gameTitleLower = game.title.toLowerCase();
      final nameWords = lowerName
          .split(' ')
          .where((w) => w.isNotEmpty)
          .toList();
      final titleWords = gameTitleLower
          .split(' ')
          .where((w) => w.isNotEmpty)
          .toList();

      int matchCount = 0;
      for (final nameWord in nameWords) {
        for (final titleWord in titleWords) {
          if (nameWord.isNotEmpty && titleWord.contains(nameWord)) {
            matchCount++;
          }
        }
      }

      if (nameWords.isNotEmpty && matchCount >= (nameWords.length * 0.5)) {
        return game;
      }
    }

    print('❌ No se encontró juego: "$name" en la biblioteca');
    return null;
  }

  /// Calcular puntuación de coincidencia basada en la razón
  static double _calculateMatchScore(String reason) {
    // Palabras clave que indican una buena coincidencia
    final positiveKeywords = [
      'perfecto',
      'ideal',
      'excelente',
      'mejor',
      'recomendado',
      'disfrutarás',
      'adecuado',
      'apropiado',
    ];

    final lowerReason = reason.toLowerCase();
    int matches = 0;

    for (final keyword in positiveKeywords) {
      if (lowerReason.contains(keyword)) {
        matches++;
      }
    }

    // Puntuación entre 1-5
    return (matches + 1).clamp(1, 5).toDouble();
  }
}

/// Modelo para una recomendación de juego
class GameRecommendation {
  final Game game;
  final String reason;
  final double matchScore; // 1-10
  final int rank;

  GameRecommendation({
    required this.game,
    required this.reason,
    required this.matchScore,
    this.rank = 1,
  });
}
