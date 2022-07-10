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
import 'package:acms/store/app.store.dart';
import 'package:acms/views/screens/auth/login.form.dart';
import 'package:acms/views/screens/auth/signup.form.dart';
import 'package:acms/views/theme.dart';
import 'package:acms/views/views.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

class AuthScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _AuthScreenState();
}

enum _Mode { LOADING, LOGIN, SIGNUP }

class _AuthScreenState extends State<AuthScreen>
    with
        WidgetStateUtilsMixin<AuthScreen>,
        SingleTickerProviderStateMixin<AuthScreen> {
  AnimationController controller;
  Animation<double> opacity;

  _Mode mode = _Mode.LOADING;

  bool hasGotoNext = false;

  @override
  void initState() {
    super.initState();

    // fade-in/out animation
    controller =
        AnimationController(duration: Duration(milliseconds: 200), vsync: this);
    opacity = Tween(begin: .0, end: 1.0).animate(controller)
      ..addListener(() => setState(() {}));
    controller.forward();
  }

  changeModeWithAnimation(_Mode next) {
    controller.reverse().asStream().listen((_) {
      setState(() => mode = next);
      controller.forward();
    });
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Image.asset('assets/images/logo.png', width: 120.0),
    );
  }

  Widget _getModeScreen() {
    if (mode == _Mode.LOADING) return _buildLoadingScreen();
    if (mode == _Mode.LOGIN)
      return LoginForm(
        onSignup: () => changeModeWithAnimation(_Mode.SIGNUP),
      );
    if (mode == _Mode.SIGNUP)
      return SignupForm(
        onLogin: () => changeModeWithAnimation(_Mode.LOGIN),
      );
    return Container();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return StoreConnector<AppState, _ViewModel>(
      distinct: true,
      converter: (store) => _ViewModel(store),
      onInitialBuild: (model) {
        if (model.restoreSessionState.isUseless()) {
          model.restoreSession();
        }
        if (model.restoreSessionState.isSuccessful()) {
          setState(() => mode = _Mode.LOGIN);
        }
      },
      onDidChange: (model) {
        if (model.hasRestoreSessionSucceed()) {
          if (model.restoreSessionState.value) {
            if (hasGotoNext) {
              return;
            } else {
              hasGotoNext = true;
              Navigator.of(context).pushReplacementNamed('sync');
            }
          } else if (mode == _Mode.LOADING) {
            setState(() => mode = _Mode.LOGIN);
          }
          return;
        }
        if (model.hasLoginSucceed()) {
          if (hasGotoNext) {
            return;
          } else {
            hasGotoNext = true;
            Navigator.of(context).pushReplacementNamed('sync');
            model.resetSmsCodeState();
            return;
          }
        }
      },
      builder: (context, _) => Material(
        color: AppColors.darkBg,
        child: Opacity(
          opacity: opacity.value,
          child: _getModeScreen(),
        ),
      ),
    );
  }
}

class _ViewModel {
  final AppState _state;
  final Function _dispatch;

  _ViewModel(Store<AppState> store)
      : _state = store.state,
        _dispatch = store.dispatch;

  AsyncState<bool> get restoreSessionState =>
      _state.authState.restoreSessionState;
  AsyncState<Session> get loginState => _state.authState.loginState;

  AsyncState<bool> get syncState => _state.authState.syncState;

  bool hasRestoreSessionSucceed() {
    final prev = _state.prevState?.authState?.restoreSessionState;
    return prev != restoreSessionState && restoreSessionState.isSuccessful();
  }

  bool hasLoginSucceed() {
    final prev = _state.prevState?.authState?.loginState;
    return prev != loginState && loginState.isSuccessful();
  }

  bool hasSyncSucceed() {
    return syncState != null && syncState.isSuccessful() && syncState.value;
  }

  void readSyncFlag() => _dispatch(new ReadSyncSuccessAction());

  void restoreSession() => _dispatch(new RestoreSessionAction());

  void resetSmsCodeState() {
    _dispatch(new SendSmsCodeStateAction(AsyncState.create()));
  }

  operator ==(o) {
    return o is _ViewModel &&
        this.loginState == o.loginState &&
        this.syncState == o.syncState &&
        this.restoreSessionState == o.restoreSessionState;
  }

  @override
  int get hashCode => 0;
}
