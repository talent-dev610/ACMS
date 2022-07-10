/*
 * @author Oleg Khalidov <brooth@gmail.com>.
 * -----------------------------------------------
 * Freelance software development:
 * Upwork: https://www.upwork.com/fl/khalidovoleg
 * Freelancer: https://www.freelancer.com/u/brooth
 */

import 'package:acms/actions/domain.actions.dart';
import 'package:acms/c.dart';
import 'package:acms/i18n/i18n.dart';
import 'package:acms/models/async.models.dart';
import 'package:acms/models/domain.models.dart';
import 'package:acms/store/app.store.dart';
import 'package:acms/views/components/alerts.dart';
import 'package:acms/views/components/bars.dart';
import 'package:acms/views/components/domain.dart';
import 'package:acms/views/theme.dart';
import 'package:acms/views/views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:latlong/latlong.dart';
import 'package:redux/redux.dart';
import 'package:rxdart/rxdart.dart';

class ManualLocaionMapScreen extends StatefulWidget {
  final ContactPhone phone;
  final Contact contact;
  final Function(Location location) onLocation;
  final String title;

  const ManualLocaionMapScreen(this.phone, this.contact, this.onLocation,
      {Key key, this.title})
      : super(key: key);

  @override
  _State createState() => _State();
}

class _State extends State<ManualLocaionMapScreen> with WidgetStateUtilsMixin {
  final _mapPotitionChanged$ = PublishSubject<MapPosition>();

  Location _location;
  AlertData _notification;
  _ViewModel _model;

  @override
  void initState() {
    this.subscriptions.addAll([
      _mapPotitionChanged$
          .debounce(Duration(milliseconds: 1500))
          .listen((position) => _model.lookupLocation(position.center)),
    ]);

    super.initState();
  }

  @override
  void dispose() {
    _mapPotitionChanged$.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, _ViewModel>(
      distinct: true,
      converter: (store) => _ViewModel(store),
      builder: (_, model) => Scaffold(
            backgroundColor: AppColors.lightBg,
            appBar: _buildTopBar(model),
            body: _buildBody(model),
          ),
      onInitialBuild: (model) => _model = model,
      onDidChange: (model) {
        _model = model;
        if (model.hasLookupLocationFailed()) {
          setState(() => _notification =
              AlertData.fromAsyncError(model.lookupLocationState.error));
          return;
        }
        if (model.hasLookupLocationSucceed()) {
          setState(() => _location = model.lookupLocationState.value);
        }
        if (model.hasSaveManualPhoneLocationFailed()) {
          setState(() => _notification = AlertData.fromAsyncError(
              model.saveManualPhoneLocationState.error));
          return;
        }
        if (model.hasSaveManualPhoneLocationSucceed()) {
          widget.onLocation(_location);
          setState(() {
            _location = null;
            _notification = AlertData.success(
                I18N.manualLocation_savedSuccessfuly,
                onDismiss: () => Navigator.pop(context));
          });
        }
      },
    );
  }

  _buildTopBar(_ViewModel model) {
    return TopBar(
      title: widget.title ?? '',
      leftAction: _location == null
          ? TopBarAction.back(() => Navigator.pop(context))
          : TopBarAction.cancel(() => Navigator.pop(context)),
      rightAction: _location != null
          ? TopBarAction.save(() => _savePickedLocation(model),
              progress: model.saveManualPhoneLocationState.isInProgress())
          : null,
      progress: model.lookupLocationState.isInProgress(),
    );
  }

  _buildBody(_ViewModel model) {
    return Stack(
      children: <Widget>[
        FlutterMap(
          options: MapOptions(
              center: MAP_DEFAULT_CENTER,
              zoom: MAP_DEFAULT_ZOOM,
              onPositionChanged: (p) {
                if (_location != null) setState(() => _location = null);
                _mapPotitionChanged$.add(p);
              }),
          layers: [
            TileLayerOptions(
              urlTemplate: 'http://{host}:{port}/map_tiles/{x}/{y}/{z}?type=' +
                  (ContactsMap.mapMode == MapMode.NORMAL
                      ? 'normal'
                      : ContactsMap.mapMode == MapMode.TERRAIN
                          ? 'terrain'
                          : 'sattelite'),
              additionalOptions: {
                'host': BACKEND_HOST,
                'port': BACKEND_PORT.toString(),
              },
            ),
          ],
        ),
        Center(
          child: Padding(
            padding: EdgeInsets.only(bottom: 32.0),
            child: Icon(Icons.place, size: 40.0, color: Colors.redAccent),
          ),
        ),
        _location != null
            ? Center(
                child: Container(
                    margin: EdgeInsets.only(top: 35.0),
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(190),
                      borderRadius: BorderRadius.circular(99.0),
                    ),
                    child: Text(
                      _location.locality,
                      style: _Styles.locality,
                      softWrap: false,
                    )),
              )
            : SizedBox(),
        Padding(
          padding: const EdgeInsets.all(2.0),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Image.asset('assets/images/google_logo.png', width: 55.0),
          ),
        ),
        buildNotification(_notification),
      ],
    );
  }

  void _savePickedLocation(_ViewModel model) {
    final phoneCopy = widget.phone.copyWith(
      valid: true,
      country: _location.country,
      countryCode: _location.countryCode,
      locality: _location.locality,
      latitude: _location.latitude,
      longitude: _location.longitude,
    );
    model.saveManualPhoneLocations(phoneCopy, widget.contact);
  }
}

class _Styles {
  static final locality = TextStyle(
    fontFamily: 'NotoSans',
    fontSize: 14.0,
    color: Colors.white,
  );
}

class _ViewModel {
  final AppState _state;
  final Function _dispatch;

  _ViewModel(Store<AppState> store)
      : _state = store.state,
        _dispatch = store.dispatch;

  AsyncState<Location> get lookupLocationState =>
      _state.domainState.lookupLocationState;

  AsyncState get saveManualPhoneLocationState =>
      _state.domainState.saveManualPhoneLocationState;

  lookupLocation(LatLng ll) => _dispatch(LookupLocationAction(ll));

  saveManualPhoneLocations(ContactPhone phone, UserContact contact) =>
      _dispatch(SaveManualPhoneLocationAction(phone, contact));

  bool hasLookupLocationFailed() {
    final prev = _state.prevState?.domainState?.lookupLocationState;
    return prev != _state.domainState.lookupLocationState &&
        _state.domainState.lookupLocationState.isFailed();
  }

  bool hasLookupLocationSucceed() {
    final prev = _state.prevState?.domainState?.lookupLocationState;
    return prev != _state.domainState.lookupLocationState &&
        _state.domainState.lookupLocationState.isSuccessful();
  }

  bool hasSaveManualPhoneLocationFailed() {
    final prev = _state.prevState?.domainState?.saveManualPhoneLocationState;
    return prev != _state.domainState.saveManualPhoneLocationState &&
        _state.domainState.saveManualPhoneLocationState.isFailed();
  }

  bool hasSaveManualPhoneLocationSucceed() {
    final prev = _state.prevState?.domainState?.saveManualPhoneLocationState;
    return prev != _state.domainState.saveManualPhoneLocationState &&
        _state.domainState.saveManualPhoneLocationState.isSuccessful();
  }

  operator ==(o) {
    return o is _ViewModel &&
        lookupLocationState == o.lookupLocationState &&
        saveManualPhoneLocationState == o.saveManualPhoneLocationState;
  }

  @override
  int get hashCode => 0;
}
