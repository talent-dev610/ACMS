/*
 * @author Oleg Khalidov <brooth@gmail.com>.
 * -----------------------------------------------
 * Freelance software development:
 * Upwork: https://www.upwork.com/fl/khalidovoleg
 * Freelancer: https://www.freelancer.com/u/brooth
 */

import 'dart:async' as Async;
import 'dart:convert';
import 'dart:io';

import 'package:acms/api/domain.api.dart';
import 'package:acms/c.dart';
import 'package:acms/models/async.models.dart';
import 'package:acms/models/auth.models.dart';
import 'package:http/http.dart' as http;
import 'package:acms/api/auth.api.dart';

class Api {
  final AuthApi auth;
  final DomainApi domain;

  Api(this.auth, this.domain);

  factory Api.create() {
    final apiClient = new ApiClient();
    return Api(AuthApi(apiClient), DomainApi(apiClient));
  }
}

enum ApiMethod { GET, POST, PATCH, DELETE }

class ApiClient {
  final _client = http.Client();

  Async.Future<Map<String, dynamic>> callApi(
    String path, {
    String host,
    ApiMethod method = ApiMethod.GET,
    Map<String, dynamic> body,
    Map<String, String> params,
    Session session,
  }) async {
    try {
      final uri = Uri.http(
          '${host ?? BACKEND_HOST}:$BACKEND_PORT', '/api' + path, params);
      final headers = new Map<String, String>();
      headers['x-client-id'] = CLIENT_ID;
      if (method != ApiMethod.GET) headers['Content-Type'] = 'application/json';
      if (session != null) headers['x-access-token'] = session.token;
      final bodyJson = body != null ? jsonEncode(body) : null;

      final future = method == ApiMethod.GET
          ? _client.get(uri, headers: headers)
          : method == ApiMethod.POST
              ? _client.post(uri, headers: headers, body: bodyJson)
              : method == ApiMethod.PATCH
                  ? _client.patch(uri, headers: headers, body: bodyJson)
                  : _client.delete(uri, headers: headers);

      final response = await future;
      await Async.Future.delayed(Duration(milliseconds: 200));

      if (response.statusCode == 401) {
        if (session != null) session.expired();
        throw AsyncError(
            AsyncErrorType.SESSION_EXPIRED, AsyncErrorSeverity.WARNING);
      }
      if (response.statusCode == 400) {
        throw _parseApiError(response);
      }
      if (response.statusCode != 200 && response.statusCode != 201)
        throw AsyncError.serverError();
      return jsonDecode(response.body);
    } catch (err) {
      if (err is IOException || err is http.ClientException)
        throw AsyncError.networkProblems();
      throw err;
    }
  }

  AsyncError _parseApiError(http.Response response) {
    final error = jsonDecode(response.body);
    final type = AsyncErrorType.values.firstWhere(
        (t) => t.toString() == 'AsyncErrorType.${error["code"]}',
        orElse: () => AsyncErrorType.SERVER_ERROR);
    return AsyncError(type, AsyncErrorSeverity.WARNING, error['message']);
  }
}
