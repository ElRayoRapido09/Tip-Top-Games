# ⚡ Guía Rápida - CORS Resuelto

## El Problema que Resolvimos

```
❌ Error: Access to fetch at 'https://api.steampowered.com/...' 
         has been blocked by CORS policy
```

## La Solución: Proxy Backend

Ahora tienes un servidor que actúa como intermediario:

```
Flutter Web (localhost:51499)
        ↓
Proxy Server (localhost:8080) ← Habilita CORS
        ↓
Steam API (api.steampowered.com) ✅
```

---

## 🚀 PASOS PARA EJECUTAR

### Opción 1: Automático (RECOMENDADO)

**Windows:**
```bash
# Doble-click en start_server.bat
```

**Mac/Linux:**
```bash
chmod +x start_server.sh
./start_server.sh
```

### Opción 2: Manual

**Terminal 1 - Inicia el servidor proxy:**
```bash
cd server
dart pub get
dart run bin/server.dart
```

Deberías ver:
```
Servidor proxy ejecutándose en: http://localhost:8080
CORS habilitado para todas las solicitudes
```

**Terminal 2 - Ejecuta la app:**
```bash
flutter run -d chrome
```

O si quieres usar web:
```bash
flutter run -d web-server
```

---

## ✅ Verificación

1. **Servidor corriendo:** Accede a http://localhost:8080/health
   - Si ves: `{"status":"ok"}` → ✅ Funciona

2. **App corriendo:** Ingresa un Steam ID válido
   - Si ves tus juegos → ✅ Funciona

---

## 🎮 Cómo Obtener tu Steam ID

1. Visita: https://steamcommunity.com/profiles
2. Mira la URL: `/profiles/[ESTO_ES_TU_ID]`
3. Copia el número de 17 dígitos (ej: `76561198123456789`)
4. Pegalo en la app

---

## 🐛 Si Algo No Funciona

### Error: "Servidor proxy no disponible"
```bash
# Asegúrate de ejecutar:
start_server.bat  # o start_server.sh
```

### Error: CORS origin
```bash
# Verifica que el servidor esté corriendo
http://localhost:8080/health
```

### Error: "Usuario no encontrado"
- Verifica el Steam ID (debe ser 17 dígitos)
- Asegúrate que tu biblioteca de Steam sea pública

---

## 📋 Resumen de Cambios

| Cambio | Detalle |
|--------|---------|
| ✅ Servidor Proxy | `server/bin/server.dart` |
| ✅ Auto-detect | Detecta web vs mobile |
| ✅ Error Handler | Muestra alerta si proxy no responde |
| ✅ Scripts | `start_server.bat` y `start_server.sh` |
| ✅ CORS Habilitado | Todas las solicitudes ahora funcionan |

---

## 🔗 Documentación Completa

- [README.md](README.md) - Guía general
- [STEAM_INTEGRATION.md](STEAM_INTEGRATION.md) - Detalles técnicos
- [server/README.md](server/README.md) - Documentación del servidor

---

**¡Listo!** Ahora tienes una app completa que funciona en web y mobile. 🎮✨
