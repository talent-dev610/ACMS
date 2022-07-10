/*
 * @author Oleg Khalidov <brooth@gmail.com>.
 * -----------------------------------------------
 * Freelance software development:
 * Upwork: https://www.upwork.com/fl/khalidovoleg
 * Freelancer: https://www.freelancer.com/u/brooth
 */

import 'dart:async';
import 'dart:io';

import 'package:acms/actions/domain.actions.dart';
import 'package:acms/actions/geo.actions.dart';
import 'package:acms/i18n/i18n.dart';
import 'package:acms/models/async.models.dart';
import 'package:acms/models/auth.models.dart';
import 'package:acms/models/domain.models.dart';
import 'package:acms/store/app.store.dart';
import 'package:acms/views/components/alerts.dart';
import 'package:acms/views/components/bars.dart';
import 'package:acms/views/components/base.dart';
import 'package:acms/views/components/domain.dart';
import 'package:acms/views/screens/main/cluster_list.screen.dart';
import 'package:acms/views/screens/main/contact_comments.screen.dart';
import 'package:acms/views/screens/main/contact_options.screen.dart';
import 'package:acms/views/screens/main/main.screen.dart';
import 'package:acms/views/screens/main/manual_location_list.screen.dart';
import 'package:acms/views/screens/main/search_map.screen.dart';
import 'package:acms/views/theme.dart';
import 'package:acms/views/views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong/latlong.dart';
import 'package:redux/redux.dart';
import 'package:rxdart/rxdart.dart';

typedef bool IsActive();

class MapTab extends StatefulWidget implements MainScreenTab {
  final IsActive isActive;
  final Function(Contact c) onTwiceSearchTap;
  final Function() redrawTopBar;
  List<Contact> showClusterList;
  List<Contact> clusterListFiltedContacts;
  _MapTabState _state;

  MapTab(this.isActive, this.onTwiceSearchTap, this.redrawTopBar);

  @override
  _MapTabState createState() {
    _state = _MapTabState();
    return _state;
  }

  @override
  onTabClick() {}

  @override
  Widget get tabIcon => Padding(
        padding: const EdgeInsets.only(bottom: 4.0),
        child: Icon(Icons.public),
      );

  @override
  String get tabIconTitle => I18N.map_tabText;

  @override
  Widget get topBar {
    if (showClusterList != null) {
      return PreferredSize(
          preferredSize: Size(double.infinity, 58.0),
          child: StatefulBuilder(
              builder: (context, _) => ClusterListTopBar(
                    showClusterList,
                    onFilter: (contacts) {
                      _state
                          .setState(() => clusterListFiltedContacts = contacts);
                    },
                    onClose: () {
                      _state.setState(() {
                        showClusterList = null;
                        clusterListFiltedContacts = null;
                        redrawTopBar();
                      });
                    },
                    onOpenComments: (contact) => Navigator.push(
                        context,
                        AppRouteTransitions.none(
                            (_) => ContactCommentsScreen(contact))),
                    onOpenHolderMap: (contact) => Navigator.push(
                        context,
                        AppRouteTransitions.standard((_) => SearchMapScreen(
                              holder: contact,
                              onTwiceSearchTap: onTwiceSearchTap,
                            ))),
                  )));
    }
    return PreferredSize(
      preferredSize: Size(double.infinity, 58.0),
      child: StoreConnector<AppState, _ViewModel>(
          converter: (store) => _ViewModel(store),
          builder: (context, model) {
            return TopBar(
              title: I18N.map_title,
              lineHeight: 4.0,
              progress: /*(model.currentPositionState.isInProgress() && !model.currentPositionState.isFailed()) ||*/
                  (model.findContactsState.isInProgress() && !model.findContactsState.isFailed()),
              rightActions: <Widget>[
                TopBarAction(
                    icon: Icons.person,
                    onPress: () => showDialog(
                        context: context,
                        builder: (_) =>
                            _buildContactsPermissionDialog(context, model))),
                TopBarAction(
                    icon: Icons.near_me,
                    onPress: () => showDialog(
                        context: context,
                        builder: (_) =>
                            _buildLocationPermissionDialog(context, model))),
              ],
            );
          }),
    );
  }

