/*
 * @author Oleg Khalidov <brooth@gmail.com>.
 * -----------------------------------------------
 * Freelance software development:
 * Upwork: https://www.upwork.com/fl/khalidovoleg
 * Freelancer: https://www.freelancer.com/u/brooth
 */

import 'dart:async';

import 'package:acms/api/api.dart';
import 'package:acms/models/auth.models.dart';

class AuthApi {
  final ApiClient client;

  AuthApi(this.client);

  Future<bool> sendVerificationCode(String phoneNumber) async {
    final params = {'phone': phoneNumber};
    await client.callApi('/auth/sendSmsCode', params: params);
    return true;
  }

  Future<Session> login(
      String phoneNumber, String smsCode, Function onSessionExpired) async {
    final params = {'phone': phoneNumber, 'code': smsCode};
    final json = await client.callApi('/auth', params: params);
    return Session.fromJson(json, onSessionExpired);
  }

  Future<Session> signup(String name, String phoneNumber, String smsCode,
      Function onSessionExpired) async {
    final body = {'name': name, 'phone': phoneNumber, 'code': smsCode};
    final json =
        await client.callApi('/auth', method: ApiMethod.POST, body: body);
    return Session.fromJson(json, onSessionExpired);
  }

  Future<void> savePref(Session session, String key, String value) async {
    final body = {'key': key, 'value': value};
    await this.client.callApi('/users/prefs',
        method: ApiMethod.PATCH, session: session, body: body);
  }

  Future<UserPrefs> getPrefs(Session session) async {
    final json = await this.client.callApi('/users/prefs', session: session);
    return UserPrefs.fromJson(json['result']);
  }
}
