import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import 'api_exception.dart';

class ApiClient {
  final http.Client _client;

  ApiClient({
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}$endpoint',
    );

    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: body == null ? null : jsonEncode(body),
    );

    final dynamic responseBody = response.body.isNotEmpty
        ? jsonDecode(response.body)
        : null;

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      if (responseBody is Map<String, dynamic>) {
        return responseBody;
      }

      return {};
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: _extractErrorMessage(responseBody),
    );
  }

  String _extractErrorMessage(dynamic responseBody) {
    if (responseBody is Map<String, dynamic>) {
      if (responseBody['message'] != null) {
        return responseBody['message'].toString();
      }

      if (responseBody['title'] != null) {
        return responseBody['title'].toString();
      }

      if (responseBody['detail'] != null) {
        return responseBody['detail'].toString();
      }
    }

    return 'Something went wrong. Please try again.';
  }

  void dispose() {
    _client.close();
  }
}