  openLocation(LatLng ll) => _state._openLocation(ll);

  _buildContactsPermissionDialog(BuildContext context, _ViewModel model) {
    String content = '';
    final actions = <Widget>[
      FlatButton(
        child: Text(I18N.close),
        onPressed: () => Navigator.pop(context),
      )
    ];

    if (model.userContactsState.isSuccessful()) {
      content += I18N.map_readContactsPermissionDialog_syncContent(
          model.userContactsState.value.length);

      final untranslatedPhones = <ContactPhone, Contact>{};
      model.userContactsState.value?.forEach((contact) => contact.phones
          .where((phone) =>
              model.loginState.isNotSuccessful() ||
              model.loginState.value.user.prefs.hiddenManualLocationPhones
                      .contains(phone.id) ==
                  false)
          .where((phone) =>
              phone.country == null ||
              phone.locality == null ||
              phone.latitude == null ||
              phone.longitude == null)
          .forEach((phone) => untranslatedPhones[phone] = contact));
      if (untranslatedPhones.isNotEmpty) {
        content += '\n' +
            I18N.map_readContactsPermissionDialog_untranslatedContent(
                untranslatedPhones.length);
        actions.add(
          FlatButton(
            child: Text(I18N.map_syncCompleteDialogSet,
                style: AppStyles.dialogActionText),
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).push(AppRouteTransitions.none(
                  (_) => ManualLocationListScreen(untranslatedPhones)));
            },
          ),
        );
      }
    }

    return AlertDialog(
      title: Text(I18N.map_readContactsPermissionDialogContent,
          style: _Styles.permissionDialogTitle),
      content: content.isNotEmpty
          ? Text(content, style: _Styles.permissionDialogContent)
          : null,
      actions: actions,
    );
  }

  _buildLocationPermissionDialog(BuildContext context, _ViewModel model) {
    return AlertDialog(
      title: Text(I18N.map_findLocationPermissionDialogContent,
          style: _Styles.permissionDialogTitle),
      actions: <Widget>[
        FlatButton(
          child: Text(I18N.close),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        FlatButton(
          child: Text(I18N.map_findLocationPermissionDialogMyLocation),
          onPressed: () {
            Navigator.pop(context);
            _state._openCurrentLocation(model);
          },
        )
      ],
    );
  }
}

class _MapTabState extends State<MapTab> with WidgetStateUtilsMixin {
  ContactsMapController _mapController;
  AlertData _notification;
  _ViewModel _model;
  DateTime _cameraChangedTs = DateTime.now();

  @override
  void initState() {
    _mapController = ContactsMapController(
        onCameraChanged: _updateContactHolders,
        onCameraMove: () => _cameraChangedTs = DateTime.now());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showClusterList != null) {
      return ClusterListBody(
        contacts: widget.clusterListFiltedContacts ?? widget.showClusterList,
        onOpenLocation: (ll) {
          widget.showClusterList = null;
          widget.redrawTopBar();
          setState(() {});
          new Timer(new Duration(milliseconds: 500),
              () => _mapController.move(ll, 10.0));
        },
        onTwiceSearchTap: widget.onTwiceSearchTap,
        onOpenComments: (contact) => Navigator.push(context,
            AppRouteTransitions.none((_) => ContactCommentsScreen(contact))),
        onOpenContactOptions: (contact) => Navigator.push(context,
            AppRouteTransitions.none((_) => ContactOptionsScreen(contact))),
        onOpenHolderMap: (contact) => Navigator.push(
            context,
            AppRouteTransitions.standard((_) => SearchMapScreen(
                  holder: contact,
                  onTwiceSearchTap: widget.onTwiceSearchTap,
                ))),
      );
    }

