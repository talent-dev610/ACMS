/*
 * @author Oleg Khalidov <brooth@gmail.com>.
 * -----------------------------------------------
 * Freelance software development:
 * Upwork: https://www.upwork.com/fl/khalidovoleg
 * Freelancer: https://www.freelancer.com/u/brooth
 */
import 'dart:async';
import 'package:rxdart/rxdart.dart';

enum AsyncStatus { NEW, IN_PROGRESS, SUCCESS, FAILED }

class AsyncState<V> {
  final AsyncStatus status;
  final V value;
  final AsyncError error;

  const AsyncState(this.status, [this.value, this.error]);

  const AsyncState.create([V value]) : this(AsyncStatus.NEW, value);
  const AsyncState.inProgress([V value]) : this(AsyncStatus.IN_PROGRESS, value);
  const AsyncState.success([V value]) : this(AsyncStatus.SUCCESS, value);

  static AsyncState<V> failed<V>(dynamic error, [V value]) {
    if (error is AsyncError)
      return AsyncState(AsyncStatus.FAILED, value, error);

    print(error);
    if (error is Error) print(error.stackTrace);
    return AsyncState(AsyncStatus.FAILED, value, AsyncError.appError());
  }

  bool get hasValue => value != null;
  bool get hasNoValue => value == null;
  bool get isValueEmpty =>
      value is List && (value == null || (value as List).isEmpty);
  bool get isValueNotEmpty =>
      value is List && value != null && (value as List).isNotEmpty;

  // todo: all getters
  bool isSuccessful() => status == AsyncStatus.SUCCESS;
  bool isNotSuccessful() => status != AsyncStatus.SUCCESS;
  bool isNew() => status == AsyncStatus.NEW;
  bool isUseless() => status == AsyncStatus.NEW || status == AsyncStatus.FAILED;
  bool isFailed() => status == AsyncStatus.FAILED;
  bool isComplete() =>
      status == AsyncStatus.FAILED || status == AsyncStatus.SUCCESS;
  bool isInProgress() => status == AsyncStatus.IN_PROGRESS;
  bool isNotInProgress() => status != AsyncStatus.IN_PROGRESS;

  AsyncState<V> copyWith({V value}) =>
      new AsyncState<V>(this.status, value ?? this.value, this.error);

  operator ==(o) {
    return o is AsyncState &&
        o != null &&
        status == o.status &&
        value == o.value;
  }

  @override
  int get hashCode => 0;
}

enum AsyncErrorSeverity { FATAL, ERROR, WARNING }
enum AsyncErrorType {
  // app
  NETWORK_PROBLEMS,
  SERVER_ERROR,
  APP_ERROR,

  PERMISSION_DENIED,

  // API
  INVALID_PHONE_NUMBER,
  SESSION_EXPIRED,
  TOO_MANY_REQUESTS,
  NO_VERIFICATION_CODE,
  INVALID_VERIFICATION_CODE,
  USER_NOT_FOUND,
  PHONE_NUMBER_TAKEN,
  FAILED_TO_SEND_SMS,
  LOCATION_NOT_FOUND,
}

class AsyncError {
  final AsyncErrorType type;
  final AsyncErrorSeverity severity;
  final dynamic data;

  const AsyncError(this.type, this.severity, [this.data]);

  const AsyncError.error(AsyncErrorType kind, [String msg])
      : this(kind, AsyncErrorSeverity.ERROR, msg);
  const AsyncError.networkProblems()
      : this(AsyncErrorType.NETWORK_PROBLEMS, AsyncErrorSeverity.WARNING);
  const AsyncError.serverError()
      : this(AsyncErrorType.SERVER_ERROR, AsyncErrorSeverity.ERROR);
  const AsyncError.appError()
      : this(AsyncErrorType.APP_ERROR, AsyncErrorSeverity.ERROR);

  Stream asStream() => Observable.error(this);

  @override
  String toString() {
    return 'AsyncError{code: $type, severity: $severity, data: $data}';
  }
}
