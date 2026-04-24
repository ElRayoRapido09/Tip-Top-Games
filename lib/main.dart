import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tip-Top Games',
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0F0F1E),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C5FFF),
          brightness: Brightness.dark,
        ),
      ),
      home: const MainNavigation(),
    );
  }
}

// Model de Game
class Game {
  final String id;
  final String title;
  final String imageUrl;
  final double hours;
  final List<String> genres;

  Game({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.hours,
    required this.genres,
  });
}

// Pantalla de navegación principal
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          SteamTimeHome(),
          LibraryScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: const Color(0xFF6C5FFF).withOpacity(0.2),
            ),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFF0F0F1E),
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          selectedItemColor: const Color(0xFF6C5FFF),
          unselectedItemColor: const Color(0xFF9999AA),
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.library_books),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: '',
            ),
          ],
        ),
      ),
    );
  }
}

class SteamTimeHome extends StatefulWidget {
  const SteamTimeHome({super.key});

  @override
  State<SteamTimeHome> createState() => _SteamTimeHomeState();
}

class _SteamTimeHomeState extends State<SteamTimeHome> {
  double _selectedTime = 45;
  final Set<String> _selectedGenres = {};

  final List<String> genres = [
    'Acción',
    'Relajante',
    'Competitivo',
    'Shooter',
    'RPG',
    'Plataformas',
  ];

  String _getTimeLabel(double value) {
    if (value <= 30) {
      return '10m';
    } else if (value <= 60) {
      return '${value.toInt()}m';
    } else if (value <= 120) {
      return '${(value / 60).toStringAsFixed(1)}h';
    } else {
      return '2h+';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tip-Top Games',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C5FFF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            // Main content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question
                  const Text(
                    '¿Cuánto tiempo\ntienes hoy?',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Subtitle
                  const Text(
                    'Gemini AI analizará tu biblioteca de 6 juegos para encontrar la sesión perfecta.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9999AA),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Time display circle
                  Center(
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF6C5FFF).withOpacity(0.3),
                            const Color(0xFF4A3FA3).withOpacity(0.3),
                          ],
                        ),
                        border: Border.all(
                          color: const Color(0xFF6C5FFF).withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${_selectedTime.toInt()}',
                              style: const TextStyle(
                                fontSize: 60,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              'min',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF9999AA),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'TIEMPO DE JUEGO',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF9999AA),
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Slider
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Slider(
                        value: _selectedTime,
                        min: 10,
                        max: 120,
                        activeColor: const Color(0xFF6C5FFF),
                        inactiveColor: const Color(0xFF6C5FFF).withOpacity(0.2),
                        onChanged: (value) {
                          setState(() {
                            _selectedTime = value;
                          });
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '10m',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF9999AA),
                              ),
                            ),
                            const Text(
                              '1h',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF9999AA),
                              ),
                            ),
                            const Text(
                              '2h+',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF9999AA),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  // Game genre section
                  const Text(
                    '¿QUÉ TIENES GANAS DE JUGAR?',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF9999AA),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Genre chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: genres.map((genre) {
                      final isSelected = _selectedGenres.contains(genre);
                      return FilterChip(
                        label: Text(genre),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedGenres.add(genre);
                            } else {
                              _selectedGenres.remove(genre);
                            }
                          });
                        },
                        backgroundColor: const Color(0xFF1A1A2E),
                        selectedColor: const Color(0xFF6C5FFF),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF9999AA),
                          fontSize: 13,
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? const Color(0xFF6C5FFF)
                              : const Color(0xFF6C5FFF).withOpacity(0.3),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 40),
                  // Main button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C5FFF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {},
                      child: const Text(
                        '🔮 Buscar sugerencias con IA',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Pantalla de Librería
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _sortBy = 'Recientes';
  
  final List<Game> games = [
    Game(
      id: '1',
      title: 'Elden Ring',
      imageUrl: 'assets/elden_ring.jpg',
      hours: 48,
      genres: ['Action', 'Adventure'],
    ),
    Game(
      id: '2',
      title: 'Rocket League',
      imageUrl: 'assets/rocket_league.jpg',
      hours: 19,
      genres: ['Sports', 'Competitive'],
    ),
    Game(
      id: '3',
      title: 'Hades',
      imageUrl: 'assets/hades.jpg',
      hours: 15,
      genres: ['Action', 'Roguelike'],
    ),
    Game(
      id: '4',
      title: 'Counter Strike 2',
      imageUrl: 'assets/cs2.jpg',
      hours: 4,
      genres: ['Shooter', 'Competitive'],
    ),
    Game(
      id: '5',
      title: 'The Witcher 3',
      imageUrl: 'assets/witcher3.jpg',
      hours: 120,
      genres: ['RPG', 'Adventure'],
    ),
    Game(
      id: '6',
      title: 'Celeste',
      imageUrl: 'assets/celeste.jpg',
      hours: 8,
      genres: ['Platformer', 'Indie'],
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tu Biblioteca',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C5FFF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search bar
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF6C5FFF).withOpacity(0.2),
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Buscar por nombre, género...',
                        hintStyle: const TextStyle(
                          color: Color(0xFF9999AA),
                        ),
                        border: InputBorder.none,
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF9999AA),
                        ),
                        suffixIcon: GestureDetector(
                          onTap: () {
                            _searchController.clear();
                          },
                          child: Icon(
                            Icons.close,
                            color: const Color(0xFF9999AA).withOpacity(0.5),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Filter info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${games.length} juegos • Ordenado por $_sortBy',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF9999AA),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: const Icon(
                          Icons.tune,
                          color: Color(0xFF9999AA),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Games Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: games.length,
                    itemBuilder: (context, index) {
                      final game = games[index];
                      return GameCard(game: game);
                    },
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget de tarjeta de juego
class GameCard extends StatelessWidget {
  final Game game;

  const GameCard({
    super.key,
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF6C5FFF).withOpacity(0.2),
              ),
            ),
            child: Stack(
              children: [
                // Placeholder image
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF6C5FFF).withOpacity(0.2),
                        const Color(0xFF4A3FA3).withOpacity(0.2),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: const Color(0xFF9999AA).withOpacity(0.5),
                      size: 40,
                    ),
                  ),
                ),
                // Time badge
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '⏱ ~${game.hours.toInt()}h',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Game title
          Text(
            game.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // Genres
          Text(
            game.genres.join(', '),
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF9999AA),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// Pantalla de Perfil (placeholder)
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF6C5FFF),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Mi Perfil',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tu información de perfil aparecerá aquí',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF9999AA),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

