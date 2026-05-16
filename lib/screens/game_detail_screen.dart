import 'package:flutter/material.dart';
import '../models/game.dart';

class GameDetailScreen extends StatefulWidget {
  final Game game;
  final Offset? tapPosition;

  const GameDetailScreen({
    super.key,
    required this.game,
    this.tapPosition,
  });

  @override
  State<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Animación de escala (expansion desde el punto de tap)
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    // Animación de deslizamiento suave
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    // Animación de fade para el fondo
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuad),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _closeWithAnimation() async {
    await _animationController.reverse();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  String _formatHours(double hours) {
    if (hours < 1) {
      return '${(hours * 60).toInt()} minutos';
    } else if (hours < 24) {
      return '${hours.toStringAsFixed(1)} horas';
    } else {
      final days = (hours / 24).toStringAsFixed(1);
      return '$days días';
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await _closeWithAnimation();
      },
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Fondo oscuro animado
            FadeTransition(
              opacity: _fadeAnimation,
              child: GestureDetector(
                onTap: _closeWithAnimation,
                child: Container(
                  color: Colors.black.withOpacity(0.6),
                ),
              ),
            ),
            // Contenido principal con animación
            Center(
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: GestureDetector(
                    onTap: () {}, // Prevenir cierre al tocar el contenido
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF6C5FFF).withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF6C5FFF).withOpacity(0.25),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Header con imagen del juego
                              Stack(
                                children: [
                                  // Game header image
                                  Container(
                                    width: double.infinity,
                                    height: 200,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          const Color(0xFF6C5FFF)
                                              .withOpacity(0.3),
                                          const Color(0xFF4A3FA3)
                                              .withOpacity(0.2),
                                        ],
                                      ),
                                    ),
                                    child: ClipRRect(
                                      child: Image.network(
                                        'https://cdn.akamai.steamstatic.com/steam/apps/${widget.game.appId}/header.jpg',
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            color: const Color(0xFF0F0F1E),
                                            child: const Center(
                                              child: Icon(
                                                Icons.image_not_supported,
                                                color: Color(0xFF9999AA),
                                                size: 48,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  // Botón de cierre
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: GestureDetector(
                                      onTap: _closeWithAnimation,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.5),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white
                                                .withOpacity(0.3),
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // Contenido
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    // Título del juego
                                    Text(
                                      widget.game.title,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    // Información del juego en grid
                                    GridView.count(
                                      crossAxisCount: 2,
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      childAspectRatio: 1.3,
                                      children: [
                                        _InfoCard(
                                          icon: Icons.schedule,
                                          label: 'Tiempo jugado',
                                          value: _formatHours(
                                              widget.game.hours),
                                        ),
                                        _InfoCard(
                                          icon: Icons.gamepad,
                                          label: 'App ID',
                                          value: widget.game.appId.toString(),
                                        ),
                                        if (widget.game.genres.isNotEmpty)
                                          _InfoCard(
                                            icon: Icons.category,
                                            label:
                                                'Géneros (${widget.game.genres.length})',
                                            value: widget.game.genres
                                                .take(1)
                                                .join(', '),
                                            isSmall: true,
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    // Géneros
                                    if (widget.game.genres.isNotEmpty) ...[
                                      const Text(
                                        'GÉNEROS',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF9999AA),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: widget.game.genres
                                            .map(
                                              (genre) => Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF6C5FFF)
                                                      .withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    20,
                                                  ),
                                                  border: Border.all(
                                                    color: const Color(0xFF6C5FFF)
                                                        .withOpacity(0.5),
                                                  ),
                                                ),
                                                child: Text(
                                                  genre,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF6C5FFF),
                                                    fontWeight:
                                                        FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                    // Estadísticas detalladas
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0F0F1E),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFF6C5FFF)
                                              .withOpacity(0.2),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _StatRow(
                                            icon: Icons.schedule,
                                            label: 'Tiempo total jugado:',
                                            value: _formatHours(
                                                widget.game.hours),
                                          ),
                                          const SizedBox(height: 12),
                                          _StatRow(
                                            icon: Icons.local_offer,
                                            label: 'ID de aplicación:',
                                            value: widget.game.appId.toString(),
                                          ),
                                          const SizedBox(height: 12),
                                          _StatRow(
                                            icon: Icons.info_outline,
                                            label: 'Estado:',
                                            value: 'Jugado',
                                            valueColor:
                                                Colors.green.withOpacity(0.8),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    // Botón de acción
                                    SizedBox(
                                      width: double.infinity,
                                      height: 48,
                                      child: ElevatedButton.icon(
                                        onPressed: _closeWithAnimation,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF6C5FFF),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                        icon: const Icon(Icons.close),
                                        label: const Text('Cerrar'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isSmall;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F1E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF6C5FFF).withOpacity(0.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: const Color(0xFF6C5FFF),
            size: isSmall ? 18 : 20,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: isSmall ? 10 : 11,
              color: const Color(0xFF9999AA),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmall ? 12 : 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFF6C5FFF),
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF9999AA),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.white,
          ),
          textAlign: TextAlign.right,
        ),
      ],
    );
  }
}
