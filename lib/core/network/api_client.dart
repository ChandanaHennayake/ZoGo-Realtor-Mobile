import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import 'api_exception.dart';
import 'connectivity_service.dart';

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

    try {
      final response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: body == null ? null : jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      final dynamic responseBody = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : null;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        ConnectivityService.instance.notifyOnline();
        if (responseBody is Map<String, dynamic>) {
          return responseBody;
        }
        return {};
      }

      throw ApiException(
        statusCode: response.statusCode,
        message: _extractErrorMessage(responseBody, response.statusCode),
      );
    } on SocketException catch (_) {
      ConnectivityService.instance.notifyOffline();
      throw const ApiException(
        statusCode: 0,
        message: 'No internet connection. Please check your network and try again.',
      );
    } on TimeoutException catch (_) {
      ConnectivityService.instance.notifyOffline();
      throw const ApiException(
        statusCode: 408,
        message: 'Connection timed out. Please check your internet connection.',
      );
    } on http.ClientException catch (e) {
      ConnectivityService.instance.notifyOffline();
      throw ApiException(
        statusCode: 0,
        message: 'Network error: ${e.message}. Please check your connection.',
      );
    }
  }

  String _extractErrorMessage(dynamic responseBody, int statusCode) {
    if (responseBody is Map<String, dynamic>) {
      if (responseBody['message'] != null &&
          responseBody['message'].toString().trim().isNotEmpty) {
        return responseBody['message'].toString().trim();
      }

      if (responseBody['error'] != null &&
          responseBody['error'].toString().trim().isNotEmpty) {
        return responseBody['error'].toString().trim();
      }

      // Check ASP.NET Validation errors dictionary
      if (responseBody['errors'] != null && responseBody['errors'] is Map) {
        final errors = responseBody['errors'] as Map;
        final errorList = <String>[];
        for (final val in errors.values) {
          if (val is List && val.isNotEmpty) {
            errorList.add(val.first.toString());
          } else if (val != null && val.toString().trim().isNotEmpty) {
            errorList.add(val.toString().trim());
          }
        }
        if (errorList.isNotEmpty) {
          return errorList.join('\n');
        }
      }

      if (responseBody['title'] != null &&
          responseBody['title'].toString().trim().isNotEmpty) {
        return responseBody['title'].toString().trim();
      }

      if (responseBody['detail'] != null &&
          responseBody['detail'].toString().trim().isNotEmpty) {
        return responseBody['detail'].toString().trim();
      }
    }

    switch (statusCode) {
      case 400:
        return 'Invalid request details. Please verify your input.';
      case 401:
        return 'Incorrect email or password. Please verify and try again.';
      case 403:
        return 'Access denied. You do not have permission.';
      case 404:
        return 'Resource not found. Please try again later.';
      case 500:
        return 'Server encountered an issue. Please try again later.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  void dispose() {
    _client.close();
  }
}
