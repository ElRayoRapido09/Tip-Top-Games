# Solución CORS para Flutter Web + Steam API

## El Problema

Steam API no permite solicitudes CORS desde navegadores web. Cuando usas Flutter Web, el navegador bloquea las llamadas directas a Steam API con el error:

```
Access to fetch at 'https://api.steampowered.com/...' has been blocked by CORS policy
```

## La Solución

Hemos creado un **backend proxy** en Dart que actúa como intermediario:

```
Flutter Web (localhost:51499)
        ↓
Proxy Server (localhost:8080)  ← Habilita CORS
        ↓
Steam API (api.steampowered.com)
```

## Instalación y Ejecución

### 1. Instalar dependencias del servidor

```bash
cd server
dart pub get
cd ..
```

### 2. Ejecutar el servidor proxy

```bash
dart run server/bin/server.dart
```

O en desarrollo (con auto-reload):

```bash
dart run --enable-vm-service server/bin/server.dart
```

Deberías ver:
```
Servidor proxy ejecutándose en: http://localhost:8080
CORS habilitado para todas las solicitudes
```

### 3. Ejecutar la app Flutter

En otra terminal:

```bash
flutter run -d chrome
```

O en web:

```bash
flutter run -d web-server
```

## Cómo Funciona

### En Web
- Detecta que está corriendo en navegador
- Usa `http://localhost:8080` como proxy
- El proxy redirige las solicitudes a Steam API con CORS headers

### En Mobile/Desktop
- Detecta que es Android/iOS/Windows/macOS/Linux
- Hace llamadas **directas** a Steam API (sin CORS)
- No necesita el proxy

## Endpoints del Proxy

```
GET /health
  → Verifica que el servidor esté activo

GET /library?steamid=XXXX
  → Obtiene biblioteca de juegos
  
GET /userinfo?steamid=XXXX
  → Obtiene información del usuario

GET /vanityurl?vanityurl=XXXX
  → Resuelve vanity URL a Steam ID
```

## Estructura del Proyecto

```
server/
├── bin/
│   └── server.dart          # Servidor proxy
├── pubspec.yaml             # Dependencias
└── README.md

lib/
├── services/
│   └── steam_api_service.dart  # Auto-detecta plataforma
└── ...
```

## Troubleshooting

### Error: "Servidor proxy no disponible"

1. Verifica que ejecutaste: `dart run server/bin/server.dart`
2. Verifica que el servidor esté en `http://localhost:8080`
3. Intenta acceder a http://localhost:8080/health en el navegador

### Error: "steamid requerido"

Verifica que estés enviando un Steam ID válido (17 dígitos)

### Error en Steam API

- Verifica tu API Key en `steam_api_service.dart`
- Visita: https://steamcommunity.com/dev/apikey

## Notas Importantes

⚠️ **La API Key está en el código**  
En producción, deberías:
- Usar variables de entorno
- Implementar autenticación
- No exponer la API Key en el cliente

## URLs de Referencia

- **Steam API Docs**: https://steamcommunity.com/dev
- **CORS Info**: https://developer.mozilla.org/es/docs/Web/HTTP/CORS
- **Shelf (Framework usado)**: https://pub.dev/packages/shelf
