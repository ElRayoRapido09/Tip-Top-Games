# 🎮 Tip-Top Games

Una app de Flutter que recomienda juegos de tu biblioteca de Steam según el tiempo disponible.

## ✨ Características

- 🔑 Login con tu cuenta Steam
- 📚 Carga automática de tu biblioteca de juegos
- ⏱️ Filtra juegos por tiempo disponible
- 🔍 Busca juegos en tu biblioteca
- 🎯 Recomendaciones personalizadas

## 📋 Requisitos Previos

- Flutter 3.8.0 o superior
- Dart 3.0.0 o superior
- Steam API Key (gratis)

## ⚠️ Importante: Solución CORS para Web

Si ejecutas la app en **Flutter Web**, necesitas levantar un **servidor proxy** para evitar errores CORS con Steam API.

### 🚀 Ejecución Rápida (Windows)

```bash
# Haz doble click en:
start_server.bat
```

### 🚀 Ejecución Rápida (Mac/Linux)

```bash
chmod +x start_server.sh
./start_server.sh
```

### 📝 Ejecución Manual

```bash
# Terminal 1: Inicia el servidor proxy
cd server
dart pub get
dart run bin/server.dart

# Terminal 2: Ejecuta la app (esperando 5 segundos)
flutter run -d chrome
```

## 🔧 Configuración Inicial

1. **Obtén tu Steam API Key**
   - Visita: https://steamcommunity.com/dev/apikey
   - Copia tu clave

2. **Ya está configurada en el proyecto**
   - El servidor proxy usa la API Key automáticamente

3. **Obtén tu Steam ID**
   - Visita: https://steamcommunity.com/profiles
   - Copia el número de 17 dígitos

## 🎯 Cómo Usar

1. Abre la app
2. Ingresa tu Steam ID (número de 17 dígitos)
3. ¡Listo! Tu biblioteca se cargará automáticamente

## 📁 Estructura del Proyecto

```
.
├── lib/                          # Código principal
│   ├── main.dart                # Entrada de la app
│   ├── models/
│   │   └── game.dart            # Modelo de juego
│   ├── services/
│   │   ├── steam_auth_service.dart    # Autenticación
│   │   └── steam_api_service.dart     # Conexión Steam API
│   ├── providers/
│   │   └── steam_provider.dart   # State management
│   └── screens/
│       └── steam_login_screen.dart    # Pantalla de login
├── server/                       # Backend proxy CORS
│   ├── bin/
│   │   └── server.dart          # Servidor
│   ├── pubspec.yaml
│   └── README.md
├── pubspec.yaml
├── STEAM_INTEGRATION.md         # Detalles técnicos
├── start_server.bat             # Script para Windows
└── start_server.sh              # Script para Mac/Linux
```

## 🌐 Plataformas Soportadas

| Plataforma | Estado | Requiere Proxy |
|-----------|--------|----------------|
| Flutter Web | ✅ | Sí |
| Android | ✅ | No |
| iOS | ✅ | No |
| Windows | ✅ | No |
| macOS | ✅ | No |
| Linux | ✅ | No |

## 🐛 Troubleshooting

### Error: "Servidor proxy no disponible"

Solución:
```bash
# En una terminal nueva, ejecuta:
start_server.bat  # Windows
# o
./start_server.sh # Mac/Linux
```

### Error: "Usuario no encontrado"

- Verifica que el Steam ID sea válido (17 dígitos)
- Asegúrate de que la biblioteca sea pública

### Error: CORS origin

- Verifica que el servidor proxy esté corriendo en `http://localhost:8765`
- Intenta acceder a http://localhost:8765/health en el navegador

### Error: `errno = 10013` al iniciar el proxy (Windows)

Windows reserva rangos de puertos (Hyper-V, WSL, Docker). Si el **8080** está en un rango excluido, el servidor no puede abrirlo. Este proyecto usa el puerto **8765** por defecto. Para otro puerto:

```powershell
$env:STEAM_PROXY_PORT="9000"
dart run server/bin/server.dart
```

Y en Flutter: `flutter run -d chrome --dart-define=STEAM_PROXY_URL=http://localhost:9000`

## 📚 Documentación Adicional

- [STEAM_INTEGRATION.md](STEAM_INTEGRATION.md) - Detalles técnicos
- [server/README.md](server/README.md) - Documentación del servidor

## 🔐 Seguridad

⚠️ **Nota de Desarrollo**: La API Key está en el código. En producción:
- Usa variables de entorno
- Oculta la API Key del cliente
- Implementa autenticación segura

## 🔗 Enlaces Útiles

- [Steam API Documentation](https://steamcommunity.com/dev)
- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Documentation](https://dart.dev/guides)

---

Hecho con ❤️ para gamers que quieren jugar mejor.

