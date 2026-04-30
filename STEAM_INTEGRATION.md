# Integración con Steam - Tip-Top Games

## Configuración Requerida

Para que la integración con Steam funcione correctamente, necesitas obtener una **Steam Web API Key**.

### Pasos para obtener tu Steam API Key:

1. **Crea una cuenta en Steam** (si aún no la tienes)
   - Visita: https://steamcommunity.com/

2. **Obtén tu API Key**
   - Visita: https://steamcommunity.com/dev/apikey
   - Inicia sesión con tu cuenta de Steam
   - Acepta el acuerdo y obtén tu clave

3. **Configura la clave en el proyecto**
   - Abre [lib/services/steam_api_service.dart](lib/services/steam_api_service.dart)
   - Reemplaza `YOUR_STEAM_API_KEY` con tu clave real:
   ```dart
   static const String _apiKey = 'TU_CLAVE_AQUI';
   ```

## Cómo Encontrar tu Steam ID

Tu Steam ID es un número de 17 dígitos que identifica tu cuenta:

1. Visita: https://steamcommunity.com/profiles
2. Verás tu URL con tu Steam ID (ej: `/profiles/76561198123456789`)
3. Copia el número al ingresar en la app

## Características Implementadas

✅ **Autenticación con Steam**
- Login con Steam ID
- Almacenamiento seguro de sesión local
- Cierre de sesión

✅ **Carga de Biblioteca**
- Obtiene todos los juegos de tu biblioteca de Steam
- Muestra nombre del juego, horas jugadas, y imagen

✅ **Filtrado de Juegos**
- Filtrar por tiempo de juego
- Buscar juegos por nombre
- Filtrar por género (preparado para expansión)

✅ **Pantallas**
- **Pantalla de Login**: Ingresa tu Steam ID para conectar
- **Pantalla de Inicio**: Filtra juegos por tiempo disponible
- **Pantalla de Biblioteca**: Ve todos tus juegos con búsqueda
- **Pantalla de Perfil**: Información del usuario (placeholder)

## Estructura del Proyecto

```
lib/
├── main.dart                    # Aplicación principal
├── models/
│   └── game.dart               # Modelo de juego
├── services/
│   ├── steam_auth_service.dart  # Autenticación local
│   └── steam_api_service.dart   # Conexión con Steam API
├── providers/
│   └── steam_provider.dart      # State management
└── screens/
    └── steam_login_screen.dart  # Pantalla de login
```

## API de Steam Utilizada

- **GetOwnedGames**: Obtiene lista de juegos del usuario
- **GetPlayerSummaries**: Obtiene información del perfil
- **ResolveVanityURL**: Resuelve URLs personalizadas a Steam ID

## Notas de Desarrollo

- **Seguridad**: La API key debería estar en variables de entorno en producción
- **Caché**: Se puede implementar caché local para mejorar performance
- **Géneros**: Los géneros de juegos vienen vacíos y requieren otra llamada API
- **Imágenes**: Se usan URLs directas de Steam (pueden no cargar en todas las regiones)

## Próximas Mejoras Sugeridas

- Implementar flujo OpenID de Steam (autenticación más segura)
- Agregar caché de datos
- Obtener géneros reales de los juegos
- Integrar con API de Gemini para recomendaciones IA
- Implementar sincronización automática
- Agregar estadísticas de juego
