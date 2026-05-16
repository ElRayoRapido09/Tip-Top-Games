import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/steam_provider.dart';
import '../services/steam_api_service.dart';

class SteamLoginScreen extends StatefulWidget {
  const SteamLoginScreen({super.key});

  @override
  State<SteamLoginScreen> createState() => _SteamLoginScreenState();
}

class _SteamLoginScreenState extends State<SteamLoginScreen> {
  final TextEditingController _steamIdController = TextEditingController();
  bool _isLoading = false;
  bool? _proxyHealthy;

  @override
  void initState() {
    super.initState();
    _checkProxyHealth();
  }

  Future<void> _checkProxyHealth() async {
    if (!kIsWeb) {
      setState(() => _proxyHealthy = true);
      return;
    }
    final healthy = await SteamApiService.checkProxyHealth();
    setState(() {
      _proxyHealthy = healthy;
    });
  }

  @override
  void dispose() {
    _steamIdController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final steamId = _steamIdController.text.trim();

    if (steamId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa tu ID de Steam'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (mounted) {
        await context.read<SteamProvider>().loginWithSteamId(steamId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0F1E), Color(0xFF1A1A2E)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  // Logo/Icon
                  Container(
                    width: 100,
                    height: 100,
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
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.videogame_asset,
                      color: Color(0xFF6C5FFF),
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Proxy Status Warning (solo si _proxyHealthy es false)
                  if (_proxyHealthy == false)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.5)),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.warning_outlined,
                            color: Colors.red,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Servidor proxy no disponible',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Ejecuta: dart run server/bin/server.dart',
                                  style: TextStyle(
                                    color: Color(0xFF9999AA),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Title
                  const Text(
                    'Tip-Top Games',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Subtitle
                  const Text(
                    'Conecta con tu cuenta de Steam',
                    style: TextStyle(fontSize: 16, color: Color(0xFF9999AA)),
                  ),
                  const SizedBox(height: 60),
                  // Description
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF6C5FFF).withOpacity(0.2),
                      ),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Para continuar:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          '1. Visita: https://steamcommunity.com/profiles/',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9999AA),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '2. Copia tu ID de Steam de la URL (ej: 76561198...)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9999AA),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '3. Pégalo en el campo de abajo',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9999AA),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Input field
                  TextField(
                    controller: _steamIdController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      hintText: 'Tu ID de Steam (17 dígitos)',
                      hintStyle: const TextStyle(color: Color(0xFF9999AA)),
                      prefixIcon: const Icon(
                        Icons.badge,
                        color: Color(0xFF9999AA),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1A1A2E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF6C5FFF)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: const Color(0xFF6C5FFF).withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF6C5FFF),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Login button
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
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Conectar con Steam',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
