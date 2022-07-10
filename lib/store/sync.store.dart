import 'package:acms/actions/sync.actions.dart';
import 'package:acms/models/async.models.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class SyncState {
  final AsyncState<PermissionStatus> contactsPermissionState;
  final AsyncState<PermissionStatus> locationPermissionState;
  final AsyncState<PermissionStatus> smsPermissionState;

  final AsyncState<ConnectivityResult> networkType;

  final AsyncState<int> serverContactsCount;
  final AsyncState<int> localContactsCount;

  final AsyncState<SyncStep> currentSyncStep;

  const SyncState(
    this.contactsPermissionState,
    this.locationPermissionState,
    this.networkType,
    this.serverContactsCount,
    this.localContactsCount,
    this.smsPermissionState,
    this.currentSyncStep,
  );

  SyncState.initial()
      : this(
          AsyncState.create(),
          AsyncState.create(),
          AsyncState.create(),
          AsyncState.create(),
          AsyncState.create(),
          AsyncState.create(),
          AsyncState.success(SyncStep.STEP_NONE),
        );

  SyncState copyWith({
    AsyncState<PermissionStatus> contactsPermissionState,
    AsyncState<PermissionStatus> locationPermissionState,
    AsyncState<ConnectivityResult> networkType,
    AsyncState<int> serverContactsCount,
    AsyncState<int> localContactsCount,
    AsyncState<PermissionStatus> smsPermissionState,
    AsyncState<SyncStep> currentSyncStep,
  }) =>
      SyncState(
        contactsPermissionState ?? this.contactsPermissionState,
        locationPermissionState ?? this.locationPermissionState,
        networkType ?? this.networkType,
        serverContactsCount ?? this.serverContactsCount,
        localContactsCount ?? this.localContactsCount,
        smsPermissionState ?? this.smsPermissionState,
        currentSyncStep ?? this.currentSyncStep,
      );
}

SyncState syncReducer(final SyncState state, dynamic action) {
  if (action is CheckPermissionsStateAction) {
    if (action.permission == PermissionGroup.contacts) {
      return state.copyWith(
        contactsPermissionState: action.state,
      );
    } else if (action.permission == PermissionGroup.location) {
      return state.copyWith(
        locationPermissionState: action.state,
      );
    } else if (action.permission == PermissionGroup.sms) {
      return state.copyWith(smsPermissionState: action.state);
    }
  } else if (action is UpdateNetworkTypeStateAction) {
    return state.copyWith(networkType: action.state);
  } else if (action is ReadLocalContactsStateAction) {
    return state.copyWith(localContactsCount: action.state);
  } else if (action is UpdateSyncStepStateAction) {
    return state.copyWith(currentSyncStep: action.state);
  } else if (action is ReadServerContactsStateAction) {
    return state.copyWith(serverContactsCount: action.state);
  }
  return state;
}
