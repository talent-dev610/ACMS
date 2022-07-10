/*
 * @author Oleg Khalidov <brooth@gmail.com>.
 * -----------------------------------------------
 * Freelance software development:
 * Upwork: https://www.upwork.com/fl/khalidovoleg
 * Freelancer: https://www.freelancer.com/u/brooth
 */

import 'package:acms/actions/auth.actions.dart';
import 'package:acms/i18n/i18n.dart';
import 'package:acms/models/async.models.dart';
import 'package:acms/models/auth.models.dart';
import 'package:acms/models/domain.models.dart';
import 'package:acms/store/app.store.dart';
import 'package:acms/views/components/alerts.dart';
import 'package:acms/views/components/bars.dart';
import 'package:acms/views/screens/main/manual_location_map.screen.dart';
import 'package:acms/views/theme.dart';
import 'package:acms/views/views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

class ManualLocationListScreen extends StatefulWidget {
  final Map<ContactPhone, Contact> phones;

  const ManualLocationListScreen(this.phones);

  @override
  _ManualLocationListScreenState createState() {
    return new _ManualLocationListScreenState();
  }
}

class _ManualLocationListScreenState extends State<ManualLocationListScreen>
    with WidgetStateUtilsMixin {
  final Map<ContactPhone, Location> _savedLocations = {};
  AlertData _notification;

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, _ViewModel>(
      converter: (store) => _ViewModel(store),
      builder: (_, model) => Scaffold(
            backgroundColor: AppColors.lightBg,
            appBar: _buildTopBar(model),
            body: _buildList(model),
          ),
      onDidChange: (model) {
        if (model.hasHideFailed())
          setState(() =>
              _notification = AlertData.fromAsyncError(model.hideState.error));
      },
    );
  }

  _buildTopBar(_ViewModel model) {
    return TopBar(
      title: I18N.manualLocation_title,
      leftAction: TopBarAction.back(() => Navigator.pop(context)),
      progress: model.hideState.isInProgress(),
    );
  }

  _buildList(_ViewModel model) {
    final keys = widget.phones.keys
        .where((phone) =>
            model.session == null ||
            model.session.user.prefs.hiddenManualLocationPhones
                    .contains(phone.id) ==
                false)
        .toList();
    return Stack(
      children: <Widget>[
        ListView.builder(
            itemCount: keys.length,
            itemBuilder: (_, index) {
              final phone = keys[index];
              final contact = widget.phones[phone];
              final location = _savedLocations[phone];
              return Dismissible(
                key: Key(phone.id),
                direction: DismissDirection.startToEnd,
                onDismissed: (direction) => model.hide(phone),
                background: Container(
                  color: Colors.red,
                  padding: EdgeInsets.only(left: 15.0),
                  alignment: Alignment.centerLeft,
                  child: Icon(Icons.delete_forever,
                      size: 25.0, color: Colors.white),
                ),
                child: Container(
                    child: ListTile(
                      title: Text(contact.name,
                          style: _Styles.contactName,
                          overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                          phone.value +
                              (location != null
                                  ? ' - ' + location.locality
                                  : ''),
                          style: _Styles.contactPhone,
                          overflow: TextOverflow.ellipsis),
                      trailing: location != null
                          ? Icon(Icons.check, color: Colors.green, size: 20.0)
                          : Icon(Icons.keyboard_arrow_right,
                              color: Colors.grey),
                      contentPadding: EdgeInsets.fromLTRB(15.0, .0, 5.0, .0),
                      onTap: () => Navigator.push(
                          context,
                          AppRouteTransitions.standard((_) =>
                              ManualLocaionMapScreen(
                                  phone,
                                  contact,
                                  (location) => setState(
                                      () => _savedLocations[phone] = location),
                                  title: phone.value))),
                    ),
                    decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                      color: Color(0xffe5e5e5),
                    )))),
              );
            }),
        buildNotification(_notification),
      ],
    );
  }
}

class _ViewModel {
  final AppState _state;
  final Function _dispatch;

  _ViewModel(Store<AppState> store)
      : _state = store.state,
        _dispatch = store.dispatch;

  Session get session => _state.authState.loginState.value;

  AsyncState<String> get hideState =>
      _state.authState.hideFromManualLocationListState;

  hide(ContactPhone phone) {
    _dispatch(HideFromManualLocationListAction(phone));
  }

  bool hasHideFailed() {
    final prev = _state.prevState?.authState?.hideFromManualLocationListState;
    return prev != _state.authState.hideFromManualLocationListState &&
        _state.authState.hideFromManualLocationListState.isFailed();
  }

  operator ==(o) {
    return o is _ViewModel && hideState == o.hideState;
  }

  @override
  int get hashCode => 0;
}

class _Styles {
  static final contactName = TextStyle(
    fontFamily: 'NotoSans',
    fontSize: 16.0,
    color: Colors.black87,
  );
  static final contactPhone = TextStyle(
    fontFamily: 'NotoSans',
    fontSize: 14.0,
    color: Colors.black54,
  );
}
