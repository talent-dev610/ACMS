/*
 * @author Oleg Khalidov (brooth@gmail.com).
 * -----------------------------------------------
 * Software Development:
 * Upwork: https://www.upwork.com/fl/khalidovoleg
 * Freelancer: https://www.freelancer.com/u/brooth
 */

import 'dart:async';

import 'package:acms/models/async.models.dart';
import 'package:acms/views/components/alerts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

abstract class WidgetStateUtilsMixin<T extends StatefulWidget>
    extends State<T> {
  final List<StreamSubscription> subscriptions = [];

  @protected
  @mustCallSuper
  void dispose() {
    super.dispose();
    subscriptions.forEach((s) => s.cancel());
    subscriptions.clear();
  }

  @protected
  Widget asyncStateWidget<V>(AsyncState<V> state,
      {Widget onSuccess(V value),
      Widget onFail(dynamic error),
      Widget onProgress(),
      Widget onValue(V value),
      Widget orElse()}) {
    if (state != null) {
      if (state.isSuccessful() && onSuccess != null)
        return onSuccess(state.value);
      if (state.isInProgress() && onProgress != null) return onProgress();
      if (state.isFailed() && onFail != null) return onFail(state.error);
      if (state.value != null && onValue != null) return onValue(state.value);
    }
    if (orElse != null) return orElse();
    return Container();
  }

  @protected
  Widget buildNotification(AlertData data,
      {double top = 10.0, Alignment alignment = Alignment.topCenter}) {
    return data == null
        ? Container()
        : NotificationToast(data, top: top, alignment: alignment);
  }

  void unfocus() {
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void hideKeyboard() => unfocus();
}
