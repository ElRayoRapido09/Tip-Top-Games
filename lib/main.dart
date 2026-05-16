import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'providers/steam_provider.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/recommendations_screen.dart';
import 'screens/game_detail_screen.dart';
import 'models/game.dart';

/// Tamaños adaptados al ancho de pantalla del dispositivo.
class _Layout {
  _Layout(BuildContext context)
      : width = MediaQuery.sizeOf(context).width,
        height = MediaQuery.sizeOf(context).height,
        padding = MediaQuery.paddingOf(context);

  final double width;
  final double height;
  final EdgeInsets padding;

  double get horizontal => (width * 0.045).clamp(12.0, 24.0);
  double get titleSize => (width * 0.075).clamp(22.0, 32.0);
  double get subtitleSize => (width * 0.034).clamp(12.0, 14.0);
  double get circleSize => (width * 0.48).clamp(140.0, 220.0);
  double get circleNumberSize => (width * 0.14).clamp(40.0, 60.0);
  int get gridColumns => width >= 600 ? 3 : 2;
  double get gridAspectRatio => width < 360 ? 0.68 : 0.75;
}

void main() {
  // Initialize database factory
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else if (defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    // En desktop usamos FFI; en Android/iOS dejamos sqflite nativo.
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => SteamProvider())],
      child: MaterialApp(
        title: 'Tip-Top Games',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFF0F0F1E),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6C5FFF),
            brightness: Brightness.dark,
          ),
        ),
        home: const AppEntry(),
      ),
    );
  }
}

// Widget que decide mostrar login o app principal
class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  @override
  Widget build(BuildContext context) {
    return Consumer<SteamProvider>(
      builder: (context, steamProvider, _) {
        if (steamProvider.appUser != null && steamProvider.isAuthenticated) {
          return const MainNavigation();
        } else {
          return LoginScreen(
            onLoginSuccess: (user) {
              context.read<SteamProvider>().setAppUser(user);
            },
          );
        }
      },
    );
  }
}

// Pantalla de navegación principal
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _pageAnimationController;
  late AnimationController _navAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<Widget> _pages = const [
    SteamTimeHome(),
    LibraryScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();

    // Controlador para transición de páginas
    _pageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Controlador para animación de navbar
    _navAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Fade para la página
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pageAnimationController, curve: Curves.easeOut),
    );

    // Slide para la página
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _pageAnimationController, curve: Curves.easeOutCubic),
        );

    _pageAnimationController.forward();
    _navAnimationController.forward();
  }

  @override
  void dispose() {
    _pageAnimationController.dispose();
    _navAnimationController.dispose();
    super.dispose();
  }

  void _onNavItemTapped(int index) {
    if (index != _selectedIndex) {
      // Resetear animación de página
      _pageAnimationController.reset();

      setState(() {
        _selectedIndex = index;
      });

      // Reiniciar animación
      _pageAnimationController.forward();

      // Pequeña animación del navbar
      _navAnimationController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: _pages[_selectedIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: const Color(0xFF6C5FFF).withOpacity(0.2)),
          ),
        ),
        child: _AnimatedBottomNavBar(
          currentIndex: _selectedIndex,
          onTap: _onNavItemTapped,
          animationController: _navAnimationController,
        ),
      ),
    );
  }
}

// Widget personalizado para la barra de navegación animada
class _AnimatedBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final AnimationController animationController;

  const _AnimatedBottomNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: const Color(0xFF0F0F1E),
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      selectedItemColor: const Color(0xFF6C5FFF),
      unselectedItemColor: const Color(0xFF9999AA),
      onTap: onTap,
      items: [
        _buildNavItem(
          icon: Icons.home,
          index: 0,
          isSelected: currentIndex == 0,
        ),
        _buildNavItem(
          icon: Icons.library_books,
          index: 1,
          isSelected: currentIndex == 1,
        ),
        _buildNavItem(
          icon: Icons.person,
          index: 2,
          isSelected: currentIndex == 2,
        ),
      ],
    );
  }

  BottomNavigationBarItem _buildNavItem({
    required IconData icon,
    required int index,
    required bool isSelected,
  }) {
    return BottomNavigationBarItem(
      icon: _AnimatedNavIcon(
        icon: icon,
        isSelected: isSelected,
        animationController: animationController,
      ),
      label: '',
    );
  }
}

