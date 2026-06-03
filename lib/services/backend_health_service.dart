import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class BackendHealthService {
  BackendHealthService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  Future<void> check({Duration timeout = const Duration(seconds: 8)}) async {
    try {
      final response = await _client
          .get(Uri.parse('${ApiConfig.baseUrl}/health'))
          .timeout(timeout);
      if (response.statusCode == 404) {
        throw Exception('ENDPOINT_NOT_FOUND_404');
      }
      if (response.statusCode >= 500) {
        throw Exception('SERVER_UNAVAILABLE_${response.statusCode}');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Servidor no disponible (${response.statusCode})');
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['ok'] != true && body['status'] != 'ok') {
        throw Exception('Servidor no disponible');
      }
    } on TimeoutException {
      throw Exception('TIMEOUT');
    } on http.ClientException {
      throw Exception('NETWORK_ERROR');
    }
  }
}
