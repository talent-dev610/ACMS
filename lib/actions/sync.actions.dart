import 'dart:async';

import 'package:acms/actions/actions.dart';
import 'package:acms/api/api.dart';
import 'package:acms/i18n/i18n.dart';
import 'package:acms/models/async.models.dart';
import 'package:acms/models/domain.models.dart';
import 'package:acms/store/app.store.dart';
import 'package:acms/utils/phone_log.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:rxdart/rxdart.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:contacts_service/contacts_service.dart' as cs;
import 'package:shared_preferences/shared_preferences.dart';

final permissionHandler = PermissionHandler();

enum SyncStep {
  STEP_NONE,
  STEP_PERMISSIONS,
  STEP_LOCAL_CONTACTS,
  STEP_SERVER_CONTACTS,
  STEP_FINISH,
}

class UpdateSyncStepStateAction {
  final AsyncState<SyncStep> state;
  UpdateSyncStepStateAction(this.state);
}

class CheckPermissionsStateAction {
  final PermissionGroup permission;
  final AsyncState<PermissionStatus> state;

  CheckPermissionsStateAction(this.permission, this.state);
}

class CheckPermissionsAction implements AsyncAction {
  final List<PermissionGroup> permissions;

  CheckPermissionsAction(this.permissions);

  @override
  ThunkAction<AppState> execute(api) => (store) async {
        if (store.state.syncState.currentSyncStep.value ==
                SyncStep.STEP_PERMISSIONS &&
            (store.state.syncState.currentSyncStep.isInProgress() ||
                store.state.syncState.currentSyncStep.isSuccessful())) {
          return;
        }

        store.dispatch(UpdateSyncStepStateAction(
            AsyncState.inProgress(SyncStep.STEP_PERMISSIONS)));

        var denied = List<PermissionGroup>();
        for (var permission in permissions) {
          store.dispatch(
              CheckPermissionsStateAction(permission, AsyncState.inProgress()));
          var status =
              await permissionHandler.checkPermissionStatus(permission);
          if (status != PermissionStatus.granted) {
            denied.add(permission);
            store.dispatch(CheckPermissionsStateAction(
                permission, AsyncState.inProgress(status)));
          } else {
            store.dispatch(CheckPermissionsStateAction(
                permission, AsyncState.success(status)));
          }
        }

        if (denied.isNotEmpty) {
          var requestResults =
              await permissionHandler.requestPermissions(denied);

          bool deniedAgain = false;
          requestResults.forEach((key, value) {
            if (value != PermissionStatus.granted) {
              deniedAgain = true;
              store.dispatch(CheckPermissionsStateAction(
                  key,
                  AsyncState.failed(
                      AsyncError(AsyncErrorType.PERMISSION_DENIED,
                          AsyncErrorSeverity.ERROR),
                      value)));
            } else {
              store.dispatch(
                  CheckPermissionsStateAction(key, AsyncState.success(value)));
            }
          });
          if (deniedAgain) {
            store.dispatch(UpdateSyncStepStateAction(AsyncState.failed(
                AsyncError(
                    AsyncErrorType.PERMISSION_DENIED, AsyncErrorSeverity.ERROR),
                SyncStep.STEP_PERMISSIONS)));
            return;
          }
        }
        store.dispatch(UpdateSyncStepStateAction(
            AsyncState.success(SyncStep.STEP_PERMISSIONS)));
      };
}

class GotoSettingsAction implements AsyncAction {
  @override
  ThunkAction<AppState> execute(api) => (store) {
        permissionHandler.openAppSettings();
      };
}

class UpdateNetworkTypeStateAction {
  final AsyncState<ConnectivityResult> state;
  UpdateNetworkTypeStateAction(this.state);
}

class UpdateNetworkTypeAction implements AsyncAction {
  final ConnectivityResult event;
  UpdateNetworkTypeAction(this.event);
  @override
  ThunkAction<AppState> execute(api) => (store) {
        print('UpdateNetworkTypeAction $event');
        store.dispatch(
            UpdateNetworkTypeStateAction(AsyncState.success(this.event)));
      };
}

class ReadLocalContactsStateAction {
  final AsyncState<int> state;
  ReadLocalContactsStateAction(this.state);
}

class ReadLocalContactsAction implements AsyncAction {
  @override
  ThunkAction<AppState> execute(api) => (store) async {
        if (store.state.syncState.currentSyncStep.value ==
                SyncStep.STEP_LOCAL_CONTACTS &&
            (store.state.syncState.currentSyncStep.isInProgress() ||
                store.state.syncState.currentSyncStep.isSuccessful())) {
          return;
        }
        store.dispatch(UpdateSyncStepStateAction(
            AsyncState.inProgress(SyncStep.STEP_LOCAL_CONTACTS)));
        var iter = await cs.ContactsService.getContacts();
        print('Read ${iter.length} from local');
        store.dispatch(
            ReadLocalContactsStateAction(AsyncState.success(iter.length)));
        store.dispatch(UpdateSyncStepStateAction(
            AsyncState.success(SyncStep.STEP_LOCAL_CONTACTS)));
      };
}

class ReadServerContactsStateAction {
  final AsyncState<int> state;
  ReadServerContactsStateAction(this.state);
}

class ReadServerContactsAction implements AsyncAction {
  @override
  ThunkAction<AppState> execute(api) => (store) async {
        final session = store.state.authState.loginState.value;
        if (session == null) return;
        if (store.state.syncState.currentSyncStep.value ==
                SyncStep.STEP_SERVER_CONTACTS &&
            (store.state.syncState.currentSyncStep.isInProgress() ||
                store.state.syncState.currentSyncStep.isSuccessful())) {
          return;
        }
        store.dispatch(UpdateSyncStepStateAction(
            AsyncState.inProgress(SyncStep.STEP_SERVER_CONTACTS)));
        var retryCount = 0;
        if (store.state.syncState.serverContactsCount.isFailed()) {
          retryCount = store.state.syncState.serverContactsCount.value;
          if (retryCount >= 3) {
            var error = store.state.syncState.serverContactsCount.error;
            store.dispatch(ReadServerContactsStateAction(
                AsyncState.failed(error, retryCount)));
            store.dispatch(UpdateSyncStepStateAction(
                AsyncState.failed(error, SyncStep.STEP_SERVER_CONTACTS)));
            return;
          }
        }
        store.dispatch(ReadServerContactsStateAction(AsyncState.inProgress()));
        try {
          final data = await api.domain.getContactsCount(session);
          store.dispatch(
              ReadServerContactsStateAction(AsyncState.success(data)));
          store.dispatch(UpdateSyncStepStateAction(
              AsyncState.success(SyncStep.STEP_SERVER_CONTACTS)));
        } catch (error) {
          store.dispatch(ReadServerContactsStateAction(
              AsyncState.failed(error, retryCount + 1)));
          store.dispatch(UpdateSyncStepStateAction(
              AsyncState.failed(error, SyncStep.STEP_SERVER_CONTACTS)));
        }
      };
}

class SaveSyncProgressAction implements AsyncAction {
  @override
  ThunkAction<AppState> execute(api) => (store) async {
        store.dispatch(UpdateSyncStepStateAction(
            AsyncState.inProgress(SyncStep.STEP_FINISH)));
        final prefs = await SharedPreferences.getInstance();
        final value = prefs.setBool('is_sync_success', true);
        store.dispatch(UpdateSyncStepStateAction(
            AsyncState.success(SyncStep.STEP_FINISH)));
      };
}
