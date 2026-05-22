import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

const String _steamApiKey = 'FE5D7F671CA58B004133A244D7ACD29F';
const String _steamApiBase = 'https://api.steampowered.com';
const String _storeApiBase = 'https://store.steampowered.com/api';

/// Puerto por defecto. Evita 8080: en Windows suele estar en el rango
/// reservado por Hyper-V/WSL (p. ej. 7992-8091) y falla con errno 10013.
const int _defaultPort = 8765;

void main() async {
  final port = int.tryParse(
        Platform.environment['STEAM_PROXY_PORT'] ?? '',
      ) ??
      _defaultPort;

  final handler =
      logRequests().addMiddleware(_addCorsHeaders).addHandler(_handleRequest);

  HttpServer server;
  try {
    server = await io.serve(handler, InternetAddress.anyIPv4, port);
  } on SocketException catch (e) {
    if (e.osError?.errorCode == 10048) {
      print('⚠️ El puerto $port ya está en uso (otra instancia del proxy).');
      print('   No necesitas iniciarlo de nuevo.');
      print('   Prueba en el navegador: http://localhost:$port/health');
      print('   Para reiniciar, cierra el proceso dartvm que usa ese puerto.');
    } else if (e.osError?.errorCode == 10013) {
      print('⚠️ El puerto $port está bloqueado por Windows (Hyper-V/WSL).');
      print('   Usa otro puerto: set STEAM_PROXY_PORT=9000 && dart run ...');
    } else {
      print('⚠️ No se pudo abrir el puerto $port: $e');
    }
    exit(1);
  }

  print(
      '✅ Servidor proxy ejecutándose en: http://${server.address.host}:${server.port}');
  print(
      'ℹ️ Para celular real usa la IP de tu PC, ej: http://192.168.x.x:${server.port}');
  print('✅ CORS habilitado');
  print('📋 Endpoints:');
  print('   GET /health');
  print('   GET /library?steamid=76561198...');
  print('   GET /userinfo?steamid=76561198...');
  print('   GET /gamedetails?appid=620');
  print('   GET /achievements?steamid=76561198...&appid=620');
}

Middleware _addCorsHeaders = createMiddleware(
  responseHandler: (response) {
    return response.change(headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
      'Content-Type': 'application/json',
    });
  },
);

Future<Response> _handleRequest(Request request) async {
  // Manejar preflight
  if (request.method == 'OPTIONS') {
    return Response.ok('OK');
  }

  // Obtener el path de forma más confiable
  final path = request.requestedUri.path;
  final steamId = request.url.queryParameters['steamid'];
  final vanityUrl = request.url.queryParameters['vanityurl'];
  final appId = request.url.queryParameters['appid'];

  // Log para debugging
  print('📍 Request: ${request.method} $path');
  print('   Query params: steamid=$steamId, vanityurl=$vanityUrl');

  try {
    if (path == '/health' || path == 'health') {
      return Response.ok(jsonEncode({
        'status': 'ok',
        'version': 2,
        'features': ['gamedetails', 'achievements'],
      }));
    } else if (path == '/library' || path == 'library') {
      if (steamId == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'steamid required'}),
        );
      }
      return await _getLibrary(steamId);
    } else if (path == '/userinfo' || path == 'userinfo') {
      if (steamId == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'steamid required'}),
        );
      }
      return await _getUserInfo(steamId);
    } else if (path == '/vanityurl' || path == 'vanityurl') {
      if (vanityUrl == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'vanityurl required'}),
        );
      }
      return await _resolveVanityUrl(vanityUrl);
    } else if (path == '/gamedetails' || path == 'gamedetails') {
      if (appId == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'appid required'}),
        );
      }
      return await _getGameDetails(appId);
    } else if (path == '/achievements' || path == 'achievements') {
      if (steamId == null || appId == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'steamid and appid required'}),
        );
      }
      return await _getAchievements(steamId, appId);
    }

    print('   ❌ Route not found: $path');
    return Response.notFound(jsonEncode({'error': 'not found'}));
  } catch (e) {
    print('   ⚠️ Error: $e');
    return Response.internalServerError(
      body: jsonEncode({'error': 'Server error: $e'}),
    );
  }
}

Future<Response> _getLibrary(String steamId) async {
  try {
    final url = Uri.parse(
      '$_steamApiBase/IPlayerService/GetOwnedGames/v1/'
      '?steamid=$steamId'
      '&include_appinfo=true'
      '&include_played_free_games=true'
      '&key=$_steamApiKey',
    );

    final response = await http.get(url).timeout(
          const Duration(seconds: 10),
        );

    if (response.statusCode == 200) {
      return Response.ok(response.body);
    }
    return Response.internalServerError(
      body: jsonEncode({'error': 'Steam API error: ${response.statusCode}'}),
    );
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({'error': 'Error: $e'}),
    );
  }
}

Future<Response> _getUserInfo(String steamId) async {
  try {
    final url = Uri.parse(
      '$_steamApiBase/ISteamUser/GetPlayerSummaries/v2/'
      '?steamids=$steamId'
      '&key=$_steamApiKey',
    );

    final response = await http.get(url).timeout(
          const Duration(seconds: 10),
        );

    if (response.statusCode == 200) {
      return Response.ok(response.body);
    }
    return Response.internalServerError(
      body: jsonEncode({'error': 'Steam API error: ${response.statusCode}'}),
    );
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({'error': 'Error: $e'}),
    );
  }
}

