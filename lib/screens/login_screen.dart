import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/app_user.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final Function(AppUser) onLoginSuccess;

  const LoginScreen({
    super.key,
    required this.onLoginSuccess,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameOrEmailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _error;
  bool _showPassword = false;

  @override
  void dispose() {
    _usernameOrEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final usernameOrEmail = _usernameOrEmailController.text.trim();
    final password = _passwordController.text;

    if (usernameOrEmail.isEmpty) {
      _setError('Ingresa tu usuario o correo');
      return;
    }

    if (password.isEmpty) {
      _setError('Ingresa tu contraseña');
      return;
    }

    setState(() => _isLoading = true);
    _clearError();

    try {
      final db = DatabaseService();
      final user =
          await db.validateCredentials(usernameOrEmail, password);

      if (user == null) {
        _setError('Usuario o contraseña incorrectos');
        return;
      }

      // Login exitoso
      if (mounted) {
        widget.onLoginSuccess(user);
      }
    } catch (e) {
      _setError('Error al iniciar sesión: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _setError(String message) {
    setState(() => _error = message);
  }

  void _clearError() {
    setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: SafeArea(
        child: SingleChildScrollView(
          child: SizedBox(
            height:
                MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo/Header
                  const Spacer(),
                  const Text(
                    '🎮 Tip-Top Games',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6C5FFF),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Inicia sesión en tu cuenta',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF9999AA),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Error message
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Username/Email
                  TextField(
                    controller: _usernameOrEmailController,
                    decoration: InputDecoration(
                      hintText: 'Usuario o Correo',
                      hintStyle: const TextStyle(
                        color: Color(0xFF9999AA),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1A1A2E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF6C5FFF),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: const Color(0xFF6C5FFF)
                              .withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF6C5FFF),
                        ),
                      ),
                      prefixIcon: const Icon(
                        Icons.person,
                        color: Color(0xFF6C5FFF),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (_) => _clearError(),
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextField(
                    controller: _passwordController,
                    obscureText: !_showPassword,
                    decoration: InputDecoration(
                      hintText: 'Contraseña',
                      hintStyle: const TextStyle(
                        color: Color(0xFF9999AA),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1A1A2E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF6C5FFF),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: const Color(0xFF6C5FFF)
                              .withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF6C5FFF),
                        ),
                      ),
                      prefixIcon: const Icon(
                        Icons.lock,
                        color: Color(0xFF6C5FFF),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: const Color(0xFF6C5FFF),
                        ),
                        onPressed: () {
                          setState(() =>
                              _showPassword =
                                  !_showPassword);
                        },
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (_) => _clearError(),
                  ),
                  const SizedBox(height: 32),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF6C5FFF),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                      ),
                      onPressed:
                          _isLoading ? null : _login,
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child:
                                  CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<
                                        Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Iniciar Sesión',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Register link
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      const Text(
                        '¿No tienes cuenta? ',
                        style: TextStyle(
                          color: Color(0xFF9999AA),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const RegisterScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Registrate',
                          style: TextStyle(
                            color:
                                Color(0xFF6C5FFF),
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
