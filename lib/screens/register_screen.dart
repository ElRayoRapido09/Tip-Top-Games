import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/steam_api_service.dart';
import '../models/app_user.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _gameUserController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _error;
  AppUser? _createdUser;
  final _steamApiService = SteamApiService();
  bool _showPassword = false;

  @override
  void dispose() {
    _gameUserController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Validar el formulario
  bool _validateForm() {
    if (_gameUserController.text.isEmpty) {
      _setError('El nombre de usuario es requerido');
      return false;
    }

    if (_gameUserController.text.length < 3) {
      _setError('El nombre de usuario debe tener al menos 3 caracteres');
      return false;
    }

    if (_emailController.text.isEmpty) {
      _setError('El correo es requerido');
      return false;
    }

    if (!_isValidEmail(_emailController.text)) {
      _setError('Correo inválido');
      return false;
    }

    if (_passwordController.text.isEmpty) {
      _setError('La contraseña es requerida');
      return false;
    }

    if (_passwordController.text.length < 6) {
      _setError('La contraseña debe tener al menos 6 caracteres');
      return false;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _setError('Las contraseñas no coinciden');
      return false;
    }

    return true;
  }

  /// Validar email
  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[A-Za-z]+\.[A-Za-z]+$').hasMatch(email.trim());
  }

  /// Establecer error
  void _setError(String message) {
    setState(() {
      _error = message;
    });
  }

  /// Registrar usuario
  Future<void> _registerUser() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);
    _clearError();

    try {
      final db = DatabaseService();

      // Verificar si el usuario ya existe
      if (await db.gameUserExists(_gameUserController.text.trim())) {
        _setError('Este nombre de usuario ya existe');
        return;
      }

      if (await db.emailExists(_emailController.text.trim())) {
        _setError('Este correo ya está registrado');
        return;
      }

      // Crear usuario
      final user = await db.createUser(
        gameUser: _gameUserController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      setState(() => _createdUser = user);

      // Nota: La carpeta de Google Drive será creada automáticamente cuando el usuario
      // suba su primera imagen de perfil (si existe una carpeta centralizada configurada)

      // Mostrar pantalla de vinculación de Steam
      if (mounted) {
        _showSteamLinkingDialog();
      }
    } catch (e) {
      _setError('Error al registrar: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Mostrar diálogo para vincular Steam
  void _showSteamLinkingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SteamLinkingDialog(
        onSteamLinked: (steamId) async {
          if (_createdUser != null) {
            await DatabaseService().linkSteamId(_createdUser!.id!, steamId);

            if (mounted) {
              Navigator.pop(context); // Cerrar diálogo
              _showSuccessAndNavigateToLogin();
            }
          }
        },
        onSkip: () {
          Navigator.pop(context); // Cerrar diálogo
          _showSuccessAndNavigateToLogin();
        },
        steamApiService: _steamApiService,
      ),
    );
  }

  /// Mostrar éxito y navegar a login
  void _showSuccessAndNavigateToLogin() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          '✅ Registro Exitoso',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Tu cuenta ha sido creada exitosamente.\nAhora puedes iniciar sesión.',
          style: TextStyle(color: Color(0xFF9999AA)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Cerrar diálogo
              Navigator.pop(context); // Volver a login
            },
            child: const Text(
              'Iniciar Sesión',
              style: TextStyle(color: Color(0xFF6C5FFF)),
            ),
          ),
        ],
      ),
    );
  }

  /// Limpiar error
  void _clearError() {
    setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Text(
                  'Crear Cuenta',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Únete a Tip-Top Games',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF9999AA),
                  ),
                ),
                const SizedBox(height: 32),

                // Formulario
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
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

                      // GameUser
                      TextField(
                        controller: _gameUserController,
                        decoration: InputDecoration(
                          hintText: 'Nombre de usuario',
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
                              color: const Color(0xFF6C5FFF).withOpacity(0.3),
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
                      ),
                      const SizedBox(height: 16),

                      // Email
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          hintText: 'Correo electrónico',
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
                              color: const Color(0xFF6C5FFF).withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF6C5FFF),
                            ),
                          ),
                          prefixIcon: const Icon(
                            Icons.email,
                            color: Color(0xFF6C5FFF),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.emailAddress,
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
                              color: const Color(0xFF6C5FFF).withOpacity(0.3),
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
                      ),
                      const SizedBox(height: 16),

                      // Confirm Password
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: !_showPassword,
                        decoration: InputDecoration(
                          hintText: 'Confirmar contraseña',
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
                              color: const Color(0xFF6C5FFF).withOpacity(0.3),
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
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 32),

                      // Register Button
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
                          onPressed: _isLoading ? null : _registerUser,
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
                                  'Registrarse',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Login link
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          const Text(
                            '¿Ya tienes cuenta? ',
                            style: TextStyle(
                              color: Color(0xFF9999AA),
                            ),
                          ),
                          GestureDetector(
                            onTap: () =>
                                Navigator.pop(context),
                            child: const Text(
                              'Inicia sesión',
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
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Diálogo para vincular Steam
class _SteamLinkingDialog extends StatefulWidget {
  final Function(String) onSteamLinked;
  final VoidCallback onSkip;
  final SteamApiService steamApiService;

  const _SteamLinkingDialog({
    required this.onSteamLinked,
    required this.onSkip,
    required this.steamApiService,
  });

  @override
  State<_SteamLinkingDialog> createState() => _SteamLinkingDialogState();
}

class _SteamLinkingDialogState extends State<_SteamLinkingDialog> {
  final _steamIdController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _steamIdController.dispose();
    super.dispose();
  }

  Future<void> _linkSteam() async {
    final steamId = _steamIdController.text.trim();

    if (steamId.isEmpty) {
      setState(() => _error = 'Ingresa tu Steam ID');
      return;
    }

    if (!RegExp(r'^\d{17}$').hasMatch(steamId)) {
      setState(() => _error = 'Steam ID inválido (debe ser 17 dígitos)');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Verificar que sea válido con Steam API
      final userInfo =
          await widget.steamApiService.getUserInfo(steamId);
      if (userInfo.isEmpty) {
        setState(
          () =>
              _error =
                  'No se pudo verificar el Steam ID',
        );
        return;
      }

      widget.onSteamLinked(steamId);
    } catch (e) {
      setState(() => _error = 'Error al vincular Steam: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      title: const Text(
        'Vincular Cuenta Steam',
        style: TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ingresa tu Steam ID de 17 dígitos para vincular tu cuenta:',
            style:
                TextStyle(
                  color: Color(0xFF9999AA),
                  fontSize: 12,
                ),
          ),
          const SizedBox(height: 16),
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.red),
              ),
              child: Text(
                _error!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _steamIdController,
            decoration: InputDecoration(
              hintText: '76561198123456789',
              hintStyle: const TextStyle(
                color: Color(0xFF9999AA),
              ),
              filled: true,
              fillColor: const Color(0xFF0F0F1E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(
                  color: const Color(0xFF6C5FFF)
                      .withOpacity(0.3),
                ),
              ),
            ),
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: _isLoading ? null : _linkSteam,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C5FFF),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<
                        Color>(Colors.white),
                  ),
                )
              : const Text('Vincular'),
        ),
      ],
    );
  }
}
