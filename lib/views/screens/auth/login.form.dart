/*
 * @author Oleg Khalidov <brooth@gmail.com>.
 * -----------------------------------------------
 * Freelance software development:
 * Upwork: https://www.upwork.com/fl/khalidovoleg
 * Freelancer: https://www.freelancer.com/u/brooth
 */
import 'package:acms/i18n/i18n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

import 'package:acms/actions/auth.actions.dart';
import 'package:acms/models/auth.models.dart';
import 'package:acms/store/app.store.dart';
import 'package:acms/views/views.dart';
import 'package:acms/c.dart';
import 'package:acms/utils/validators.dart';
import 'package:acms/models/async.models.dart';
import 'package:acms/views/components/alerts.dart';
import 'package:acms/views/theme.dart';
import 'package:acms/views/components/forms.dart';

class LoginForm extends StatefulWidget {
  final Function onSignup;

  const LoginForm({this.onSignup});

  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm>
    with WidgetStateUtilsMixin<LoginForm> {
  final phoneInputController =
      TextInputController(validatePhone, I18N.phoneRequired);
  final codeInputController = TextInputController(null, I18N.codeRequired);

  AlertData notification;

  _LoginFormState() {
    if (DEV_MODE) {
      phoneInputController.editingController.text = '77784398709';
    }
  }

  void _login(_ViewModel model) {
    final error = phoneInputController.validate(context) ??
        codeInputController.validate(context);
    if (error != null)
      return setState(() => notification = AlertData.error(error));

    hideKeyboard();
    model.login('+' + phoneInputController.text, codeInputController.text);
  }

  void _sendSmsCode(_ViewModel model) {
    final error = phoneInputController.validate(context);
    if (error != null)
      return setState(() => notification = AlertData.error(error));

    model.sendSmsCode('+' + phoneInputController.text);
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, _ViewModel>(
      distinct: true,
      converter: (store) => _ViewModel(store),
      builder: (context, model) => Stack(children: <Widget>[
            AuthForm(children: [
              Padding(
                padding: EdgeInsets.only(bottom: 20.0),
                child: Icon(
                  Icons.person,
                  size: 60.0,
                  color: Colors.white,
                ),
              ),
              Padding(
                padding: AppDimensions.authFormTopFieldPadding,
                child: AuthFormTextInput(
                  I18N.phoneCaption,
                  inputType: TextInputType.phone,
                  maxLength: 20,
                  prefixText: '+',
                  readonly: model.loginState.isInProgress() ||
                      model.smsCodeState.isInProgress(),
                  controller: phoneInputController,
                  onChanged: (_) {
                    if (model.smsCodeState.isSuccessful()) {
                      model.resetSmsCodeState();
                      setState(() => codeInputController.text = null);
                    }
                    if (phoneInputController.error != null) {
                      setState(() => phoneInputController.error = null);
                    }
                  },
                ),
              ),
              model.smsCodeState.isSuccessful()
                  ? Padding(
                      padding: AppDimensions.authFormMiddleFieldPadding,
                      child: AuthFormTextInput(
                        I18N.codeCaption,
                        inputType: TextInputType.phone,
                        maxLength: 4,
                        readonly: model.loginState.isInProgress(),
                        controller: codeInputController,
                        onChanged: (_) => codeInputController.error != null
                            ? setState(() {
                                codeInputController.error = null;
                              })
                            : null,
                      ),
                    )
                  : SizedBox(),
              Padding(
                padding: AppDimensions.authFormMiddleButtonPadding,
                child: model.smsCodeState.isSuccessful()
                    ? AuthFormButton(
                        I18N.loginCaption,
                        () => _login(model),
                        disabled: model.loginState.isInProgress(),
                        progress: model.loginState.isInProgress(),
                      )
                    : AuthFormButton(
                        I18N.sendSmsCodeCaption,
                        () => _sendSmsCode(model),
                        disabled: model.smsCodeState.isInProgress(),
                        progress: model.smsCodeState.isInProgress(),
                      ),
              ),
            ]),
            // Align(
            //   alignment: Alignment.bottomCenter,
            //   child: Padding(
            //     padding: EdgeInsets.only(bottom: 28.0),
            //     child: AuthFormHyperlink(
            //       [
            //         TextSpan(text: I18N.dontHaveAccout),
            //         TextSpan(text: ' '),
            //         TextSpan(
            //             text: I18N.signUpCaption,
            //             style: TextStyle(fontWeight: FontWeight.bold))
            //       ],
            //       Colors.white,
            //       widget.onSignup,
            //     ),
            //   ),
            // ),
            buildNotification(notification, top: 50.0),
          ]),
      onDidChange: (model) {
        if (model.hasSmsCodeBeenSent()) {
          setState(() {
            notification = AlertData.success(I18N.smsCodeSend);
          });
        }
        if (model.hasSmsCodeFailed()) {
          setState(() {
            notification = AlertData.fromAsyncError(model.smsCodeState.error);
          });
        }
        if (model.hasLoginFailed()) {
          setState(() {
            notification = AlertData.fromAsyncError(model.loginState.error);
          });
        }
      },
    );
  }
}

class _ViewModel {
  final AppState _state;
  final Function _dispatch;

  _ViewModel(Store<AppState> store)
      : _state = store.state,
        _dispatch = store.dispatch;

  AsyncState<Session> get loginState => _state.authState.loginState;

  AsyncState get smsCodeState => _state.authState.smsCodeState;

  bool hasSmsCodeBeenSent() {
    final prev = _state.prevState?.authState?.smsCodeState;
    return prev != smsCodeState && smsCodeState.isSuccessful();
  }

  bool hasSmsCodeFailed() {
    final prev = _state.prevState?.authState?.smsCodeState;
    return prev != smsCodeState && smsCodeState.isFailed();
  }

  bool hasLoginFailed() {
    final prev = _state.prevState?.authState?.loginState;
    return prev != loginState && loginState.isFailed();
  }

  void login(String phone, String code) => _dispatch(LoginAction(phone, code));

  void sendSmsCode(String phone) => _dispatch(SendSmsCodeAction(phone));

  void resetSmsCodeState() =>
      _dispatch(SendSmsCodeStateAction(AsyncState.create()));

  operator ==(o) {
    return o is _ViewModel &&
        loginState == o.loginState &&
        smsCodeState == o.smsCodeState;
  }

  @override
  int get hashCode => 0;
}
