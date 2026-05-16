/// Configuración de Google Drive para la aplicación
/// 
/// IMPORTANTE: Actualiza estos valores con la información de tu Drive
class DriveConfig {
  /// El ID de la carpeta centralizada donde se guardarán todas las fotos de perfil
  /// 
  /// Para obtener el ID:
  /// 1. Abre Google Drive
  /// 2. Navega a tu carpeta de almacenamiento (ej: Tip-Top-Games-Fotos)
  /// 3. La URL será: https://drive.google.com/drive/folders/[ESTE_ES_EL_ID]
  /// 4. Copia el ID entre /folders/ y el final
  /// 
  /// Ejemplo: 
  /// static const String centralFolderId = '1A2B3C4D5E6F7G8H9I0J';
  static const String centralFolderId = '1bFnma26JCqfX3IkY39NXJzrb_JkPHo-J';
  
  /// Nombre de la carpeta centralizada (para búsqueda automática si el ID está vacío)
  static const String centralFolderName = 'Tip-Top-Games-Fotos';
  
  /// Google OAuth Client ID (obtén esto del Google Cloud Console)
  /// Si está vacío, se usará un cliente ID por defecto
  static const String googleClientId = '128910010955-50npiada6hojrfej2uv450vls6s83da9.apps.googleusercontent.com';
}