    return StoreConnector<AppState, _ViewModel>(
      distinct: true,
      converter: (store) => _ViewModel(store),
      builder: (context, model) => _buildMap(model),
      onInitialBuild: (m) {
        this._model = m;
        this.subscriptions.addAll([
          Observable.periodic(Duration(minutes: 3))
              .where((_) {
                print(['widget.isActive()', widget.isActive(), _cameraChangedTs, _cameraChangedTs.add(Duration(seconds: 1)), _cameraChangedTs
                    .add(Duration(seconds: 1))
                    .isBefore(DateTime.now())]);
                return widget.isActive() &&
                  _cameraChangedTs
                      .add(Duration(seconds: 1))
                      .isBefore(DateTime.now());
              })
              .listen((_) => _model.syncUserContacts()),
          Observable.timer(1, Duration(seconds: 3))
              .where((_) => !_model.hasSyncContactsSucceed()
              && _model.currentPositionState.isComplete()
              && !_model.isSyncContactsInProgress()
              )
              .listen((_) => _model.syncUserContacts(ifNotBusy: false)),
          /*Observable.periodic(Duration(seconds: 5))
              .where((_) => !_model.hasSyncContactsSucceed() && _model.currentPositionState.isComplete())
              .listen((_) => _model.syncUserContacts(ifNotBusy: false)),*/
          Observable.periodic(Duration(seconds: 10))
            .where((_) => _model.currentPositionState.isUseless() && _model.hasSyncContactsSucceed())
            .listen((event) {
              _model.getCurrentPosition(context);
            })
        ]);

        if (_model.currentPositionState.isUseless()) {
          _model.getCurrentPosition(context);
        }
      },
      onDidChange: (model) {
        this._model = model;
        if (model.hasSyncContactsFailed()) {
          if (model.userContactsState.error.type ==
              AsyncErrorType.PERMISSION_DENIED) {
            showDialog(
                context: context,
                builder: (_) => AlertDialog(
                      content:
                          Text(I18N.map_deniedContactsPermissionDialogContent),
                      actions: <Widget>[
                        FlatButton(
                          child: Text(I18N.quit),
                          onPressed: () {
                            exit(0);
                          },
                        ),
                      ],
                    ));
            return;
          }
          setState(() {
            _notification = AlertData.error(I18N.syncFailedError(
                I18N.fromAsyncError(model.userContactsState.error)));
          });
        }
        if (model.hasSyncContactsSucceed()) {
          _showSyncResultDialog(model);
        }
        if (model.hasLoadContactHoldersFailed()) {
          setState(() {
            _notification = AlertData.error(I18N.loadContactsFailedError(
                I18N.fromAsyncError(model.findContactsState.error)));
          });
        }
        if (model.hasCurrentPositionFailed()) {
          setState(() {
            _notification = AlertData.error(I18N.getLocationFailed);
          });
        }
        if (model.hasCurrentPositionSucceed()) {
          _openCurrentLocation(model);
        }
      },
    );
  }

  _buildMap(_ViewModel model) {
    final contacts = <Contact>[];
    if (model.userContactsState.hasValue)
      contacts.addAll(model.userContactsState.value);
    if (model.findContactsState.hasValue)
      contacts.addAll(model.findContactsState.value);

    return Stack(
      children: <Widget>[
        ContactsMap(
          contacts,
          controller: _mapController,
          onTwiceSearchTap: widget.onTwiceSearchTap,
          onOpenComments: (contact) => Navigator.push(context,
              AppRouteTransitions.none((_) => ContactCommentsScreen(contact))),
          onOpenContactOptions: (contact) => Navigator.push(context,
              AppRouteTransitions.none((_) => ContactOptionsScreen(contact))),
          onOpenClusterList: (contacts) => setState(() {
                widget.showClusterList = contacts;
                widget.redrawTopBar();
              }),
          onOpenHolderMap: (contact) {
            Navigator.push(
                context,
                AppRouteTransitions.standard((_) => SearchMapScreen(
                      holder: contact,
                      onTwiceSearchTap: widget.onTwiceSearchTap,
                    )));
          },
        ),
        model.userContactsState.isInProgress()
            ? Container(
                width: double.infinity,
                height: 25.0,
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                color: AppPalette.secondaryColor,
                child: Row(
                  children: <Widget>[
                    CircularActivityIndicator(color: Colors.white, size: 12.0),
                    SizedBox(width: 10.0),
                    Text(
                      I18N.map_syncContactsText,
                      style: _Styles.syncContactsText,
                    ),
                  ],
                ),
              )
            : SizedBox(),
        buildNotification(_notification),
      ],
    );
  }

  _updateContactHolders() {
    if (_model != null &&
        _mapController.ready &&
        _model.findContactsState.isNotInProgress()) {
      final bounds = _mapController.getBounds();
      if (bounds?.southEast != null && bounds.northWest != null)
        _model.findContacts(bounds);
    }
  }

  _openLocation(LatLng ll) => _mapController.move(ll, 10.0);

  _openCurrentLocation(_ViewModel model) {
    if (model.currentPositionState.isSuccessful()) {
      final p = model.currentPositionState.value;
      final ll = LatLng(p.latitude, p.longitude);
      _mapController.move(ll, 8.0);
    }
  }

  void _showSyncResultDialog(_ViewModel model) {
    final uploadedContacts = model.userContactsState.value
        .where((c) =>
            c.source == UserContactSource.SYNC_CREATE ||
            c.source == UserContactSource.SYNC_UPDATE)
        .toList();
    if (uploadedContacts.isEmpty) return;

    final untranslatedPhones = <ContactPhone, Contact>{};
    uploadedContacts.forEach((contact) => contact.phones
        .where((phone) =>
            model.loginState.isNotSuccessful() ||
            model.loginState.value.user.prefs.hiddenManualLocationPhones
                    .contains(phone.id) ==
                false)
        .where((phone) =>
            phone.country == null ||
            phone.locality == null ||
            phone.latitude == null ||
            phone.longitude == null)
        .forEach((phone) => untranslatedPhones[phone] = contact));
    final dialogActions = <Widget>[
      FlatButton(
        child: Text(I18N.close, style: AppStyles.dialogMinorActionText),
        onPressed: () => Navigator.pop(context),
      )
    ];
    if (untranslatedPhones.isNotEmpty)
      dialogActions.add(FlatButton(
        child: Text(I18N.map_syncCompleteDialogSet,
            style: AppStyles.dialogActionText),
        onPressed: () {
          Navigator.pop(context);
          Navigator.of(context).push(AppRouteTransitions.none(
              (_) => ManualLocationListScreen(untranslatedPhones)));
        },
      ));
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: Text(
                I18N.map_syncCompleteDialogTitle,
                style: AppStyles.dialogTitleText,
              ),
              content: Text(
                I18N.map_syncCompleteDialogContent(
                    uploadedContacts.length, untranslatedPhones.length),
                style: AppStyles.dialogContentText,
              ),
              actions: dialogActions,
            ));
  }
}

