/*
 * Developed in 2018 by Oleg Khalidov (brooth@gmail.com).
 *
 * Freelance Mobile Development:
 * UpWork: https://www.upwork.com/fl/khalidovoleg
 * Freelancer: https://www.freelancer.com/u/brooth
 */

import 'package:acms/views/components/base.dart';
import 'package:acms/views/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AuthForm extends StatelessWidget {
  final List<Widget> children;
  final double keyboardSpaceRatio;

  AuthForm({this.children, this.keyboardSpaceRatio = .5});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            constraints: BoxConstraints(maxWidth: 300.0),
            margin: AppDimensions.authFormPadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: children,
            ),
          ),
          KeyboardSpace(heightRatio: keyboardSpaceRatio),
        ],
      ),
    );
  }
}

typedef String Validator(String val);

class TextInputController {
  String error;
  String success;

  final FocusNode focusNode = FocusNode();
  final editingController = TextEditingController();
  final Validator validator;
  final String requiredError;

  TextInputController([this.validator, this.requiredError]);

  String get text => editingController.text;

  set text(String text) => editingController.text = text ?? '';

  String validate(BuildContext ctx) {
    if (error == null) {
      if (requiredError != null && text.isEmpty)
        error = requiredError;
      else if (validator != null) error = validator(text);
    }
    if (error != null) focus(ctx);

    return error;
  }

  focus(BuildContext ctx) {
    FocusScope.of(ctx).requestFocus(focusNode);
  }
}

class AuthFormTextInput extends StatelessWidget {
  final String caption;
  final bool secret;
  final int maxLength;
  final TextInputType inputType;
  final TextInputController controller;
  final ValueChanged<String> onChanged;
  final bool readonly;
  final bool disabled;
  final String prefixText;

  AuthFormTextInput(
    this.caption, {
    this.secret = false,
    this.inputType = TextInputType.text,
    this.maxLength = 100,
    this.controller,
    this.onChanged,
    this.readonly = false,
    this.disabled = false,
    this.prefixText,
  });

  @override
  Widget build(BuildContext context) {
    final icon = controller?.success != null
        ? Image.asset('assets/images/ic__success.png',
            width: 18.0, height: 18.0)
        : controller?.error != null
            ? Image.asset('assets/images/ic__error.png')
            : null;
    final suffixIcon = icon == null
        ? null
        : Padding(
            padding: EdgeInsets.all(14.5),
            child: Container(
                decoration: BoxDecoration(
                  color: AppColors.authInputBorder,
                  shape: BoxShape.circle,
                ),
                padding: EdgeInsets.all(1.0),
                child: icon),
          );

    return new Stack(
      children: <Widget>[
        Container(
          height: 50.0,
          margin: EdgeInsets.symmetric(horizontal: 9.0),
          decoration: AppDecorations.authInputBox,
        ),
        TextField(
          controller: controller?.editingController,
          // textAlign: TextAlign.center,
          maxLines: 1,
          inputFormatters: [LengthLimitingTextInputFormatter(maxLength)],
          obscureText: secret,
          keyboardType: inputType,
          style: disabled ? AppStyles.textFieldDisabled : AppStyles.textField,
          decoration: InputDecoration(
            enabled: !readonly && !disabled,
            labelText: caption,
            labelStyle: AppStyles.authTextInputCaption,
            prefixText: prefixText,
            suffixIcon: suffixIcon,
            border: InputBorder.none,
            contentPadding: EdgeInsets.fromLTRB(15.0, 6.0, 0.0, 0.0),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class AuthFormButton extends StatelessWidget {
  final String text;
  final GestureTapCallback onPressed;
  final bool progress;
  final bool disabled;

  const AuthFormButton(this.text, this.onPressed,
      {this.progress, this.disabled});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 9.0),
      decoration: AppDecorations.authButtonBox,
      child: FlatButton(
        color: AppColors.authButton,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(text, maxLines: 1, style: AppStyles.authButtonText),
            progress
                ? Container(
                    height: 14.0,
                    width: 24.0,
                    padding: EdgeInsets.only(left: 10.0),
                    child: Theme(
                      data: ThemeData(accentColor: Colors.white),
                      child: CircularProgressIndicator(
                        strokeWidth: 1.3,
                      ),
                    ),
                  )
                : Container(),
          ],
        ),
        onPressed: disabled ? () => null : onPressed,
        padding: EdgeInsets.symmetric(vertical: 12.5),
      ),
    );
  }
}

class AuthFormHyperlink extends StatelessWidget {
  // final Widget child;
  final List<TextSpan> text;
  final GestureTapCallback onTap;
  final Color color;

  AuthFormHyperlink(this.text, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkResponse(
        radius: 20.0,
        splashColor: Colors.black.withAlpha(30),
        containedInkWell: true,
        highlightColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(10.0),
          child: RichText(
            text: TextSpan(
              children: text,
              style: AppStyles.authHyperlink.copyWith(color: color),
            ),
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
