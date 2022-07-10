/*
 * @author Oleg Khalidov <brooth@gmail.com>.
 * -----------------------------------------------
 * Freelance software development:
 * Upwork: https://www.upwork.com/fl/khalidovoleg
 * Freelancer: https://www.freelancer.com/u/brooth
 */

import 'dart:async';
import 'dart:convert';

import 'package:acms/models/domain.models.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:acms/actions/actions.dart';
import 'package:acms/models/async.models.dart';
import 'package:acms/models/auth.models.dart';
import 'package:acms/store/app.store.dart';

class PersistSessionAction implements AsyncAction {
  final Session session;

  PersistSessionAction(this.session);

  @override
  ThunkAction<AppState> execute(api) => (store) async {
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('__session__', jsonEncode(session.toJson()));
      };
}

class ReadSyncSuccessStateAction {
  final AsyncState<bool> state;
  ReadSyncSuccessStateAction(this.state);
}

class ReadSyncSuccessAction {
  @override
  ThunkAction<AppState> execute(api) => (store) async {
        store.dispatch(ReadSyncSuccessStateAction(AsyncState.inProgress()));
        final prefs = await SharedPreferences.getInstance();
        final value = prefs.getBool('is_sync_success') ?? false;
        print("sync success $value");
        store.dispatch(ReadSyncSuccessStateAction(AsyncState.success(value)));
      };
}

class RestoreSessionStateAction {
  final AsyncState<bool> state;

  RestoreSessionStateAction(this.state);
}

class RestoreSessionAction implements AsyncAction {
  @override
  ThunkAction<AppState> execute(api) => (store) async {
        store.dispatch(RestoreSessionStateAction(AsyncState.inProgress()));

        await Future.delayed(Duration(seconds: 1));
        final prefs = await SharedPreferences.getInstance();
        final json = prefs.getString('__session__');
        if (json != null) {
          final session = Session.fromJson(
              jsonDecode(json), () => store.dispatch(LogoutAction()));
          store.dispatch(LoginStateAction(AsyncState.success(session)));
        }
        store.dispatch(
            RestoreSessionStateAction(AsyncState.success(json != null)));
      };
}

class SendSmsCodeStateAction {
  final AsyncState<bool> state;

  SendSmsCodeStateAction(this.state);
}

class SendSmsCodeAction implements AsyncAction {
  final String phoneNumber;

  SendSmsCodeAction(this.phoneNumber);

  @override
  ThunkAction<AppState> execute(api) => (store) {
        store.dispatch(SendSmsCodeStateAction(AsyncState.inProgress()));

        api.auth
            .sendVerificationCode(phoneNumber)
            .then((data) => store
                .dispatch(SendSmsCodeStateAction(AsyncState.success(data))))
            .catchError((error) => store
                .dispatch(SendSmsCodeStateAction(AsyncState.failed(error))));
      };
}

class LoginStateAction {
  final AsyncState<Session> state;

  LoginStateAction(this.state);
}

class LoginAction implements AsyncAction {
  final String phoneNumber;
  final String smsCode;

  LoginAction(this.phoneNumber, this.smsCode);

  @override
  ThunkAction<AppState> execute(api) => (store) async {
        try {
          store.dispatch(LoginStateAction(AsyncState.inProgress()));

          final data = await api.auth.login(
              phoneNumber, smsCode, () => store.dispatch(LogoutAction()));
          store.dispatch(LoginStateAction(AsyncState.success(data)));
          store.dispatch(PersistSessionAction(data));
        } catch (error) {
          store.dispatch(LoginStateAction(AsyncState.failed(error)));
        }
      };
}

class SignupStateAction {
  final AsyncState<Session> state;

  SignupStateAction(this.state);
}

class SignupAction implements AsyncAction {
  final String phoneNumber;
  final String smsCode;
  final String name;

  SignupAction(this.phoneNumber, this.smsCode, this.name);

  @override
  ThunkAction<AppState> execute(api) => (store) async {
        try {
          store.dispatch(SignupStateAction(AsyncState.inProgress()));

          final data = await api.auth.signup(
              name, phoneNumber, smsCode, () => store.dispatch(LogoutAction()));
          store.dispatch(SignupStateAction(AsyncState.success(data)));
          store.dispatch(PersistSessionAction(data));
        } catch (error) {
          store.dispatch(SignupStateAction(AsyncState.failed(error)));
        }
      };
}

class LogoutStateAction {
  final AsyncState state;

  LogoutStateAction(this.state);
}

class LogoutAction implements AsyncAction {
  @override
  ThunkAction<AppState> execute(api) => (store) async {
        print('LogoutAction.execute()');

        store.dispatch(LogoutStateAction(AsyncState.inProgress()));
        try {
          final prefs = await SharedPreferences.getInstance();
          prefs.remove('__session__');
          store.dispatch(LogoutStateAction(AsyncState.success()));
          store.dispatch(LoginStateAction(AsyncState.create()));
        } catch (error) {
          store.dispatch(LogoutStateAction(AsyncState.failed(error)));
        }
      };
}

class HideFromManualLocationListStateAction {
  final AsyncState<String> state;

  HideFromManualLocationListStateAction(this.state);
}

class HideFromManualLocationListAction implements AsyncAction {
  final ContactPhone phone;

  HideFromManualLocationListAction(this.phone);

  @override
  ThunkAction<AppState> execute(api) => (store) async {
        print('HideFromManualLocationListAction.execute()');

        final session = store.state.authState.loginState.value;
        if (session == null) return;
        try {
          session.user.prefs.hiddenManualLocationPhones.add(phone.id);
          store.dispatch(HideFromManualLocationListStateAction(
              AsyncState.inProgress(phone.id)));

          final value = session.user.prefs.hiddenManualLocationPhones.join(';');
          await api.auth.savePref(session, 'hiddenManualLocationPhones', value);
          store.dispatch(PersistSessionAction(session));
          store.dispatch(HideFromManualLocationListStateAction(
              AsyncState.success(phone.id)));
        } catch (error) {
          session.user.prefs.hiddenManualLocationPhones.remove(phone.id);
          store.dispatch(
              HideFromManualLocationListStateAction(AsyncState.failed(error)));
        }
      };
}

class RefreshUserPrefsStateAction {
  final AsyncState<UserPrefs> state;

  RefreshUserPrefsStateAction(this.state);
}

class RefreshUserPrefsAction implements AsyncAction {
  @override
  ThunkAction<AppState> execute(api) => (store) async {
        print('RefreshUserPrefsAction.execute()');
        final session = store.state.authState.loginState.value;
        if (session == null) return;

        store.dispatch(RefreshUserPrefsStateAction(AsyncState.inProgress()));
        try {
          final data = await api.auth.getPrefs(session);
          store.dispatch(RefreshUserPrefsStateAction(AsyncState.success(data)));
          final newSession =
              session.copyWith(user: session.user.copyWith(prefs: data));
          store.dispatch(PersistSessionAction(newSession));
          store.dispatch(LoginStateAction(AsyncState.success(newSession)));
        } catch (error) {
          store.dispatch(RefreshUserPrefsStateAction(AsyncState.failed(error)));
        }
      };
}