class _Styles {
  static final syncContactsText = TextStyle(
    fontFamily: 'NotoSans',
    fontSize: 14.0,
    color: AppColors.topBarTitle,
  );
  static final contactName = TextStyle(
    fontFamily: 'NotoSans',
    fontSize: 16.0,
    color: Colors.black87,
    fontWeight: FontWeight.w500,
  );
  static final contactInfo = TextStyle(
    fontSize: 15.0,
    fontFamily: 'NotoSans',
    color: AppPalette.primaryColor,
  );
  static final contactInfoHint = contactInfo.copyWith(
      color: Colors.grey.withAlpha(130), fontStyle: FontStyle.italic);

  static final contactHolderHint = contactName.copyWith(
    color: Colors.grey,
    fontWeight: FontWeight.normal,
  );
  static final clusterText = TextStyle(
    fontFamily: 'NotoSans',
    fontSize: 12.0,
    color: Colors.white,
  );
  static final permissionDialogContent = TextStyle(
    fontFamily: 'NotoSans',
    fontSize: 15.0,
    color: Colors.black87,
  );
  static final permissionDialogTitle = TextStyle(
    fontFamily: 'NotoSans',
    fontSize: 15.0,
    fontWeight: FontWeight.w500,
    color: Colors.black87,
  );
}

