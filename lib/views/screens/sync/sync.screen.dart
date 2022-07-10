import 'dart:async';
import 'dart:io';

import 'package:acms/actions/domain.actions.dart';
import 'package:acms/actions/sync.actions.dart';
import 'package:acms/i18n/i18n.dart';
import 'package:acms/models/async.models.dart';
import 'package:acms/store/app.store.dart';
/**
 * @author Felix Zhang <felixzhangsz@gmail.com>.
 */

import 'package:acms/views/views.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rxdart/rxdart.dart';

import '../../theme.dart';
import 'package:redux/redux.dart';

class SyncScreen extends StatefulWidget {
  @override
  _SyncScreenState createState() {
    return _SyncScreenState();
  }
}

class _SyncScreenState extends State<SyncScreen>
    with WidgetStateUtilsMixin, WidgetsBindingObserver {
  _ViewModel _model;

  // Connectivity
  var subscription;

  bool hasShowPermissionRequestDialog = false;

  _buildContactsPermissionWidget() {
    if (_model == null ||
        _model.currentStep.isValueEmpty ||
        _model.currentStep.value == null) {
      return [
        Offstage(
          offstage: true,
        )
      ];
    }

    var widgets = List<Widget>();
    if (_model.currentStep.value.index > SyncStep.STEP_NONE.index) {
      widgets.add(Text("Ready", style: _Styles.syncContactsText));
    }
    if (_model.currentStep.value.index >= SyncStep.STEP_PERMISSIONS.index) {
      widgets.add(Text(I18N.sync_checkingPermissions, style: _Styles.syncContactsText,));
      bool contactsPermissionGranted =
          _model?.isContactsPermissionGranted() ?? false;
      bool locationPermissionGranted =
          _model?.isLocationPermissionGranted() ?? false;
      bool smsPermissionGranted = _model?.isSmsPermissionGranted() ?? false;

      String contactsInfo = contactsPermissionGranted
          ? I18N.sync_grantContactsPermission
          : I18N.sync_deniedContactsPermission;
      String locationInfo = locationPermissionGranted
          ? I18N.sync_grantLocationPermission
          : I18N.sync_deniedLocationPermission;
      String smsInfo = smsPermissionGranted
          ? I18N.sync_grantSmsPermission
          : I18N.sync_deniedSmsPermission;
      widgets.add(Text(contactsInfo, style: _Styles.syncContactsText));
      widgets.add(Text(locationInfo, style: _Styles.syncContactsText));
      widgets.add(Text(smsInfo, style: _Styles.syncContactsText));
    }

    widgets.add(Text(I18N.sync_checkingNetworkType, style: _Styles.syncContactsText));
    if (_model.networkType.isSuccessful()) {
      var network = "None";
      if (_model.networkType.value == ConnectivityResult.mobile) {
        network = "mobile";
      } else if (_model.networkType.value == ConnectivityResult.wifi) {
        network = "WiFi";
      }
      widgets.add(Text(I18N.sync_getNetworkType(network), style: _Styles.syncContactsText));
    }

    if (_model.currentStep.value.index >= SyncStep.STEP_LOCAL_CONTACTS.index) {
      widgets.add(Text(I18N.sync_readinglocalContacts, style: _Styles.syncContactsText));
      if (_model.localContactsCount.isSuccessful()) {
        String localContactsCountInfo = I18N
            .sync_localContactsCount(_model.localContactsCount?.value ?? -1);
        widgets.add(Text(localContactsCountInfo, style: _Styles.syncContactsText));
      }
    }
    if (_model.currentStep.value.index >= SyncStep.STEP_SERVER_CONTACTS.index) {
      widgets.add(Text(I18N.sync_readingServerContacts, style: _Styles.syncContactsText));
      if (_model.serverContactsCount.isSuccessful()) {
        String serverContactsCount =
            I18N.sync_serverContactsCount(_model.serverContactsCount.value);
        widgets.add(Text(serverContactsCount, style: _Styles.syncContactsText));
      } else if (_model.serverContactsCount.isFailed()) {
        var retryCount = _model.serverContactsCount.value;
        if (retryCount >= 3) {
          String serverContactsCount =
              I18N.sync_serverContactsCountError(retryCount);
          widgets.add(Text(serverContactsCount, style: _Styles.syncContactsText));
        }
      }
    }
    return widgets;
  }

  @override
  void initState() {
    super.initState();
    print('initState $this');
    WidgetsBinding.instance?.addObserver(this);
    subscription = Connectivity().onConnectivityChanged.listen((event) {
      print('updateNetworkType $event');
      this._model.updateNetworkType(event);
    });
  }

  @override
  void dispose() {
    print('dispose $this');
    super.dispose();
    WidgetsBinding.instance?.removeObserver(this);
    subscription.cancel();
  }

  bool fromBackground = false;
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        print("Entering resumed state $this");
        if (fromBackground && _model.currentStep.hasValue) {
          if (_model.currentStep.value == SyncStep.STEP_PERMISSIONS) {
            if (_model.currentStep.isFailed()) {
              _model.checkPermissionStatus();
            }
          }
        }
        fromBackground = false;
        break;
      case AppLifecycleState.inactive:
        print("Enterring inactive state $this");
        break;
      case AppLifecycleState.detached:
        print("Entering detached state $this");
        break;
      case AppLifecycleState.paused:
        print("Entering paused state $this");
        fromBackground = true;
        break;
      default:
    }
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, _ViewModel>(
      distinct: true,
      converter: (store) => _ViewModel(store),
      onInitialBuild: (model) {
        print("sync.screen onInitialBuild ${DateTime.now()} $this");
        this._model = model;
        _model.nextStep();
      },
      onWillChange: (model) async {
        this._model = model;
        if (model.currentStep.value == SyncStep.STEP_FINISH) {
          if (model.currentStep.isSuccessful()) {
            await Future.delayed(Duration(seconds: 3));
            print('navigate to main $mounted');
            Navigator.of(context).pushReplacementNamed('main');
            return;
          }
        }
      },
      onDidChange: (model) async {
        this._model = model;
        if (!mounted) {
          return;
        }
        if (model.currentStep.hasValue) {
          if (model.currentStep.value == SyncStep.STEP_PERMISSIONS) {
            if (model.currentStep.isFailed()) {
              if (hasShowPermissionRequestDialog) {
                return;
              }
              hasShowPermissionRequestDialog = true;
              showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => AlertDialog(
                        content: Text(
                            I18N.map_deniedContactsPermissionDialogContent),
                        actions: <Widget>[
                          FlatButton(
                            child: Text(I18N.sync_permissionRequestTips),
                            onPressed: () {
                              _model.gotoSettings();
                              Navigator.pop(context);
                              hasShowPermissionRequestDialog = false;
                            },
                          ),
                        ],
                      ));
              return;
            }
          } else if (model.currentStep.value == SyncStep.STEP_SERVER_CONTACTS) {
            if (model.currentStep.isFailed() &&
                model.serverContactsCount.value < 3) {
              model.readServerContacts();
              return;
            }
          }
        }
        _model.nextStep();
        // if (this.mounted) {
        //   setState(() {});
        // }
      },
      builder: (context, model) => Material(
        color: AppColors.darkBg,
        child: Scaffold(
          appBar: AppBar(
            title: Text("Sync Progress"),
          ),
          body: Center(
            child: Column(
              children: _buildContactsPermissionWidget(),
            ),
          ),
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

  AsyncState<SyncStep> get currentStep => _state.syncState.currentSyncStep;

  AsyncState<PermissionStatus> get contactsPermissionState =>
      _state.syncState.contactsPermissionState;

  AsyncState<PermissionStatus> get locationPermissionState =>
      _state.syncState.locationPermissionState;

  AsyncState<PermissionStatus> get smsPermissionState =>
      _state.syncState.smsPermissionState;

  AsyncState<int> get localContactsCount => _state.syncState.localContactsCount;

  AsyncState<int> get serverContactsCount =>
      _state.syncState.serverContactsCount;

  AsyncState<ConnectivityResult> get networkType =>
      _state.syncState.networkType;

  bool isInPermissionStep() {
    return currentStep.value == SyncStep.STEP_PERMISSIONS;
  }

  bool hasPermissionDenied() {
    return contactsPermissionState.isFailed() ||
        locationPermissionState.isFailed() ||
        smsPermissionState.isFailed();
  }

  bool isContactsPermissionGranted() {
    return _state.syncState.contactsPermissionState.value ==
        PermissionStatus.granted;
  }

  bool isLocationPermissionGranted() {
    return _state.syncState.locationPermissionState.value ==
        PermissionStatus.granted;
  }

  bool isSmsPermissionGranted() {
    return _state.syncState.smsPermissionState.value ==
        PermissionStatus.granted;
  }

  void checkPermissionStatus([force = false]) {
    print('checkPermissionStatus');
    if (_state.syncState.currentSyncStep.value != SyncStep.STEP_PERMISSIONS ||
        (_state.syncState.currentSyncStep.value == SyncStep.STEP_PERMISSIONS &&
            _state.syncState.currentSyncStep.isFailed())) {
      _dispatch(new CheckPermissionsAction([
        PermissionGroup.contacts,
        PermissionGroup.location,
        PermissionGroup.sms,
      ]));
    }
  }

  void updateNetworkType(ConnectivityResult event) {
    _dispatch(new UpdateNetworkTypeAction(event));
  }

  void readServerContacts() {
    _dispatch(new ReadServerContactsAction());
  }

  void readLocalContacts() {
    _dispatch(new ReadLocalContactsAction());
  }

  void gotoSettings() {
    _dispatch(new GotoSettingsAction());
  }

  void saveProgress() {
    _dispatch(new SaveSyncProgressAction());
  }

  void nextStep() {
    print(
        'nextStep currentStep: ${currentStep.value} ${currentStep.isSuccessful()}');
    if (currentStep.hasValue && currentStep.isSuccessful()) {
      if (currentStep.value == SyncStep.STEP_NONE) {
        checkPermissionStatus();
      } else if (currentStep.value == SyncStep.STEP_PERMISSIONS) {
        readLocalContacts();
      } else if (currentStep.value == SyncStep.STEP_LOCAL_CONTACTS) {
        readServerContacts();
      } else if (currentStep.value == SyncStep.STEP_SERVER_CONTACTS) {
        saveProgress();
      }
    }
  }

  operator ==(o) {
    return o is _ViewModel &&
        contactsPermissionState == o.contactsPermissionState &&
        locationPermissionState == o.locationPermissionState &&
        smsPermissionState == o.smsPermissionState &&
        networkType == o.networkType &&
        localContactsCount == o.localContactsCount &&
        serverContactsCount == o.serverContactsCount &&
        currentStep == o.currentStep;
  }

  @override
  int get hashCode => 0;
}

class _Styles {
  static final syncContactsText = TextStyle(
    fontFamily: 'NotoSans',
    fontSize: 14.0,
    color: AppColors.topBarTitle,
  );
}