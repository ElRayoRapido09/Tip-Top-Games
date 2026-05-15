import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

const String _steamApiKey = 'FE5D7F671CA58B004133A244D7ACD29F';
const String _steamApiBase = 'https://api.steampowered.com';

void main() async {
  final handler =
      logRequests().addMiddleware(_addCorsHeaders).addHandler(_handleRequest);

  final server = await io.serve(handler, InternetAddress.anyIPv4, 8080);

  print(
      '✅ Servidor proxy ejecutándose en: http://${server.address.host}:${server.port}');
  print(
      'ℹ️ Para celular real usa la IP de tu PC, ej: http://192.168.x.x:${server.port}');
  print('✅ CORS habilitado');
  print('📋 Endpoints:');
  print('   GET /health');
  print('   GET /library?steamid=76561198...');
  print('   GET /userinfo?steamid=76561198...');
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

  // Log para debugging
  print('📍 Request: ${request.method} $path');
  print('   Query params: steamid=$steamId, vanityurl=$vanityUrl');

  try {
    if (path == '/health' || path == 'health') {
      return Response.ok(jsonEncode({'status': 'ok'}));
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