Future<Response> _getGameDetails(String appId) async {
  try {
    final url = Uri.parse(
      '$_storeApiBase/appdetails?appids=$appId&l=spanish',
    );
    final response = await http.get(url).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Store API error: ${response.statusCode}'}),
      );
    }

    final root = jsonDecode(response.body) as Map<String, dynamic>;
    final app = root[appId] as Map<String, dynamic>?;
    if (app == null || app['success'] != true) {
      return Response.ok(jsonEncode({'description': null, 'storageRequirement': null}));
    }

    final data = app['data'] as Map<String, dynamic>?;
    if (data == null) {
      return Response.ok(jsonEncode({'description': null, 'storageRequirement': null}));
    }

    final short = data['short_description'] as String? ?? '';
    final about = data['about_the_game'] as String? ?? '';
    var description = short.trim();
    if (description.isEmpty) {
      description = _stripHtml(about);
    }

    final pcReq = data['pc_requirements'] as Map<String, dynamic>?;
    var storage = _parseStorage(pcReq?['minimum'] as String?) ??
        _parseStorage(pcReq?['recommended'] as String?);

    if (storage == null) {
      for (final lang in ['english', 'latam']) {
        try {
          final alt = await http.get(
            Uri.parse('$_storeApiBase/appdetails?appids=$appId&l=$lang'),
          );
          if (alt.statusCode != 200) continue;
          final altData = (jsonDecode(alt.body) as Map)[appId]?['data']
              as Map<String, dynamic>?;
          final altPc = altData?['pc_requirements'] as Map<String, dynamic>?;
          storage = _parseStorage(altPc?['minimum'] as String?) ??
              _parseStorage(altPc?['recommended'] as String?);
          if (storage != null) break;
        } catch (_) {}
      }
    }

    return Response.ok(jsonEncode({
      'description': description.isEmpty ? null : description,
      'storageRequirement': storage,
      'achievements': data['achievements'],
    }));
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({'error': 'Error: $e'}),
    );
  }
}

Future<Response> _getAchievements(String steamId, String appId) async {
  try {
    final schemaUrl = Uri.parse(
      '$_steamApiBase/ISteamUserStats/GetSchemaForGame/v2/'
      '?key=$_steamApiKey&appid=$appId&l=spanish',
    );
    final playerUrl = Uri.parse(
      '$_steamApiBase/ISteamUserStats/GetPlayerAchievements/v1/'
      '?key=$_steamApiKey&steamid=$steamId&appid=$appId&l=spanish',
    );

    final responses = await Future.wait([
      http.get(schemaUrl).timeout(const Duration(seconds: 15)),
      http.get(playerUrl).timeout(const Duration(seconds: 15)),
    ]);

    final schemaBody = responses[0].statusCode == 200
        ? jsonDecode(responses[0].body) as Map<String, dynamic>
        : <String, dynamic>{};
    final playerBody = responses[1].statusCode == 200
        ? jsonDecode(responses[1].body) as Map<String, dynamic>
        : <String, dynamic>{};

    final schemaList =
        (schemaBody['game']?['availableGameStats']?['achievements'] as List? ??
                [])
            .cast<Map<String, dynamic>>();

    if (schemaList.isEmpty) {
      return Response.ok(jsonEncode({
        'achievements': <Map<String, dynamic>>[],
        'unlockedCount': 0,
        'totalCount': 0,
        'note': 'Este juego no tiene logros en Steam',
      }));
    }

    final unlockedByApi = <String, bool>{};
    String? note;
    final stats = playerBody['playerstats'] as Map<String, dynamic>?;
    if (stats != null && stats['success'] == true) {
      for (final a
          in (stats['achievements'] as List? ?? []).cast<Map<String, dynamic>>()) {
        final api = a['apiname'] as String? ?? '';
        unlockedByApi[api] = (a['achieved'] as int? ?? 0) == 1;
      }
    } else if (stats != null && stats['success'] != true) {
      final error = stats['error'] as String? ?? '';
      if (error.toLowerCase().contains('not public')) {
        note =
            'Activa en público: Perfil y Detalles de los juegos (Steam → Privacidad).';
      } else if (error.isNotEmpty) {
        note = error;
      }
    }

    final achievements = schemaList.map((a) {
      final apiName = a['name'] as String? ?? '';
      return {
        'apiName': apiName,
        'displayName': a['displayName'] ?? '',
        'description': a['description'] ?? '',
        'hidden': (a['hidden'] as int? ?? 0) == 1,
        'unlocked': unlockedByApi[apiName] ?? false,
      };
    }).toList();

    final unlockedCount =
        achievements.where((a) => a['unlocked'] == true).length;

    return Response.ok(jsonEncode({
      'achievements': achievements,
      'unlockedCount': unlockedCount,
      'totalCount': achievements.length,
      'note': note,
    }));
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({'error': 'Error: $e'}),
    );
  }
}

String _stripHtml(String html) {
  return html
      .replaceAll(RegExp(r'<[^>]*>', multiLine: true), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String? _parseStorage(String? html) {
  if (html == null || html.isEmpty) return null;
  final plain = _stripHtml(html);
  final match = RegExp(
    r'(?:Almacenamiento|Storage)\s*:\s*(.+?)(?:\s{2,}|$)',
    caseSensitive: false,
  ).firstMatch(plain);
  return match?.group(1)?.trim();
}

Future<Response> _resolveVanityUrl(String vanityUrl) async {
  try {
    final url = Uri.parse(
      '$_steamApiBase/ISteamUser/ResolveVanityURL/v1/'
      '?vanityurl=$vanityUrl'
      '&key=$_steamApiKey',
    );

    final response = await http.get(url).timeout(
          const Duration(seconds: 10),
        );

    if (response.statusCode == 200) {
      return Response.ok(response.body);
    }
    return Response.internalServerError(
      body: jsonEncode({'error': 'Steam API error: ${response.statusCode}'}),
    );
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({'error': 'Error: $e'}),
    );
  }
}
