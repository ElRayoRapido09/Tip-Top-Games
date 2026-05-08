# Configuración de Gemini API para Recomendaciones

## ¿Qué se necesita?

La aplicación ahora usa **Google Gemini API** para generar recomendaciones personalizadas de juegos basadas en:
- Tu tiempo disponible
- Tus géneros preferidos
- Los juegos en tu biblioteca Steam

## Pasos para configurar:

### 1. Obtener la API Key de Google Gemini

1. Ve a [Google AI Studio](https://aistudio.google.com/apikey)
2. Haz clic en "Create API key"
3. Copia la clave generada (ejemplo: `AIzaSyD...`)

### 2. Configurar la clave en la app

Abre el archivo `lib/services/gemini_service.dart` y reemplaza:

```dart
static const String _apiKey = 'YOUR_GEMINI_API_KEY_HERE';
```

Con tu clave real:

```dart
static const String _apiKey = 'AIzaSyD...'; // Tu clave aquí
```

### 3. ¿Qué sucede después?

- Cuando hagas clic en "🎮 Ver sugerencias"
- La app enviará una lista de tus juegos a Gemini
- Gemini analizará tu tiempo disponible y preferencias
- Te mostrará los **3-5 mejores juegos** que puedas disfrutar

## ⚠️ Importante

- **No compartas tu API key** públicamente
- Google da acceso gratuito a Gemini API (con límites)
- Cada consulta consume tokens de tu cuota

## Alternativas

Si prefieres no usar API keys:
1. Puedes usar una versión simplificada sin IA
2. O implementar recomendaciones basadas en estadísticas locales

¿Preguntas? Revisa la documentación de [Google AI](https://ai.google.dev/)
