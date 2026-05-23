@echo off
echo.
echo ========================================
echo Iniciando Servidor Proxy Steam para Web
echo ========================================
echo.
echo Instalando dependencias del servidor...
cd server
call dart pub get
if errorlevel 1 (
    echo Error al obtener dependencias
    pause
    exit /b 1
)
cd ..

echo.
echo Ejecutando servidor en http://localhost:8765
echo (Puerto 8765: 8080 suele estar bloqueado por Hyper-V/WSL en Windows)
echo Presiona Ctrl+C para detener
echo.
dart run server/bin/server.dart

pause
