import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/steam_provider.dart';
import '../services/google_drive_service.dart';
import '../services/database_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SteamProvider>().refreshProfile();
    });
  }

  String _formatDate(DateTime date) {
    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showChangePhotoDialog() async {
    final googleDrive = GoogleDriveService();

    try {
      // Verificar y autenticar con Google Drive
      if (!googleDrive.isAuthenticated) {
        print('⏳ Autenticando con Google Drive...');
        final authenticated = await googleDrive.authenticate();
        if (!authenticated) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ No se pudo autenticar con Google Drive'),
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }
      }

      // Buscar la carpeta central si no está configurada
      if (googleDrive.centralFolderId == null) {
        print('🔍 Buscando carpeta centralizada...');
        final folderId = await googleDrive.searchFolderByName('Tip-Top-Games-Fotos');

        if (folderId != null) {
          googleDrive.setCentralFolderId(folderId);
          print('✅ Carpeta centralizada encontrada: $folderId');
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ No se encontró la carpeta. Crea una carpeta llamada "Tip-Top-Games-Fotos" en tu Drive'),
              duration: Duration(seconds: 4),
            ),
          );
          return;
        }
      }

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text(
            'Cambiar foto de perfil',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            '¿Cómo deseas cargar tu foto?',
            style: TextStyle(color: Color(0xFF9999AA)),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.camera);
              },
              child: const Text('Cámara'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.gallery);
              },
              child: const Text('Galería'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('❌ Error al preparar cambio de foto: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final imagePicker = ImagePicker();
      final pickedFile = await imagePicker.pickImage(source: source);

      if (pickedFile == null) return;

      // Mostrar loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C5FFF)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Subiendo imagen...',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      );

      // Obtener usuario actual
      final provider = context.read<SteamProvider>();
      final user = provider.appUser;

      if (user == null) {
        if (mounted) {
          Navigator.pop(context); // Cerrar loading
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: Usuario no encontrado'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Inicializar Google Drive
      final googleDrive = GoogleDriveService();
      final isAuthenticated = await googleDrive.checkAuthentication();

      if (!isAuthenticated) {
        final authenticated = await googleDrive.authenticate();
        if (!authenticated) {
          if (mounted) {
            Navigator.pop(context); // Cerrar loading
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error: No se pudo autenticar con Google'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      // Subir imagen a Google Drive
      final imageUrl = await googleDrive.uploadProfileImage(
        gameUser: user.gameUser,
        filePath: pickedFile.path,
        fileName: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      if (imageUrl == null) {
        if (mounted) {
          Navigator.pop(context); // Cerrar loading
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al subir la imagen'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Guardar URL en la base de datos
      final db = DatabaseService();
      await db.updateUserProfileImage(user.id!, imageUrl);

      // Actualizar provider
      await provider.refreshProfile();

      if (mounted) {
        Navigator.pop(context); // Cerrar loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Foto de perfil actualizada'),
            backgroundColor: Color(0xFF6C5FFF),
          ),
        );
      }
    } catch (e) {
      print('Error al subir imagen: $e');
      if (mounted) {
        Navigator.pop(context); // Cerrar loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<SteamProvider>(
        builder: (context, provider, _) {
          final user = provider.appUser;

          if (user == null) {
            return const Center(
              child: Text(
                'No hay sesión activa',
                style: TextStyle(color: Color(0xFF9999AA)),
              ),
            );
          }

          if (provider.isLoading && provider.userInfo == null) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C5FFF)),
              ),
            );
          }

          final steamInfo = provider.userInfo;
          final displayName = user.gameUser;
          final profileUrl = steamInfo?['profileurl'] as String?;
          final countryCode = steamInfo?['loccountrycode'] as String?;
          final realName = steamInfo?['realname'] as String?;
          final steamName = steamInfo?['personaname'] as String?;

          return RefreshIndicator(
            color: const Color(0xFF6C5FFF),
            backgroundColor: const Color(0xFF1A1A2E),
            onRefresh: provider.refreshProfile,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProfileHeader(
                    displayName: displayName,
                    subtitle: user.email,
                    profileImageUrl: user.profileImageUrl,
                    onChangePhoto: _showChangePhotoDialog,
                    onRefresh: provider.refreshProfile,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (provider.error != null) ...[
                          const SizedBox(height: 16),
                          _ErrorBanner(message: provider.error!),
                        ],
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                icon: Icons.videogame_asset,
                                label: 'Juegos',
                                value: '${provider.gamesCount}',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.schedule,
                                label: 'Horas totales',
                                value: provider.totalPlaytimeHours < 1
                                    ? '${(provider.totalPlaytimeHours * 60).toInt()}m'
                                    : '${provider.totalPlaytimeHours.toStringAsFixed(1)}h',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        const _SectionTitle('Cuenta Tip-Top'),
                        const SizedBox(height: 12),
                        _InfoTile(
                          icon: Icons.person_outline,
                          label: 'Usuario',
                          value: user.gameUser,
                        ),
                        _InfoTile(
                          icon: Icons.email_outlined,
                          label: 'Correo',
                          value: user.email,
                        ),
                        _InfoTile(
                          icon: Icons.calendar_today_outlined,
                          label: 'Miembro desde',
                          value: _formatDate(user.createdAt),
                        ),
                        _InfoTile(
                          icon: Icons.update,
                          label: 'Última actualización',
                          value: _formatDate(user.updatedAt),
                        ),
                        const SizedBox(height: 28),
                        const _SectionTitle('Steam'),
                        const SizedBox(height: 12),
                        if (user.steamId != null) ...[
                          _InfoTile(
                            icon: Icons.badge_outlined,
                            label: 'Steam ID',
                            value: user.steamId!,
                            copyable: true,
                          ),
                          if (steamInfo != null)
                            _InfoTile(
                              icon: Icons.person,
                              label: 'Nombre en Steam',
                              value: steamName ?? 'No disponible',
                            ),
                          if (realName != null && realName.isNotEmpty)
                            _InfoTile(
                              icon: Icons.badge,
                              label: 'Nombre real',
                              value: realName,
                            ),
                          if (countryCode != null)
                            _InfoTile(
                              icon: Icons.public,
                              label: 'País',
                              value: countryCode,
                            ),
                          if (profileUrl != null)
                            _ActionTile(
                              icon: Icons.open_in_new,
                              label: 'Ver perfil en Steam',
                              onTap: () => _openUrl(profileUrl),
                            ),
                        ] else
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A2E),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    const Color(0xFF6C5FFF).withOpacity(0.2),
                              ),
                            ),
                            child: const Text(
                              'No tienes una cuenta de Steam vinculada.',
                              style: TextStyle(
                                color: Color(0xFF9999AA),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: provider.isLoading
                                ? null
                                : () => provider.logout(),
                            icon: const Icon(Icons.logout, size: 20),
                            label: const Text('Cerrar sesión'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: BorderSide(
                                color: Colors.redAccent.withOpacity(0.6),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
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

class _ProfileHeader extends StatelessWidget {
  final String displayName;
  final String subtitle;
  final String? profileImageUrl;
  final VoidCallback onChangePhoto;
  final VoidCallback onRefresh;

  const _ProfileHeader({
    required this.displayName,
    required this.subtitle,
    this.profileImageUrl,
    required this.onChangePhoto,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.paddingOf(context).top + 16,
        16,
        28,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6C5FFF).withOpacity(0.25),
            const Color(0xFF0F0F1E),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF6C5FFF).withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mi Perfil',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              IconButton(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh, color: Color(0xFF9999AA)),
                tooltip: 'Actualizar',
              ),
            ],
          ),
          const SizedBox(height: 20),
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF6C5FFF),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C5FFF).withOpacity(0.3),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: profileImageUrl != null && profileImageUrl!.isNotEmpty
                      ? Image.network(
                          profileImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _AvatarFallback(
                            name: displayName,
                          ),
                        )
                      : _AvatarFallback(name: displayName),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: onChangePhoto,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C5FFF),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF0F0F1E), width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            displayName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 13, color: Color(0xFF9999AA)),
          ),
        ],
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final String name;

  const _AvatarFallback({required this.name});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      color: const Color(0xFF6C5FFF),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Color(0xFF9999AA),
        letterSpacing: 0.8,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6C5FFF).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF6C5FFF), size: 22),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF9999AA)),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool copyable;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.copyable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF6C5FFF).withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF6C5FFF)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9999AA),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (copyable)
            IconButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Steam ID copiado'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.copy, size: 18, color: Color(0xFF9999AA)),
              tooltip: 'Copiar',
            ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1A1A2E),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF6C5FFF).withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF6C5FFF)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6C5FFF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF9999AA),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.4)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Colors.redAccent, fontSize: 13),
      ),
    );
  }
}
