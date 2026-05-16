import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'dart:io';
import '../config/drive_config.dart';

class GoogleDriveService {
  static final GoogleDriveService _instance = GoogleDriveService._internal();
  
  late GoogleSignIn _googleSignIn;
  drive.DriveApi? _driveApi;
  
  // IDs de carpetas
  String? _centralFolderId;  // Carpeta central única para todas las fotos
  Map<String, String> _userFolderIds = {};

  factory GoogleDriveService() {
    return _instance;
  }

  GoogleDriveService._internal() {
    _googleSignIn = GoogleSignIn(
      scopes: [drive.DriveApi.driveScope],
      clientId: DriveConfig.googleClientId.isNotEmpty ? DriveConfig.googleClientId : '128910010955-50npiada6hojrfej2uv450vls6s83da9.apps.googleusercontent.com',
    );
    
    // Si el ID de carpeta centralizada está configurado, usarlo
    if (DriveConfig.centralFolderId.isNotEmpty) {
      _centralFolderId = DriveConfig.centralFolderId;
      print('✅ Carpeta centralizada pre-configurada: ${DriveConfig.centralFolderId}');
    }
  }

  /// Inicializar sesión con Google
  Future<bool> authenticate() async {
    try {
      print('🔐 Iniciando autenticación con Google...');
      
      final account = await _googleSignIn.signIn();
      if (account == null) {
        print('⚠️ El usuario canceló la autenticación');
        return false;
      }

      print('✅ Usuario autenticado: ${account.email}');

      final auth = await account.authentication;
      final accessToken = auth.accessToken;

      if (accessToken == null) {
        print('❌ No se pudo obtener access token');
        print('📝 Verifica que:');
        print('   1. Las credenciales OAuth están configuradas correctamente');
        print('   2. Tu cuenta de Google tiene permiso para acceder a Drive');
        print('   3. La aplicación tiene permisos de Drive API');
        return false;
      }

      print('✅ Access token obtenido');

      // Crear Drive API con cliente autenticado
      final httpClient = _AuthenticatedHttpClient(accessToken);
      _driveApi = drive.DriveApi(httpClient);
      
      print('✅ DriveApi inicializada correctamente');
      
      return true;
    } on Exception catch (e) {
      print('❌ Error en autenticación Google: $e');
      print('📝 Detalles del error:');
      print('   - Tipo: ${e.runtimeType}');
      print('   - Mensaje: ${e.toString()}');
      return false;
    } catch (e) {
      print('❌ Error inesperado en autenticación: $e');
      return false;
    }
  }

  /// Establecer ID de carpeta central (llamar antes de subir imágenes)
  void setCentralFolderId(String folderId) {
    _centralFolderId = folderId;
    print('✅ Carpeta central establecida: $folderId');
  }

  /// Obtener ID de carpeta central por nombre
  Future<String?> searchFolderByName(String folderName) async {
    if (_driveApi == null) {
      print('❌ DriveApi no inicializada. Autentica primero.');
      return null;
    }

    try {
      print('🔍 Buscando carpeta: "$folderName"');
      
      final query = "name='$folderName' and mimeType='application/vnd.google-apps.folder' and trashed=false";
      final result = await _driveApi!.files.list(
        q: query,
        spaces: 'drive',
        pageSize: 1,
      );

      if (result.files != null && result.files!.isNotEmpty) {
        final folderId = result.files!.first.id;
        print('✅ Carpeta encontrada: $folderName');
        print('   - ID: $folderId');
        return folderId;
      }
      
      print('⚠️ Carpeta NO encontrada: $folderName');
      print('📝 Por favor:');
      print('   1. Crea una carpeta llamada "$folderName" en tu Google Drive');
      print('   2. Intenta de nuevo');
      return null;
    } on Exception catch (e) {
      print('❌ Error al buscar carpeta: $e');
      print('📝 Verifica:');
      print('   1. Tienes conexión a internet');
      print('   2. Tu sesión de Google sigue activa');
      print('   3. Tienes permisos en Google Drive');
      return null;
    }
  }