// Widget para animar el icono individual
class _AnimatedNavIcon extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final AnimationController animationController;

  const _AnimatedNavIcon({
    required this.icon,
    required this.isSelected,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    // Solo animar si está seleccionado
    if (!isSelected) {
      return Icon(icon);
    }

    // Animación de scale para el icono seleccionado
    final scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: animationController, curve: Curves.elasticOut),
    );

    return AnimatedBuilder(
      animation: scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: scaleAnimation.value,
          child: child,
        );
      },
      child: Icon(icon),
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

  List<Game> _getFilteredGames(SteamProvider provider) {
    // Obtener juegos filtrados por tiempo
    var filtered = provider.filterByPlaytime(0, _selectedTime);

    // Si hay géneros seleccionados, filtrar por esos también
    if (_selectedGenres.isNotEmpty) {
      filtered = filtered
          .where((game) => game.genres.any((g) => _selectedGenres.contains(g)))
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<SteamProvider>(
        builder: (context, steamProvider, _) {
          if (steamProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C5FFF)),
              ),
            );
          }

          final filteredGames = _getFilteredGames(steamProvider);
          final layout = _Layout(context);

          return SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      layout.horizontal,
                      16,
                      layout.horizontal,
                      8,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Tip-Top Games',
                        style: TextStyle(
                          fontSize: layout.titleSize * 0.6,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: layout.horizontal),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '¿Cuánto tiempo\ntienes hoy?',
                          style: TextStyle(
                            fontSize: layout.titleSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                      const SizedBox(height: 8),
                      // Subtitle
                        Text(
                          'Elige tiempo y género para encontrar sugerencias en tu biblioteca (${steamProvider.games.length} juegos)',
                          style: TextStyle(
                            fontSize: layout.subtitleSize,
                            color: const Color(0xFF9999AA),
                          ),
                        ),
                        SizedBox(height: layout.height * 0.025),
                        Center(
                          child: Container(
                            width: layout.circleSize,
                            height: layout.circleSize,
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
                                  style: TextStyle(
                                    fontSize: layout.circleNumberSize,
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
                            inactiveColor: const Color(
                              0xFF6C5FFF,
                            ).withOpacity(0.2),
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
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF9999AA),
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
                      // Suggestions info
                      if (filteredGames.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C5FFF).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF6C5FFF).withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            '✨ ${filteredGames.length} juego(s) disponible(s) en tu biblioteca para este criterio',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6C5FFF),
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF9999AA).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF9999AA).withOpacity(0.3),
                            ),
                          ),
                          child: const Text(
                            'No hay juegos disponibles con estos criterios',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF9999AA),
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
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
                            disabledBackgroundColor: const Color(
                              0xFF6C5FFF,
                            ).withOpacity(0.5),
                          ),
                          onPressed: filteredGames.isNotEmpty
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          RecommendationsScreen(
                                            games: filteredGames,
                                            availableTime: _selectedTime,
                                            preferredGenres: _selectedGenres
                                                .toList(),
                                          ),
                                    ),
                                  );
                                }
                              : null,
                          child: const Text(
                            '🎮 Ver sugerencias',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                        SizedBox(height: layout.height * 0.03),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
  String _sortBy = 'Tiempo jugado';
  bool _sortAscending = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Game> _sortGames(List<Game> games) {
    final sortedGames = List<Game>.from(games);

    if (_sortBy == 'Tiempo jugado') {
      sortedGames.sort(
        (a, b) => _sortAscending
            ? a.hours.compareTo(b.hours)
            : b.hours.compareTo(a.hours),
      );
    } else if (_sortBy == 'Nombre') {
      sortedGames.sort(
        (a, b) => _sortAscending
            ? a.title.compareTo(b.title)
            : b.title.compareTo(a.title),
      );
    }

    return sortedGames;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<SteamProvider>(
        builder: (context, steamProvider, _) {
          if (steamProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C5FFF)),
              ),
            );
          }

          if (steamProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Color(0xFF9999AA),
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${steamProvider.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF9999AA)),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<SteamProvider>().initialize();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C5FFF),
                    ),
                  ),
                ],
              ),
            );
          }

          // Si no hay juegos cargados
          if (steamProvider.games.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.videogame_asset_off,
                    color: Color(0xFF9999AA),
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No hay juegos en tu biblioteca',
                    style: TextStyle(color: Color(0xFF9999AA), fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<SteamProvider>().logout();
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Cambiar cuenta'),
                  ),
                ],
              ),
            );
          }

          final games = steamProvider.games;
          final filteredGames = _searchController.text.isEmpty
              ? _sortGames(games)
              : _sortGames(steamProvider.searchGames(_searchController.text));

          // Calcular horas totales
          final totalHours = games.fold<double>(
            0,
            (sum, game) => sum + game.hours,
          );
          final layout = _Layout(context);

          return SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      layout.horizontal,
                      16,
                      layout.horizontal,
                      8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tu Biblioteca',
                          style: TextStyle(
                            fontSize: layout.titleSize * 0.65,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${games.length} juegos • ${totalHours.toStringAsFixed(1)}h totales',
                          style: TextStyle(
                            fontSize: layout.subtitleSize,
                            color: const Color(0xFF9999AA),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: layout.horizontal),
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
                            hintText: 'Buscar en tu biblioteca...',
                            hintStyle: const TextStyle(
                              color: Color(0xFF9999AA),
                            ),
                            border: InputBorder.none,
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Color(0xFF9999AA),
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? GestureDetector(
                                    onTap: () {
                                      _searchController.clear();
                                      setState(() {});
                                    },
                                    child: const Icon(
                                      Icons.close,
                                      color: Color(0xFF9999AA),
                                    ),
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Filter info con opciones de ordenamiento
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${filteredGames.length} juegos',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF9999AA),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: const Color(0xFF1A1A2E),
                                builder: (context) => Container(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Ordenar por',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      ListTile(
                                        title: const Text(
                                          'Tiempo jugado',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        trailing: _sortBy == 'Tiempo jugado'
                                            ? const Icon(
                                                Icons.check,
                                                color: Color(0xFF6C5FFF),
                                              )
                                            : null,
                                        onTap: () {
                                          setState(
                                            () => _sortBy = 'Tiempo jugado',
                                          );
                                          Navigator.pop(context);
                                        },
                                      ),
                                      ListTile(
                                        title: const Text(
                                          'Nombre',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        trailing: _sortBy == 'Nombre'
                                            ? const Icon(
                                                Icons.check,
                                                color: Color(0xFF6C5FFF),
                                              )
                                            : null,
                                        onTap: () {
                                          setState(() => _sortBy = 'Nombre');
                                          Navigator.pop(context);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.tune,
                                  color: Color(0xFF9999AA),
                                  size: 20,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Filtrar',
                                  style: TextStyle(
                                    color: Color(0xFF9999AA),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Games Grid
                      if (filteredGames.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Column(
                              children: const [
                                Icon(
                                  Icons.search_off,
                                  color: Color(0xFF9999AA),
                                  size: 48,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No se encontraron juegos',
                                  style: TextStyle(color: Color(0xFF9999AA)),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: layout.gridColumns,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 16,
                                childAspectRatio: layout.gridAspectRatio,
                              ),
                          itemCount: filteredGames.length,
                          itemBuilder: (context, index) {
                            final game = filteredGames[index];
                            return GameCard(game: game);
                          },
                        ),
                      SizedBox(height: layout.height * 0.03),
                    ],
                  ),
                ),
              ],
            ),
          ),
          );
        },
      ),
    );
  }
}

