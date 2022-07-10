/*
 * @author Oleg Khalidov <brooth@gmail.com>.
 * -----------------------------------------------
 * Freelance software development:
 * Upwork: https://www.upwork.com/fl/khalidovoleg
 * Freelancer: https://www.freelancer.com/u/brooth
 */

import 'package:acms/actions/domain.actions.dart';
import 'package:acms/i18n/i18n.dart';
import 'package:acms/models/async.models.dart';
import 'package:acms/models/domain.models.dart';
import 'package:acms/store/app.store.dart';
import 'package:acms/views/components/background.dart';
import 'package:acms/views/components/bars.dart';
import 'package:acms/views/components/domain.dart';
import 'package:acms/views/screens/main/contact_options.screen.dart';
import 'package:acms/views/screens/main/main.screen.dart';
import 'package:acms/views/theme.dart';
import 'package:acms/views/views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:latlong/latlong.dart';
import 'package:redux/redux.dart';

class BlackListTab extends StatefulWidget implements MainScreenTab {
  final Function(LatLng ll) onOpenLocation;
  _ViewModel _model;
  _BlackListTabState _state;

  BlackListTab(this.onOpenLocation);

  @override
  State<StatefulWidget> createState() {
    _state = _BlackListTabState();
    return _state;
  }

  @override
  onTabClick() {
    if (_model != null) _model.loadDislikeContacts();
  }

  @override
  Widget get tabIcon => Padding(
        padding: const EdgeInsets.only(bottom: 4.0),
        child: Icon(Icons.block),
      );

  @override
  String get tabIconTitle => I18N.blackList_title;

  @override
  Widget get topBar => PreferredSize(
        preferredSize: Size(double.infinity, 58.0),
        child: StoreConnector<AppState, _ViewModel>(
          converter: (store) => _ViewModel(store),
          builder: (context, model) => TopBar(
                lineHeight: 4.0,
                progress: model.loadDislikeContactsState.isInProgress(),
                titleWidget: Container(
                  padding: EdgeInsets.only(top: 6.0),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                          color: Color(0xFFE2E1DF), style: BorderStyle.solid),
                    ),
                  ),
                  child: TextField(
                      style: _Styles.filterFieldText,
                      decoration: InputDecoration(
                          hintText: I18N.blackList_filterPlaceholder,
                          hintStyle: _Styles.filterFieldHint,
                          border: InputBorder.none,
                          contentPadding:
                              EdgeInsets.fromLTRB(.0, 2.0, .0, 2.0)),
                      onChanged: (text) => _state?.setFilter(text)),
                ),
              ),
          onInitialBuild: (model) => this._model = model,
          onDidChange: (model) => this._model = model,
        ),
      );
}

class _BlackListTabState extends State<BlackListTab>
    with WidgetStateUtilsMixin {
  String filter = '';

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, _ViewModel>(
      converter: (store) => _ViewModel(store),
      builder: (_, model) => Material(
            color: Colors.white,
            child: asyncStateWidget<List<Contact>>(
              model.loadDislikeContactsState,
              onFail: (error) => BackPrint.fromAsyncError(error,
                  onTryAgain: () => model.loadDislikeContacts()),
              onValue: (_data) {
                final data =
                    _data.where((c) => c.matchesQuery(filter)).toList();
                if (data.isEmpty)
                  return BackPrint(
                      icon: Icons.search, message: I18N.blackList_empty);
                return ListView.builder(
                    key: new PageStorageKey('blackListView'),
                    itemCount: data.length,
                    itemBuilder: (_, index) {
                      final contact = data[index];
                      return ContactListItem(
                        contact: contact,
                        onOpenLocation: widget.onOpenLocation,
                        onOpenContactOptions: () => Navigator.push(
                            context,
                            AppRouteTransitions.none(
                                (_) => ContactOptionsScreen(contact))),
                      );
                    });
              },
            ),
          ),
      onInitialBuild: (model) => model.loadDislikeContacts(),
    );
  }

  void setFilter(String value) => setState(() => filter = value);
}

class _ViewModel {
  final AppState _state;
  final Function _dispatch;

  _ViewModel(Store<AppState> store)
      : _state = store.state,
        _dispatch = store.dispatch;

  AsyncState<List<Contact>> get loadDislikeContactsState =>
      _state.domainState.loadDislikeContactsState;

  void loadDislikeContacts() => _dispatch(new LoadDislikeContactsAction());

  bool hasLoadDislikeStateChanged() {
    final prev = _state.prevState?.domainState?.loadDislikeContactsState;
    return prev != _state.domainState.loadDislikeContactsState;
  }

  operator ==(o) {
    return o is _ViewModel &&
        loadDislikeContactsState != o.loadDislikeContactsState;
  }

  @override
  int get hashCode => 0;
}

class _Styles {
  static const filterFieldText = TextStyle(
    fontFamily: 'NotoSans',
    fontSize: 16.0,
    color: Colors.white,
    fontWeight: FontWeight.normal,
  );
  static final filterFieldHint = filterFieldText.copyWith(
    color: Colors.white30,
  );
  static const filterResultTooltip = TextStyle(
    fontFamily: 'NotoSans',
    fontSize: 14.0,
    color: Colors.white,
    fontWeight: FontWeight.w300,
  );
  static const filterContextText = TextStyle(
    fontFamily: 'NotoSans',
    fontSize: 14.0,
    color: Colors.white,
    fontWeight: FontWeight.w300,
  );
}
