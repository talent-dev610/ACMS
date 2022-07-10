/*
 * Developed in 2018 by Oleg Khalidov (brooth@gmail.com).
 *
 * Freelance Mobile Development:
 * UpWork: https://www.upwork.com/fl/khalidovoleg
 * Freelancer: https://www.freelancer.com/u/brooth
 */

import 'package:acms/i18n/i18n.dart';
import 'package:acms/models/async.models.dart';
import 'package:acms/views/components/alerts.dart';
import 'package:acms/views/components/base.dart';
import 'package:acms/views/theme.dart';
import 'package:flutter/material.dart';

class BackLoading extends StatelessWidget {
  final bool linear;

  BackLoading({this.linear = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width / 4),
        child: linear
            ? LinearActivityIndicator(color: AppColors.backLoading)
            : CircularActivityIndicator(
                color: AppColors.backLoading, size: 24.0),
      ),
    );
  }
}

class BackPrint extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String buttonTitle;
  final GestureTapCallback onButtonPress;

  BackPrint({
    this.icon,
    this.title,
    this.message,
    this.buttonTitle,
    this.onButtonPress,
  });

  static BackPrint fromAsyncError(AsyncError error,
      {String title, GestureTapCallback onTryAgain}) {
    final icon = error.severity == AsyncErrorSeverity.WARNING
        ? Icons.warning
        : Icons.error;
    final alertData = AlertData.fromAsyncError(error);
    return BackPrint(
        icon: icon,
        title: title,
        message: alertData.text,
        onButtonPress: onTryAgain);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 30.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            icon != null
                ? Icon(icon, size: 50.0, color: AppColors.backPrintIcon)
                : Container(),
            title != null
                ? Text(
                    title,
                    style: AppStyles.backPrintTitle,
                    textAlign: TextAlign.center,
                  )
                : Container(),
            message != null
                ? Text(
                    message,
                    style: AppStyles.backPrintMessage,
                    textAlign: TextAlign.center,
                  )
                : Container(),
            onButtonPress != null
                ? Container(
                    margin: EdgeInsets.only(top: 25.0),
                    decoration: AppDecorations.backPrintButton,
                    child: InkWell(
                        onTap: onButtonPress,
                        child: Padding(
                          padding: AppDimensions.backPrintButtonPadding,
                          child: Text(buttonTitle ?? I18N.tryAgain,
                              style: AppStyles.backPrintTryAgainButton),
                        )),
                  )
                : Container(),
          ],
        ),
      ),
    );
  }
}
