/*
 * @author Oleg Khalidov <brooth@gmail.com>.
 * -----------------------------------------------
 * Freelance software development:
 * Upwork: https://www.upwork.com/fl/khalidovoleg
 * Freelancer: https://www.freelancer.com/u/brooth
 */

import 'package:acms/actions/auth.actions.dart';
import 'package:acms/models/async.models.dart';
import 'package:acms/models/auth.models.dart';

class AuthState {
  final AsyncState<bool> restoreSessionState;
  final AsyncState<Session> loginState;
  final AsyncState<Session> signupState;
  final AsyncState<bool> smsCodeState;
  final AsyncState<String> hideFromManualLocationListState;
  final AsyncState<bool> syncState;

  const AuthState(
    this.restoreSessionState,
    this.loginState,
    this.signupState,
    this.smsCodeState,
    this.hideFromManualLocationListState,
    this.syncState,
  );

  AuthState.initial()
      : this(
          AsyncState.create(),
          AsyncState.create(),
          AsyncState.create(),
          AsyncState.create(),
          AsyncState.create(),
          AsyncState.create(),
        );

  AuthState copyWith({
    AsyncState<bool> restoreSessionState,
    AsyncState<Session> loginState,
    AsyncState<Session> signupState,
    AsyncState<bool> smsCodeState,
    AsyncState<String> hideFromManualLocationListState,
    AsyncState<bool> syncState,
  }) =>
      AuthState(
        restoreSessionState ?? this.restoreSessionState,
        loginState ?? this.loginState,
        signupState ?? this.signupState,
        smsCodeState ?? this.smsCodeState,
        hideFromManualLocationListState ?? this.hideFromManualLocationListState,
        syncState ?? this.syncState,
      );
}

AuthState authReducer(final AuthState state, dynamic action) {
  if (action is RestoreSessionStateAction) {
    return state.copyWith(
      restoreSessionState: action.state,
    );
  }
  if (action is SendSmsCodeStateAction) {
    return state.copyWith(
      smsCodeState: action.state,
    );
  }
  if (action is LoginStateAction) {
    return state.copyWith(
      loginState: action.state,
    );
  }
  if (action is SignupStateAction) {
    return state.copyWith(
      loginState: action.state,
      signupState: action.state,
    );
  }
  if (action is HideFromManualLocationListStateAction) {
    return state.copyWith(
      hideFromManualLocationListState: action.state,
    );
  }
  if (action is ReadSyncSuccessStateAction) {
    return state.copyWith(
      syncState: action.state,
    );
  }
  return state;
}
