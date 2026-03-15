import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transpilot/core/errors/app_exception.dart';
import 'package:transpilot/data/rpc/transmission_rpc_client.dart';
import 'package:transpilot/domain/entities/server_profile.dart';

void main() {
  group('TransmissionRpcClient', () {
    test(
      'retries after a 409 session conflict and reuses the session id',
      () async {
        final requests = <RequestOptions>[];
        final dio = Dio()
          ..httpClientAdapter = _FakeAdapter((options) async {
            requests.add(options);
            if (requests.length == 1) {
              return ResponseBody.fromString(
                '',
                409,
                headers: {
                  'X-Transmission-Session-Id': ['session-123'],
                },
              );
            }

            expect(options.headers['X-Transmission-Session-Id'], 'session-123');
            expect(options.headers['Authorization'], startsWith('Basic '));
            return ResponseBody.fromString(
              jsonEncode({
                'result': 'success',
                'arguments': {'version': '4.0.0'},
              }),
              200,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType],
              },
            );
          });

        final client = TransmissionRpcClient(
          const ServerProfile(
            id: '1',
            name: 'Local',
            host: 'example.com',
            port: 9091,
            rpcPath: '/transmission/rpc',
            useHttps: false,
            allowInvalidCertificate: false,
            username: 'demo',
            password: 'secret',
          ),
          dio: dio,
        );

        final response = await client.call('session-get');

        expect(requests, hasLength(2));
        expect(response['result'], 'success');
      },
    );

    test('maps 401 responses to invalid credentials', () async {
      final requests = <RequestOptions>[];
      final dio = Dio()
        ..httpClientAdapter = _FakeAdapter((options) async {
          requests.add(options);
          return ResponseBody.fromString('', 401);
        });

      final client = TransmissionRpcClient(
        const ServerProfile(
          id: '1',
          name: 'Remote',
          host: 'example.com',
          port: 9091,
          rpcPath: '/transmission/rpc',
          useHttps: false,
          allowInvalidCertificate: false,
          username: 'user',
          password: 'bad-password',
        ),
        dio: dio,
      );

      await expectLater(
        client.call('session-get'),
        throwsA(
          isA<AppException>().having(
            (error) => error.type,
            'type',
            AppExceptionType.invalidCredentials,
          ),
        ),
      );
      expect(requests.single.headers['Authorization'], startsWith('Basic '));
    });
  });
}

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this._handler);

  final Future<ResponseBody> Function(RequestOptions options) _handler;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return _handler(options);
  }
}
