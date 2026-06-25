import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'consts.dart';
import '../services/auth/auth_session.dart';
import '../services/storage/token_storage.dart';

class DioClient {
  static Dio create() {
    debugPrint('=== DioClient.create() ===');
    debugPrint('BASE_URL from consts: $kBaseUrl');
    final dio = Dio(
      BaseOptions(
        baseUrl: kBaseUrl,
        // Render free instances can take time to wake up on first request.
        connectTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          debugPrint('=== API REQUEST ===');
          debugPrint('Method: ${options.method}');
          debugPrint('URL: ${options.uri}');
          final token = await TokenStorage.read();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // For multipart, ensure we don't force application/json
          // (Dio + Retrofit will set the proper multipart/form-data with boundary)
          if (options.data is FormData ||
              (options.contentType?.contains('multipart') ?? false)) {
            options.headers.remove('Content-Type');
          }

          handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('=== API RESPONSE ===');
          debugPrint('Status: ${response.statusCode}');
          debugPrint('Data: ${response.data}');
          handler.next(response);
        },
        onError: (error, handler) async {
          debugPrint('=== API ERROR ===');
          debugPrint('Error: $error');
          if (error.response != null) {
            debugPrint('Response data: ${error.response!.data}');
            debugPrint('Response headers: ${error.response!.headers}');
          }
          if (_shouldRetry(error)) {
            try {
              await Future<void>.delayed(const Duration(seconds: 2));
              final retryResponse =
                  await dio.fetch<dynamic>(error.requestOptions);
              handler.resolve(retryResponse);
              return;
            } catch (_) {
              // Continue to default error handling below.
            }
          }

          final statusCode = error.response?.statusCode;
          if (statusCode == 401) {
            await TokenStorage.clear();
            AuthSession.notifyUnauthorized();
          }
          handler.next(error);
        },
      ),
    );

    return dio;
  }

  static bool _shouldRetry(DioException error) {
    if (error.requestOptions.extra['retried'] == true) return false;

    final isTransient = error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError;

    if (!isTransient) return false;

    error.requestOptions.extra['retried'] = true;
    return true;
  }
}
