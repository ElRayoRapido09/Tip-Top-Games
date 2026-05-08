import 'package:flutter/material.dart';
import '../models/game.dart';
import '../services/gemini_service.dart';

class RecommendationsScreen extends StatefulWidget {
  final List<Game> games;
  final double availableTime;
  final List<String> preferredGenres;

  const RecommendationsScreen({
    super.key,
    required this.games,
    required this.availableTime,
    required this.preferredGenres,
  });

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  late Future<List<GameRecommendation>> _recommendationsFuture;

  @override
  void initState() {
    super.initState();
    _recommendationsFuture = GeminiService.getRecommendations(
      games: widget.games,
      availableTime: widget.availableTime,
      preferredGenres: widget.preferredGenres,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '✨ Recomendaciones IA',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C5FFF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Criteria summary
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C5FFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF6C5FFF).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⏱️ Tiempo disponible: ${widget.availableTime.toStringAsFixed(0)} minutos',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6C5FFF),
                      ),
                    ),
                    if (widget.preferredGenres.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '🎮 Géneros: ${widget.preferredGenres.join(', ')}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6C5FFF),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Recommendations list
            Expanded(
              child: FutureBuilder<List<GameRecommendation>>(
                future: _recommendationsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF6C5FFF),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Analizando tu biblioteca...',
                            style: TextStyle(
                              color: Color(0xFF9999AA),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _recommendationsFuture =
                                    GeminiService.getRecommendations(
                                      games: widget.games,
                                      availableTime: widget.availableTime,
                                      preferredGenres: widget.preferredGenres,
                                    );
                              });
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Intentar de nuevo'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C5FFF),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final recommendations = snapshot.data ?? [];

                  if (recommendations.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          'No se pudieron obtener recomendaciones. Intenta de nuevo.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF9999AA).withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: recommendations.length,
                    itemBuilder: (context, index) {
                      final rec = recommendations[index];
                      return _GameRecommendationCard(
                        recommendation: rec,
                        index: index + 1,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget para mostrar una tarjeta de recomendación
class _GameRecommendationCard extends StatelessWidget {
  final GameRecommendation recommendation;
  final int index;

  const _GameRecommendationCard({
    required this.recommendation,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final game = recommendation.game;
    final score = recommendation.matchScore;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6C5FFF).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Stack(
              children: [
                Image.network(
                  game.imageUrl,
                  width: double.infinity,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 120,
                      color: const Color(0xFF2A2A3E),
                      child: const Icon(
                        Icons.games,
                        color: Color(0xFF6C5FFF),
                        size: 40,
                      ),
                    );
                  },
                ),
                // Número de recomendación
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getRankingColor(index),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '🏆 #${recommendation.rank}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Badge de score
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          '${score.toStringAsFixed(1)}/10',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  game.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Stats row
                Row(
                  children: [
                    // Hours played
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: const Color(0xFF9999AA),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${game.hours.toStringAsFixed(1)}h',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9999AA),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Score
                    Icon(Icons.star, size: 16, color: const Color(0xFF6C5FFF)),
                    const SizedBox(width: 4),
                    Text(
                      '${score.toStringAsFixed(1)}/10',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6C5FFF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Reason
                Text(
                  recommendation.reason,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9999AA),
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankingColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Oro
      case 2:
        return const Color(0xFFC0C0C0); // Plata
      case 3:
        return const Color(0xFFCD7F32); // Bronce
      default:
        return const Color(0xFF6C5FFF); // Púrpura
    }
  }
}
