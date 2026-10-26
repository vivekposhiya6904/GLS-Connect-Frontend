import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../utils/storage_service.dart';

/// Centralized HTTP client for GLS-Connect.
/// Provides:
/// - Automated Authorization header injection
/// - Cold-start resilient timeouts (default 15s)
/// - Safe retry policy for idempotent GET requests on 502/503/504 or network timeout
/// - 401 detection and single-flight token refresh
/// - Prevention of duplicate non-idempotent mutations (POST/PUT/DELETE)
class ApiClient {
  static const Duration defaultTimeout = Duration(seconds: 15);
  static const int maxGetRetries = 2;

  static bool _isRefreshing = false;

  /// Helper to get default headers with Authorization token
  static Future<Map<String, String>> _buildHeaders({Map<String, String>? extraHeaders}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final token = await StorageService.getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }
    return headers;
  }

  /// Perform a GET request with bounded retries on cold-start / server unavailable
  static Future<http.Response> get(
    Uri uri, {
    Map<String, String>? headers,
    Duration timeout = defaultTimeout,
    bool enableRetry = true,
  }) async {
    int attempts = 0;
    final int maxAttempts = enableRetry ? (1 + maxGetRetries) : 1;
    http.Response? lastResponse;
    Exception? lastException;

    while (attempts < maxAttempts) {
      attempts++;
      try {
        final requestHeaders = await _buildHeaders(extraHeaders: headers);
        final response = await http.get(uri, headers: requestHeaders).timeout(timeout);

        // Check if server is waking up / cold start (502, 503, 504)
        if (enableRetry && (response.statusCode == 502 || response.statusCode == 503 || response.statusCode == 504)) {
          lastResponse = response;
          if (attempts < maxAttempts) {
            await Future.delayed(Duration(seconds: attempts)); // Backoff: 1s, 2s
            continue;
          }
        }

        // Handle 401 Unauthorized
        if (response.statusCode == 401) {
          final refreshed = await _attemptTokenRefresh();
          if (refreshed) {
            final refreshedHeaders = await _buildHeaders(extraHeaders: headers);
            return await http.get(uri, headers: refreshedHeaders).timeout(timeout);
          }
        }

        return response;
      } on SocketException catch (e) {
        lastException = e;
        if (attempts < maxAttempts) {
          await Future.delayed(Duration(seconds: attempts));
          continue;
        }
      } on TimeoutException catch (e) {
        lastException = e;
        if (attempts < maxAttempts) {
          await Future.delayed(Duration(seconds: attempts));
          continue;
        }
      } catch (e) {
        lastException = Exception(e.toString());
        break; // Non-retryable error
      }
    }

    if (lastResponse != null) {
      return lastResponse;
    }
    throw lastException ?? Exception("Network request failed after $attempts attempts");
  }

  /// Perform a POST request (never automatically retried to prevent duplicate mutations)
  static Future<http.Response> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Duration timeout = defaultTimeout,
  }) async {
    final requestHeaders = await _buildHeaders(extraHeaders: headers);
    final response = await http.post(uri, headers: requestHeaders, body: body).timeout(timeout);

    if (response.statusCode == 401) {
      final refreshed = await _attemptTokenRefresh();
      if (refreshed) {
        final refreshedHeaders = await _buildHeaders(extraHeaders: headers);
        return await http.post(uri, headers: refreshedHeaders, body: body).timeout(timeout);
      }
    }

    return response;
  }

  /// Perform a PUT request
  static Future<http.Response> put(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Duration timeout = defaultTimeout,
  }) async {
    final requestHeaders = await _buildHeaders(extraHeaders: headers);
    final response = await http.put(uri, headers: requestHeaders, body: body).timeout(timeout);

    if (response.statusCode == 401) {
      final refreshed = await _attemptTokenRefresh();
      if (refreshed) {
        final refreshedHeaders = await _buildHeaders(extraHeaders: headers);
        return await http.put(uri, headers: refreshedHeaders, body: body).timeout(timeout);
      }
    }

    return response;
  }

  /// Perform a DELETE request
  static Future<http.Response> delete(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Duration timeout = defaultTimeout,
  }) async {
    final requestHeaders = await _buildHeaders(extraHeaders: headers);
    final response = await http.delete(uri, headers: requestHeaders, body: body).timeout(timeout);

    if (response.statusCode == 401) {
      final refreshed = await _attemptTokenRefresh();
      if (refreshed) {
        final refreshedHeaders = await _buildHeaders(extraHeaders: headers);
        return await http.delete(uri, headers: refreshedHeaders, body: body).timeout(timeout);
      }
    }

    return response;
  }

  /// Single-flight attempt to refresh the JWT token
  static Future<bool> _attemptTokenRefresh() async {
    if (_isRefreshing) return false;
    _isRefreshing = true;

    try {
      final oldToken = await StorageService.getToken();
      if (oldToken == null || oldToken.isEmpty) {
        _isRefreshing = false;
        return false;
      }

      final refreshUri = Uri.parse("${ApiConfig.baseUrl}/api/users/refresh-token");
      final response = await http.post(
        refreshUri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $oldToken',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['token'] != null) {
          await StorageService.saveToken(data['token'].toString());
          if (data['name'] != null) await StorageService.saveUserName(data['name'].toString());
          if (data['role'] != null) await StorageService.saveUserRole(data['role'].toString());
          _isRefreshing = false;
          return true;
        }
      }
    } catch (_) {
      // Network failure or token completely invalid
    } finally {
      _isRefreshing = false;
    }

    return false;
  }
}
