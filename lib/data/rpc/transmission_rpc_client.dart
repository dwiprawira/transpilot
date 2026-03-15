import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import '../../core/errors/app_exception.dart';
import '../../core/logging/app_logger.dart';
import '../../domain/entities/server_profile.dart';

class TransmissionRpcClient {
  TransmissionRpcClient(this.profile, {Dio? dio, AppLogger? logger})
    : _endpoint = profile.rpcUri,
      _logger = logger,
      _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: profile.rpcUri.toString(),
              contentType: Headers.jsonContentType,
              responseType: ResponseType.json,
              sendTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
              connectTimeout: const Duration(seconds: 10),
            ),
          ) {
    if (dio == null) {
      final adapter = IOHttpClientAdapter();
      adapter.createHttpClient = () {
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 10);
        if (profile.allowInvalidCertificate) {
          client.badCertificateCallback = (_, _, _) => true;
        }
        return client;
      };
      _dio.httpClientAdapter = adapter;
    }
  }

  final ServerProfile profile;
  final Uri _endpoint;
  final AppLogger? _logger;
  final Dio _dio;
  String? _sessionId;

  Future<Map<String, dynamic>> call(
    String method, {
    Map<String, dynamic>? arguments,
    Duration? sendTimeout,
    Duration? receiveTimeout,
    Duration? connectTimeout,
  }) async {
    _logger?.log(
      level: AppLogLevel.info,
      category: 'rpc',
      message: 'Sending Transmission RPC request',
      metadata: {
        'method': method,
        'server': '${profile.host}:${profile.port}',
        'path': profile.normalizedRpcPath,
        'https': profile.useHttps,
        'hasAuth': profile.username.isNotEmpty || profile.password.isNotEmpty,
      },
    );
    try {
      final response = await _execute(
        {'method': method, 'arguments': arguments ?? const <String, dynamic>{}},
        retryOnSessionConflict: true,
        sendTimeout: sendTimeout,
        receiveTimeout: receiveTimeout,
        connectTimeout: connectTimeout,
      );
      _logger?.log(
        level: AppLogLevel.info,
        category: 'rpc',
        message: 'Transmission RPC request succeeded',
        metadata: {
          'method': method,
          'server': '${profile.host}:${profile.port}',
        },
      );
      return response;
    } on AppException {
      rethrow;
    } on DioException catch (error) {
      final mapped = _mapDioException(error);
      _logError(method, mapped);
      throw mapped;
    } on FormatException catch (error) {
      final mapped = AppException(
        'The server returned an invalid response.',
        type: AppExceptionType.server,
        details: error,
      );
      _logError(method, mapped);
      throw mapped;
    } catch (error) {
      final mapped = AppException(
        'Unexpected Transmission RPC error.',
        details: error,
      );
      _logError(method, mapped);
      throw mapped;
    }
  }

  void _logError(String method, AppException error) {
    _logger?.log(
      level: AppLogLevel.error,
      category: 'rpc',
      message: error.message,
      metadata: {
        'method': method,
        'server': '${profile.host}:${profile.port}',
        'errorType': error.type.name,
      },
    );
  }

  Future<Map<String, dynamic>> _execute(
    Map<String, dynamic> payload, {
    required bool retryOnSessionConflict,
    Duration? sendTimeout,
    Duration? receiveTimeout,
    Duration? connectTimeout,
  }) async {
    final response = await _dio.postUri(
      _endpoint,
      data: jsonEncode(payload),
      options: Options(
        sendTimeout: sendTimeout,
        receiveTimeout: receiveTimeout,
        connectTimeout: connectTimeout,
        headers: {
          if (profile.username.isNotEmpty || profile.password.isNotEmpty)
            'Authorization':
                'Basic ${base64Encode(utf8.encode('${profile.username}:${profile.password}'))}',
          if (_sessionId != null) 'X-Transmission-Session-Id': _sessionId,
        },
        validateStatus: (status) =>
            status != null &&
            ((status >= 200 && status < 300) ||
                status == 401 ||
                status == 403 ||
                status == 404 ||
                status == 409),
      ),
    );

    if (response.statusCode == 409) {
      final sessionId = response.headers.value('X-Transmission-Session-Id');
      _logger?.log(
        level: AppLogLevel.warning,
        category: 'rpc',
        message: 'Transmission requested a new session id',
        metadata: {
          'server': '${profile.host}:${profile.port}',
          'receivedSessionId': sessionId != null && sessionId.isNotEmpty,
        },
      );
      if (!retryOnSessionConflict || sessionId == null || sessionId.isEmpty) {
        throw const AppException(
          'Transmission rejected the request because the session could not be refreshed.',
          type: AppExceptionType.server,
        );
      }
      _sessionId = sessionId;
      return _execute(
        payload,
        retryOnSessionConflict: false,
        sendTimeout: sendTimeout,
        receiveTimeout: receiveTimeout,
        connectTimeout: connectTimeout,
      );
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const AppException(
        'The server rejected the credentials.',
        type: AppExceptionType.invalidCredentials,
      );
    }

    if (response.statusCode == 404) {
      throw const AppException(
        'The RPC endpoint could not be found. Check the host, port, and RPC path.',
        type: AppExceptionType.malformedEndpoint,
      );
    }

    final data = response.data is String
        ? jsonDecode(response.data as String) as Map<String, dynamic>
        : Map<String, dynamic>.from(response.data as Map);
    final result = data['result'] as String? ?? '';
    if (result != 'success') {
      throw AppException(
        result.isEmpty ? 'Transmission returned an unknown error.' : result,
        type: result.toLowerCase().contains('duplicate')
            ? AppExceptionType.duplicateTorrent
            : AppExceptionType.server,
      );
    }
    return data;
  }

  AppException _mapDioException(DioException error) {
    final underlying = error.error;
    final underlyingText = '$underlying'.toLowerCase();

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return AppException(
        'The connection timed out.',
        type: AppExceptionType.timeout,
        details: error,
      );
    }

    if (underlying is HandshakeException ||
        underlyingText.contains('certificate')) {
      return AppException(
        'The TLS certificate could not be verified.',
        type: AppExceptionType.badCertificate,
        details: error,
      );
    }
    if (underlyingText.contains('cleartext')) {
      return AppException(
        'HTTP traffic was blocked by the platform. This build now enables cleartext HTTP, so rebuild and try again.',
        type: AppExceptionType.network,
        details: error,
      );
    }
    if (underlying is SocketException) {
      final localhostHint =
          profile.host == 'localhost' || profile.host == '127.0.0.1'
          ? ' If Transmission is running on your computer, use its LAN IP instead. On the Android emulator, use 10.0.2.2 instead of localhost.'
          : '';
      return AppException(
        'The server could not be reached.$localhostHint',
        type: AppExceptionType.unreachableHost,
        details: error,
      );
    }
    return AppException(
      'Network error while talking to Transmission.',
      type: AppExceptionType.network,
      details: error,
    );
  }
}
