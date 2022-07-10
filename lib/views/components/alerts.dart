/*
 * @author Oleg Khalidov (brooth@gmail.com).
 * -----------------------------------------------
 * Software Development:
 * Upwork: https://www.upwork.com/fl/khalidovoleg
 * Freelancer: https://www.freelancer.com/u/brooth
 */

import 'dart:async' as async;
import 'dart:math';
import 'package:acms/i18n/i18n.dart';
import 'package:acms/models/async.models.dart';
import 'package:acms/views/theme.dart';
import 'package:flutter/material.dart';

enum AlertSeverity { ERROR, SUCCESS }

class AlertData {
  final AlertSeverity sevirity;
  final String text;
  final Duration duration;
  final Function onDismiss;

  AlertData(this.sevirity, this.text, {this.duration, this.onDismiss});

  AlertData.success(String text,
      {String desc, Duration duration, Function onDismiss})
      : this(AlertSeverity.SUCCESS, text,
            duration: duration, onDismiss: onDismiss);

  AlertData.error(String text,
      {String desc, Duration duration, Function onDismiss})
      : this(AlertSeverity.ERROR, text,
            duration: duration, onDismiss: onDismiss);

  static AlertData fromAsyncError(AsyncError error) {
    var severity = AlertSeverity.ERROR;
    var msg = I18N.fromAsyncError(error);
    return AlertData(severity, msg);
  }
}

class NotificationToast extends StatefulWidget {
  final AlertData data;
  final double top;
  final Alignment alignment;

  NotificationToast(this.data,
      {this.top = 50.0, this.alignment = Alignment.topCenter});

  @override
  State createState() => new _NotificationToastState();
}

class _NotificationToastState extends State<NotificationToast>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  Animation<double> _opacity;
  async.Timer _delay;

  @override
  void initState() {
    super.initState();

    _controller = new AnimationController(
        duration: Duration(milliseconds: 100), vsync: this);
    _opacity = new Tween(begin: .0, end: 1.0).animate(_controller)
      ..addListener(() {
        setState(() {});
      });
    _startAnimation(.0);
  }

  void didUpdateWidget(covariant NotificationToast oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data != oldWidget.data) {
      _delay.cancel();
      _controller.reset();
      _startAnimation(1.0);
    }
  }

  void _startAnimation(double from) {
    _controller.forward(from: from);
    final duration = widget.data.duration ??
        Duration(milliseconds: max(widget.data.text.length * 70, 2000));
    _delay = async.Timer(duration, () {
      _controller.reverse().then((_) {
        if (widget.data.onDismiss != null) widget.data.onDismiss();
      });
    });
  }

  dispose() {
    _controller.dispose();
    _delay.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_opacity.value == .0) return Container();

    final icon = widget.data.sevirity == AlertSeverity.SUCCESS
        ? 'assets/images/ic__success.png'
        : 'assets/images/ic__error.png';

    return Opacity(
      opacity: _opacity.value,
      child: Align(
        alignment: widget.alignment,
        child: Container(
          margin: EdgeInsets.only(top: widget.top, left: 20.0, right: 20.0),
          padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
          decoration: AppDecorations.notification,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Image.asset(icon, width: 20.0, height: 20.0),
              Padding(padding: EdgeInsets.only(left: 10.0)),
              Flexible(
                  child: Text(widget.data.text,
                      maxLines: 5, style: AppStyles.notificationToastText)),
            ],
          ),
        ),
      ),
    );
  }
}
