#!/bin/bash

echo ""
echo "========================================"
echo "Iniciando Servidor Proxy Steam para Web"
echo "========================================"
echo ""
echo "Instalando dependencias del servidor..."

cd server
dart pub get

if [ $? -ne 0 ]; then
    echo "Error al obtener dependencias"
    exit 1
fi

cd ..

echo ""
echo "Ejecutando servidor en http://localhost:8765"
echo "Presiona Ctrl+C para detener"
echo ""

dart run server/bin/server.dart
