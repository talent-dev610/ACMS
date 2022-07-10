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
import 'package:acms/utils/validators.dart';
import 'package:acms/models/async.models.dart';
import 'package:acms/views/components/alerts.dart';
import 'package:acms/views/theme.dart';
import 'package:acms/views/components/forms.dart';

class SignupForm extends StatefulWidget {
  final Function onLogin;

  const SignupForm({this.onLogin});

  @override
  _SignupFormState createState() => _SignupFormState();
}

class _SignupFormState extends State<SignupForm>
    with WidgetStateUtilsMixin<SignupForm> {
  final phoneInputController =
      TextInputController(validatePhone, I18N.phoneRequired);
  final codeInputController = TextInputController(null, I18N.codeRequired);
  final nameInputController =
      TextInputController(validateName, I18N.nameRequired);

  AlertData notification;

  void _signup(_ViewModel model) {
    final error = phoneInputController.validate(context) ??
        codeInputController.validate(context) ??
        nameInputController.validate(context);
    if (error != null)
      return setState(() => notification = AlertData.error(error));

    hideKeyboard();
    model.signup('+' + phoneInputController.text, codeInputController.text,
        nameInputController.text);
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
      converter: (store) => _ViewModel(store),
      builder: (context, model) => Stack(children: <Widget>[
            AuthForm(children: [
              Padding(
                padding: EdgeInsets.only(right: 20.0, bottom: 20.0),
                child: Icon(
                  Icons.person_add,
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
                  readonly: model.signupState.isInProgress() ||
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
                        readonly: model.signupState.isInProgress(),
                        controller: codeInputController,
                        onChanged: (_) => codeInputController.error != null
                            ? setState(() {
                                codeInputController.error = null;
                              })
                            : null,
                      ),
                    )
                  : SizedBox(),
              model.smsCodeState.isSuccessful()
                  ? Padding(
                      padding: AppDimensions.authFormMiddleFieldPadding,
                      child: AuthFormTextInput(
                        I18N.nameCaption,
                        inputType: TextInputType.text,
                        maxLength: 100,
                        readonly: model.signupState.isInProgress(),
                        controller: nameInputController,
                        onChanged: (_) => nameInputController.error != null
                            ? setState(() {
                                nameInputController.error = null;
                              })
                            : null,
                      ),
                    )
                  : SizedBox(),
              Padding(
                padding: AppDimensions.authFormMiddleButtonPadding,
                child: model.smsCodeState.isSuccessful()
                    ? AuthFormButton(
                        I18N.signUpCaption,
                        () => _signup(model),
                        disabled: model.signupState.isInProgress(),
                        progress: model.signupState.isInProgress(),
                      )
                    : AuthFormButton(
                        I18N.sendSmsCodeCaption,
                        () => _sendSmsCode(model),
                        disabled: model.smsCodeState.isInProgress(),
                        progress: model.smsCodeState.isInProgress(),
                      ),
              ),
            ]),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: 28.0),
                child: AuthFormHyperlink(
                  [
                    TextSpan(text: I18N.alreadyHaveAccout),
                    TextSpan(text: ' '),
                    TextSpan(
                        text: I18N.loginCaption,
                        style: TextStyle(fontWeight: FontWeight.bold))
                  ],
                  Colors.white,
                  widget.onLogin,
                ),
              ),
            ),
            buildNotification(notification, top: 50.0),
          ]),
      onWillChange: (model) {
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
        if (model.hasSignupFailed()) {
          setState(() {
            notification = AlertData.fromAsyncError(model.signupState.error);
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

  AsyncState<Session> get signupState => _state.authState.signupState;

  AsyncState get smsCodeState => _state.authState.smsCodeState;

  bool hasSmsCodeBeenSent() {
    final prevSmsCodeState = _state.prevState?.authState?.smsCodeState;
    return prevSmsCodeState != null &&
        prevSmsCodeState.isInProgress() &&
        smsCodeState.isSuccessful();
  }

  bool hasSmsCodeFailed() {
    final prevSmsCodeState = _state.prevState?.authState?.smsCodeState;
    return prevSmsCodeState != null &&
        prevSmsCodeState.isInProgress() &&
        smsCodeState.isFailed();
  }

  bool hasSignupFailed() {
    final prevState = _state.prevState?.authState?.signupState;
    return prevState != null &&
        prevState.isInProgress() &&
        signupState.isFailed();
  }

  void signup(String phone, String code, String name) =>
      _dispatch(new SignupAction(phone, code, name));

  void sendSmsCode(String phone) => _dispatch(new SendSmsCodeAction(phone));

  void resetSmsCodeState() {
    _dispatch(new SendSmsCodeStateAction(AsyncState.create()));
  }

  operator ==(o) {
    return o is _ViewModel &&
        signupState == o.signupState &&
        smsCodeState == o.smsCodeState;
  }

  @override
  int get hashCode => 0;
}
