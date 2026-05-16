#!/bin/bash

# 🚀 SCRIPT RÁPIDO - Preparar e Ejecutar Tip-Top-Games con Google Drive

echo "=========================================="
echo "🎮 Tip-Top-Games - Google Drive Setup"
echo "=========================================="
echo ""

# Paso 1: Navegar al directorio
echo "📁 Navegando al directorio del proyecto..."
cd /home/layo/Documentos/flutter/Tip-Top-Games

# Paso 2: Limpiar
echo "🧹 Limpiando proyecto..."
flutter clean

# Paso 3: Obtener dependencias
echo "📥 Descargando dependencias..."
flutter pub get

# Paso 4: Compilar y ejecutar
echo "🚀 Ejecutando aplicación..."
echo ""
echo "Opciones disponibles:"
echo "  flutter run              (ejecutar en dispositivo por defecto)"
echo "  flutter run -d chrome    (ejecutar en navegador Chrome)"
echo "  flutter run -d all       (ejecutar en todos los dispositivos)"
echo ""
echo "📝 Por defecto ejecutaremos en el dispositivo disponible..."
echo ""

flutter run

echo ""
echo "=========================================="
echo "✅ ¡Listo!"
echo "=========================================="
echo ""
echo "🎯 Próximos pasos:"
echo "1. Registra un nuevo usuario"
echo "2. Se crearán automáticamente las carpetas en Google Drive"
echo "3. En tu perfil, haz click en la cámara 📷"
echo "4. Selecciona una foto de tu galería o cámara"
echo "5. ¡Tu foto se subirá a Google Drive!"
echo ""
echo "Documentación:"
echo "  - GOOGLE_DRIVE_SUMMARY.md  (resumen rápido)"
echo "  - GOOGLE_DRIVE_CONFIG.md   (configuración)"
echo "  - GOOGLE_DRIVE_FLOW.md     (diagramas)"
echo ""