// Widget de tarjeta de juego
class GameCard extends StatefulWidget {
  final Game game;

  const GameCard({super.key, required this.game});

  @override
  State<GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<GameCard> {
  late int _currentImageAttempt;

  @override
  void initState() {
    super.initState();
    _currentImageAttempt = 0;
  }

  List<String> _getImageUrlCandidates() {
    final appId = widget.game.appId;
    return [
      'https://cdn.akamai.steamstatic.com/steam/apps/$appId/header.jpg',
      'https://cdn.akamai.steamstatic.com/steam/apps/$appId/capsule_467x181.jpg',
      'https://cdn.akamai.steamstatic.com/steam/apps/$appId/capsule_231x87.jpg',
      'https://cdn.akamai.steamstatic.com/steam/apps/$appId/library_600x900_2x.jpg',
    ];
  }

  String get _currentImageUrl {
    final candidates = _getImageUrlCandidates();
    return candidates[_currentImageAttempt % candidates.length];
  }

  @override
  Widget build(BuildContext context) {
    final hoursDisplay = widget.game.hours < 1
        ? '${(widget.game.hours * 60).toInt()}m'
        : '${widget.game.hours.toStringAsFixed(1)}h';
    return LayoutBuilder(
      builder: (context, constraints) {
        final imageHeight = (constraints.maxWidth * 1.15).clamp(100.0, 180.0);

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GameDetailScreen(
                  game: widget.game,
                ),
              ),
            );
          },
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: imageHeight,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF6C5FFF).withOpacity(0.2),
              ),
            ),
            child: Stack(
              children: [
                // Game image from Steam with multiple URL fallbacks
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _currentImageUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Try next URL candidate
                      if (_currentImageAttempt <
                          _getImageUrlCandidates().length - 1) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() {
                              _currentImageAttempt++;
                            });
                          }
                        });
                        return Image.network(
                          _currentImageUrl,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholder();
                          },
                        );
                      }
                      return _buildPlaceholder();
                    },
                  ),
                ),
                // Time badge - bottom left
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C5FFF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.schedule,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          hoursDisplay,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Owned badge - top right
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Game title
          Text(
            widget.game.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // App ID (Steam ID)
          Text(
            'App ID: ${widget.game.appId}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF9999AA)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
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
    );
  }
}