  /// Subir archivo de imagen a la carpeta central
  Future<String?> uploadProfileImage({
    required String gameUser,
    required String filePath,
    String? fileName,
  }) async {
    if (_driveApi == null) {
      print('❌ DriveApi no inicializada');
      throw Exception('DriveApi no inicializada. Autentica primero.');
    }

    if (_centralFolderId == null) {
      print('❌ Carpeta central no establecida');
      throw Exception('Carpeta central no configurada. Contacta al administrador.');
    }

    try {
      print('📤 Iniciando subida de imagen de perfil...');
      print('   - Usuario: $gameUser');
      print('   - Carpeta destino: $_centralFolderId');
      
      // Preparar archivo
      final file = File(filePath);
      if (!await file.exists()) {
        print('❌ El archivo no existe: $filePath');
        throw Exception('El archivo no existe: $filePath');
      }

      final fileSize = await file.length();
      print('   - Tamaño: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');

      // Crear nombre del archivo con usuario y timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uploadFileName = fileName ?? 'profile_${gameUser}_$timestamp.jpg';
      
      print('   - Nombre en Drive: $uploadFileName');

      // Crear metadatos del archivo
      final fileMetadata = drive.File()
        ..name = uploadFileName
        ..parents = [_centralFolderId!];

      // Subir archivo
      final fileContent = file.openRead();
      
      print('⏳ Subiendo archivo a Google Drive...');
      
      final driveFile = await _driveApi!.files.create(
        fileMetadata,
        uploadMedia: drive.Media(fileContent, fileSize),
      );

      if (driveFile.id == null) {
        print('❌ No se pudo subir el archivo');
        throw Exception('No se pudo subir el archivo');
      }

      print('✅ Archivo subido exitosamente');
      print('   - File ID: ${driveFile.id}');

      // Hacer archivo público (para que se vea sin iniciar sesión)
      await _makeFilePublic(driveFile.id!);

      // Obtener URL compartible
      final fileUrl = _getPublicFileUrl(driveFile.id!);

      print('✅ Imagen de perfil subida completamente');
      print('   - URL pública: $fileUrl');

      return fileUrl;
    } on Exception catch (e) {
      print('❌ Error al subir imagen: $e');
      print('📝 Detalles:');
      print('   - Tipo: ${e.runtimeType}');
      print('   - Mensaje: ${e.toString()}');
      rethrow;
    }
  }

  /// Hacer archivo público
  Future<void> _makeFilePublic(String fileId) async {
    if (_driveApi == null) throw Exception('DriveApi no inicializada');

    try {
      final permission = drive.Permission()
        ..type = 'anyone'
        ..role = 'reader';

      await _driveApi!.permissions.create(permission, fileId);
      print('✅ Archivo hecho público: $fileId');
    } catch (e) {
      print('⚠️ Error al hacer archivo público (continuando): $e');
      // No es crítico, continuar aunque falle
    }
  }

  /// Obtener URL pública del archivo
  String _getPublicFileUrl(String fileId) {
    return 'https://drive.google.com/uc?id=$fileId&export=view';
  }

  /// Listar imágenes en la carpeta central
  Future<List<drive.File>> getProfileImages() async {
    if (_driveApi == null) throw Exception('DriveApi no inicializada');

    if (_centralFolderId == null) {
      print('⚠️ Carpeta central no establecida');
      return [];
    }

    try {
      final query = "parents in '$_centralFolderId' and trashed=false";
      final result = await _driveApi!.files.list(
        q: query,
        spaces: 'drive',
        orderBy: 'createdTime desc',
        pageSize: 50,
      );

      return result.files ?? [];
    } catch (e) {
      print('❌ Error al listar imágenes: $e');
      return [];
    }
  }

  /// Obtener usuario actual
  GoogleSignInAccount? getCurrentUser() {
    return _googleSignIn.currentUser;
  }

  /// Verificar si está autenticado
  bool get isAuthenticated => _driveApi != null;

  /// Obter ID de carpeta central
  String? get centralFolderId => _centralFolderId;

  /// Cerrar sesión
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _driveApi = null;
    _userFolderIds.clear();
    print('✅ Sesión cerrada');
  }

  /// Verificar autenticación actual
  Future<bool> checkAuthentication() async {
    return await _googleSignIn.isSignedIn();
  }
}

/// Cliente HTTP autenticado para Google Drive API
class _AuthenticatedHttpClient extends http.BaseClient {
  final String _accessToken;
  final http.Client _inner = http.Client();

  _AuthenticatedHttpClient(this._accessToken);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_accessToken';
    return _inner.send(request);
  }
}