class _ViewModel {
  final AppState _state;
  final Function _dispatch;

  _ViewModel(Store<AppState> store)
      : _state = store.state,
        _dispatch = store.dispatch;

  AsyncState<Session> get loginState => _state.authState.loginState;
  AsyncState<List<UserContact>> get userContactsState =>
      _state.domainState.userContactsState;
  AsyncState<Position> get currentPositionState =>
      _state.geoState.currentPositionState;
  AsyncState<List<Contact>> get findContactsState =>
      _state.domainState.findContactsState;

  void syncUserContacts({ifNotBusy = true}) {
    if (!ifNotBusy ||
        (_state.domainState.userContactsState.isNotInProgress() &&
            _state.domainState.syncUserContactsState.isNotInProgress() &&
            _state.domainState.findContactsState.isNotInProgress() &&
            _state.domainState.searchContactsState.isNotInProgress() &&
            _state.domainState.locateContactsState.isNotInProgress() &&
            _state.domainState.lookupLocationState.isNotInProgress() &&
            _state.domainState.loadHoldersState.isNotInProgress() &&
            _state.domainState.findCommonContactsState.isNotInProgress() &&
            _state.geoState.currentPositionState.isNotInProgress()
        )) {
      _dispatch(new SyncUserContactsAction());
    }
  }

  void getCurrentPosition(BuildContext ctx) {
    _dispatch(new GetCurrentPositionAction());
  }

  void findContacts(MapBounds bounds) {
    _dispatch(new FindContactAction(bounds));
  }

  bool hasFindContactsChanged() {
    final prev = _state.prevState?.domainState?.findContactsState;
    return prev != _state.domainState.findContactsState;
  }

  bool hasSyncContactsFailed() {
    final prev = _state.prevState?.domainState?.syncUserContactsState;
    return prev != _state.domainState.syncUserContactsState &&
        _state.domainState.syncUserContactsState.isFailed();
  }

  bool hasSyncContactsSucceed() {
    final prev = _state.prevState?.domainState?.syncUserContactsState;
    return prev != _state.domainState.syncUserContactsState &&
        _state.domainState.syncUserContactsState.isSuccessful() &&
        prev.isNotSuccessful();
  }

  bool isSyncContactsInProgress() {
    return _state.domainState.syncUserContactsState.isInProgress();
  }

  bool hasCurrentPositionSucceed() {
    final prev = _state.prevState?.geoState?.currentPositionState;
    return prev != _state.geoState.currentPositionState &&
        _state.geoState.currentPositionState.isSuccessful();
  }

  bool hasCurrentPositionFailed() {
    final prev = _state.prevState?.geoState?.currentPositionState;
    return prev != _state.geoState.currentPositionState &&
        _state.geoState.currentPositionState.isFailed();
  }

  bool hasLoadContactHoldersFailed() {
    final prev = _state.prevState?.domainState?.findContactsState;
    return prev != _state.domainState.findContactsState &&
        _state.domainState.findContactsState.isFailed();
  }

  operator ==(o) {
    return o is _ViewModel &&
        this.loginState == o.loginState &&
        this.userContactsState == o.userContactsState &&
        this.findContactsState == o.findContactsState &&
        this.currentPositionState == o.currentPositionState;
  }

  @override
  int get hashCode => 0;
}
