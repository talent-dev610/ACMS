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
import 'package:acms/views/components/alerts.dart';
import 'package:acms/views/components/bars.dart';
import 'package:acms/views/theme.dart';
import 'package:acms/views/views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

class MakePublicScreen extends StatefulWidget {
  final Contact contact;

  const MakePublicScreen(this.contact);

  @override
  _MakePublicScreenState createState() => _MakePublicScreenState();
}

class _MakePublicScreenState extends State<MakePublicScreen>
    with WidgetStateUtilsMixin {
  bool _restricted;
  List<String> _restrictedGroup;
  String _filter;
  AlertData _notification;

  @override
  void initState() {
    _restricted = false;
    _restrictedGroup = [];
    _filter = '';

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, _ViewModel>(
      distinct: true,
      converter: (store) => _ViewModel(store),
      builder: (_, model) => Scaffold(
          backgroundColor: AppColors.lightBg,
          appBar: _buildAppBar(context, model),
          body: _buildBody(context, model)),
      onDidChange: (model) {
        if (model.hasChangePublicFailed() || model.hasLoadHoldersFailed()) {
          if (model.hasLoadHoldersFailed()) _restricted = false;
          setState(() => _notification = AlertData.fromAsyncError(
              model.changePublicState.error ?? model.loadHoldersState.error));
        }
        if (model.hasChangePublicSucceed()) Navigator.pop(context);
      },
    );
  }

  _buildAppBar(BuildContext context, _ViewModel model) {
    return TopBar(
      title: I18N.makePublic_title,
      leftAction: TopBarAction.cancel(() => Navigator.of(context).pop()),
      rightAction: !_restricted || _restrictedGroup.isNotEmpty
          ? TopBarAction.save(
              () => model.changePublic(widget.contact, true, _restrictedGroup),
              progress: model.changePublicState.isInProgress(),
            )
          : null,
      progress: model.loadHoldersState.isInProgress(),
    );
  }

  _buildBody(BuildContext context, _ViewModel model) {
    return Material(
      color: AppColors.lightBg,
      child: Stack(
        children: <Widget>[
          Padding(
              padding: EdgeInsets.all(5.0),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Radio(
                        groupValue: _restricted,
                        value: false,
                        onChanged: (_) => setState(() => _restricted = false),
                      ),
                      Text(I18N.makePublic_toEveryone, style: _Styles.radioText)
                    ],
                  ),
                  Divider(height: .5),
                  Row(
                    children: <Widget>[
                      Radio(
                        groupValue: _restricted,
                        value: true,
                        onChanged: (_) {
                          setState(() => _restricted = true);
                          if (model.loadHoldersState.isUseless())
                            model.loadHolders();
                        },
                      ),
                      Text(I18N.makePublic_restrict, style: _Styles.radioText)
                    ],
                  ),
                  _restricted && model.loadHoldersState.isSuccessful()
                      ? _buildHolderList(context, model)
                      : SizedBox()
                ],
              )),
          buildNotification(_notification),
        ],
      ),
    );
  }

  _buildHolderList(BuildContext context, _ViewModel model) {
    final holders = model.loadHoldersState.value
        .where((h) =>
            _filter.isEmpty ||
            _restrictedGroup.contains(h.id) ||
            h.name.toLowerCase().contains(_filter))
        .toList();

    return Expanded(
      child: Column(
        children: <Widget>[
          SizedBox(height: 10.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            child: TextField(
                style: _Styles.searchFieldText,
                decoration: InputDecoration(
                    hintText: I18N.makePublic_filterHint,
                    hintStyle: _Styles.searchFieldHint,
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(5.0)),
                onChanged: (text) =>
                    setState(() => _filter = text.trim().toLowerCase())),
          ),
          SizedBox(height: 10.0),
          Expanded(
            child: ListView.builder(
              itemCount: holders.length,
              itemBuilder: (_, index) {
                final holder = holders[index];
                return Row(
                  children: <Widget>[
                    Checkbox(
                        value: _restrictedGroup.contains(holder.id),
                        onChanged: (value) => setState(() {
                              if (value)
                                _restrictedGroup.add(holder.id);
                              else
                                _restrictedGroup.remove(holder.id);
                            })),
                    Text(holder.name, style: _Styles.holderName),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Styles {
  static const searchFieldText = TextStyle(
    fontFamily: 'NotoSans',
    fontSize: 16.0,
    color: Colors.black87,
    fontWeight: FontWeight.normal,
  );
  static final searchFieldHint = searchFieldText.copyWith(
    color: Colors.black38,
  );
  static final radioText = TextStyle(
    fontFamily: 'NotoSans',
    fontSize: 14.0,
    color: Colors.black87,
  );
  static final holderName = radioText;
}

class _ViewModel {
  final AppState _state;
  final Function _dispatch;

  _ViewModel(Store<AppState> store)
      : _state = store.state,
        _dispatch = store.dispatch;

  AsyncState<List<IdName>> get loadHoldersState =>
      _state.domainState.loadHoldersState;
  AsyncState<bool> get changePublicState =>
      _state.domainState.changePublicState;

  void changePublic(UserContact contact, bool value, List<String> restrictTo) =>
      _dispatch(ChangePublicAction(contact, value, restrictTo: restrictTo));

  void loadHolders() => _dispatch(LoadHoldersAction());

  bool hasLoadHoldersFailed() {
    final prev = _state.prevState?.domainState?.loadHoldersState;
    return prev != _state.domainState.loadHoldersState &&
        _state.domainState.loadHoldersState.isFailed();
  }

  bool hasChangePublicFailed() {
    final prev = _state.prevState?.domainState?.changePublicState;
    return prev != _state.domainState.changePublicState &&
        _state.domainState.changePublicState.isFailed();
  }

  bool hasChangePublicSucceed() {
    final prev = _state.prevState?.domainState?.changePublicState;
    return prev != _state.domainState.changePublicState &&
        _state.domainState.changePublicState.isSuccessful();
  }

  operator ==(o) {
    return o is _ViewModel &&
        this.changePublicState == o.changePublicState &&
        this.loadHoldersState == o.loadHoldersState;
  }

  @override
  int get hashCode => 0;
}
