/*
 * @author Oleg Khalidov <brooth@gmail.com>.
 * -----------------------------------------------
 * Freelance software development:
 * Upwork: https://www.upwork.com/fl/khalidovoleg
 * Freelancer: https://www.freelancer.com/u/brooth
 */

import 'dart:async';

import 'package:acms/actions/domain.actions.dart';
import 'package:acms/i18n/i18n.dart';
import 'package:acms/models/async.models.dart';
import 'package:acms/models/domain.models.dart';
import 'package:acms/store/app.store.dart';
import 'package:acms/views/components/alerts.dart';
import 'package:acms/views/components/background.dart';
import 'package:acms/views/components/bars.dart';
import 'package:acms/views/components/domain.dart';
import 'package:acms/views/screens/main/contact_comments.screen.dart';
import 'package:acms/views/screens/main/contact_options.screen.dart';
import 'package:acms/views/screens/main/main.screen.dart';
import 'package:acms/views/screens/main/search_map.screen.dart';
import 'package:acms/views/theme.dart';
import 'package:acms/views/views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:latlong/latlong.dart';
import 'package:redux/redux.dart';
import 'package:rxdart/rxdart.dart';

class SearchTab extends StatefulWidget implements MainScreenTab {
  final _searchTextInputController = TextEditingController();
  final _seachQueryChanged$ = PublishSubject<String>();
  final Function(LatLng ll) onOpenLocation;
  final Function() _redrawTopBar;

  bool _enableMapSearch = false;
  Contact _searchByContact;
  _ViewModel _model;

  SearchTab(this.onOpenLocation, this._redrawTopBar);

  @override
  _SearchTabState createState() => _SearchTabState();

  @override
  onTabClick() {}

  @override
  Icon get tabIcon => Icon(Icons.search, size: 22.0);

  @override
  String get tabIconTitle => I18N.searchTab_tabText;

  @override
  Widget get topBar {
    return PreferredSize(
        preferredSize: Size(double.infinity, 58.0),
        child: StoreConnector<AppState, _ViewModel>(
          converter: (store) => _ViewModel(store),
          builder: (context, model) => TopBar(
                titleWidget: _searchByContact != null
                    ? GestureDetector(
                        child: Container(
                          height: 26.0,
                          margin: EdgeInsets.only(top: 11.0),
                          padding: EdgeInsets.fromLTRB(10.0, .0, 7.0, .0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(55.0),
                            color: AppPalette.secondaryColor,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Flexible(
                                child: Text(
                                  _searchByContact.name,
                                  style: _Styles.searchContextText,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: 5.0),
                              Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: Icon(Icons.close,
                                    color: Colors.white, size: 14.0),
                              ),
                            ],
                          ),
                        ),
                        onTap: () {
                          _searchByContact = null;
                          _redrawTopBar();
                          _search();
                        },
                      )
                    : Container(
                        padding: EdgeInsets.only(top: 6.0),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                                color: Color(0xFFE2E1DF),
                                style: BorderStyle.solid),
                          ),
                        ),
                        child: TextField(
                          controller: _searchTextInputController,
                          style: _Styles.searchFieldText,
                          decoration: InputDecoration(
                              hintText: I18N.searchTab_placeholder,
                              hintStyle: _Styles.searchFieldHint,
                              border: InputBorder.none,
                              contentPadding:
                                  EdgeInsets.fromLTRB(.0, 2.0, .0, 2.0)),
                          onChanged: (text) => _seachQueryChanged$.add(text),
                        ),
                      ),
                leftAction: TopBarAction(
                  icon: Icons.public,
                  iconSize: 20.0,
                  padding: EdgeInsets.only(top: 10.0),
                  disabled: !_enableMapSearch,
                  onPress: () => Navigator.push(
                      context,
                      AppRouteTransitions.standard(
                        (_) => _searchByContact != null
                            ? SearchMapScreen(
                                searchByContact: _searchByContact,
                                onTwiceSearchTap: searchByContact,
                                onOpenContactOptions: (contact) =>
                                    Navigator.push(
                                        context,
                                        AppRouteTransitions.none((_) =>
                                            ContactOptionsScreen(contact))))
                            : SearchMapScreen(
                                query: _searchTextInputController.text,
                                onTwiceSearchTap: searchByContact,
                                onOpenContactOptions: (contact) =>
                                    Navigator.push(
                                        context,
                                        AppRouteTransitions.none((_) =>
                                            ContactOptionsScreen(contact))),
                              ),
                      )),
                ),
                rightAction: TopBarAction.search(
                  () {
                    _search();
                    FocusScope.of(context).requestFocus(FocusNode());
                  },
                  progress: model.searchContactsState.isInProgress(),
                ),
              ),
          onInitialBuild: (model) {
            _model = model;
            // _seachQueryChanged$
            //     .debounce(Duration(milliseconds: 1500))
            //     .where((query) =>
            //         query != null &&
            //         model.searchContactsState.isNotInProgress())
            //     .listen((query) => model.searchContacts([query]));
            if (model.searchContactsState.isUseless()) _search();
          },
          onDidChange: (model) {
            if (model.hasSearchContactsSucceed()) {
              _enableMapSearch = model.searchContactsState.isValueNotEmpty &&
                  (_searchTextInputController.text.isNotEmpty ||
                      _searchByContact != null);
              if (_enableMapSearch) _redrawTopBar();
            }
          },
        ));
  }

  void searchByContact(Contact contact) {
    this._searchByContact = contact;
    _search();
  }

  void _search() {
    _seachQueryChanged$.add(null); // cancel events
    if (_searchByContact != null) {
      _model.searchContacts(_searchByContact.getSearchables());
    } else {
      _model.searchContacts([_searchTextInputController.text]);
    }
  }
}

class _SearchTabState extends State<SearchTab> with WidgetStateUtilsMixin {
  AlertData _notification;
  String _resultTooltip;

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, _ViewModel>(
      distinct: true,
      converter: (store) => _ViewModel(store),
      builder: (_, model) => _buildBody(context, model),
      onInitialBuild: (model) {
        model.getContactsCount();
      },
      onDidChange: (model) {
        if (model.hasSearchContactsStateChanged()) {
          if (model.searchContactsState.isFailed()) {
            setState(() => _notification =
                AlertData.fromAsyncError(model.searchContactsState.error));
            return;
          }
        }
        if (model.hasSearchContactsSucceed()) {
          if (model.searchContactsState.isValueNotEmpty) {
            setState(() {
              int count = 0;
              model.searchContactsState.value.forEach((c) {
                if (c is ContactHolder)
                  count += c.numberOfContacts;
                else
                  count++;
              });
              if (count > 0) {
                _resultTooltip = I18N.searchTab_foundContactTooltip(count);
                Future.delayed(Duration(seconds: 4), () {
                  setState(() {
                    _resultTooltip = null;
                  });
                });
              }
            });
          }
        }
      },
    );
  }

  _buildBody(BuildContext context, _ViewModel model) {
    final query = widget._searchTextInputController.text;
    final tooltip = _resultTooltip == null
        ? null
        : model.contactsCountState.isSuccessful()
            ? _resultTooltip +
                '\n' +
                I18N.searchTab_totalContactsTooltip(
                    model.contactsCountState.value)
            : _resultTooltip;

    return Stack(
      children: <Widget>[
        Container(
          child: model.searchContactsState.isSuccessful() &&
                  model.searchContactsState.value.isEmpty
              ? BackPrint(
                  icon: Icons.search,
                  message: query.isEmpty
                      ? I18N.searchTab_noContacts
                      : I18N.searchTab_noContactsFoundForQueryError(query))
              : _buildList(model, context),
        ),
        tooltip != null
            ? Align(
                alignment: Alignment.topRight,
                child: Container(
                  margin: EdgeInsets.all(5.0),
                  padding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 8.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5.0),
                    color: Colors.black.withAlpha(200),
                  ),
                  child: Text(tooltip, style: _Styles.searchResultTooltip),
                ))
            : SizedBox(),
        buildNotification(_notification),
      ],
    );
  }

  ListView _buildList(_ViewModel model, BuildContext context) {
    return ListView.builder(
        key: new PageStorageKey('searchListView'),
        itemCount: (model.searchContactsState.hasNoValue
                ? 0
                : model.searchContactsState.value.length) +
            2,
        itemBuilder: (_, index) {
          index = index - 2;
          if (index == -2)
            return Container(
              margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 5.0),
              padding: EdgeInsets.all(5.0),
              decoration: BoxDecoration(
                color: Color(0xFFffef9b),
                borderRadius: BorderRadius.circular(3.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: I18N.search_tips
                    .map((tip) => Text(
                          tip,
                          style: TextStyle(color: Color(0xffa25e31)),
                        ))
                    .toList(),
              ),
            );
          if (index == -1)
            return Container(
              margin: EdgeInsets.symmetric(vertical: .0, horizontal: 5.0),
              padding: EdgeInsets.all(5.0),
              decoration: BoxDecoration(
                color: Color(0xFFffef9b),
                borderRadius: BorderRadius.circular(3.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: I18N.search_tips2
                    .map((tip) => Text(
                          tip,
                          style: TextStyle(color: Color(0xffa25e31)),
                        ))
                    .toList(),
              ),
            );

          final contact = model.searchContactsState.value[index];
          return ContactListItem(
            contact: contact,
            onTap: () => showModalBottomSheet(
                context: context,
                builder: (_) => ContactInfoPanel(
                      contact,
                      holderHint: I18N.contactHolderSearchHint,
                      onOpenLocation: (ll) {
                        Navigator.of(context).pop();
                        widget.onOpenLocation(ll);
                      },
                      onOpenContactOptions: () => Navigator.push(
                          context,
                          AppRouteTransitions.none((_) => ContactOptionsScreen(
                                contact,
                                keyword: widget._searchByContact != null
                                    ? ''
                                    : widget._searchTextInputController.text,
                              ))),
                      onOpenHolderMap: () {
                        Navigator.push(
                            context,
                            AppRouteTransitions.standard((_) => SearchMapScreen(
                                  holder: contact,
                                  onTwiceSearchTap: widget.searchByContact,
                                )));
                      },
                      onOpenComments: () {
                        Navigator.push(
                            context,
                            AppRouteTransitions.none((_) =>
                                ContactCommentsScreen(
                                  contact,
                                  keyword: widget._searchByContact != null
                                      ? ''
                                      : widget._searchTextInputController.text,
                                )));
                      },
                    )),
            onSearchTap: () => widget.searchByContact(contact),
          );
        });
  }
}

class _Styles {
  static const searchFieldText = TextStyle(
    fontFamily: 'NotoSans',
    fontSize: 16.0,
    color: Colors.white,
    fontWeight: FontWeight.normal,
  );
  static final searchFieldHint = searchFieldText.copyWith(
    color: Colors.white30,
  );
  static const searchResultTooltip = TextStyle(
    fontFamily: 'NotoSans',
    fontSize: 14.0,
    color: Colors.white,
    fontWeight: FontWeight.w300,
  );
  static const searchContextText = TextStyle(
    fontFamily: 'NotoSans',
    fontSize: 14.0,
    color: Colors.white,
    fontWeight: FontWeight.w300,
  );
}

class _ViewModel {
  final AppState _state;
  final Function _dispatch;

  _ViewModel(Store<AppState> store)
      : _state = store.state,
        _dispatch = store.dispatch;

  AsyncState<List<Contact>> get searchContactsState =>
      _state.domainState.searchContactsState;

  AsyncState<int> get contactsCountState =>
      _state.domainState.contactsCountState;

  bool hasSearchContactsStateChanged() {
    final prev = _state.prevState?.domainState?.searchContactsState;
    return prev != _state.domainState.searchContactsState;
  }

  bool hasSearchContactsSucceed() {
    final prev = _state.prevState?.domainState?.searchContactsState;
    return prev != _state.domainState.searchContactsState &&
        _state.domainState.searchContactsState.isSuccessful();
  }

  void searchContacts(List<String> queries) {
    _dispatch(SearchContactsAction(queries));
  }

  void getContactsCount() {
    _dispatch(GetContactsCountAction());
  }

  operator ==(o) {
    return o is _ViewModel &&
        this.searchContactsState == o.searchContactsState &&
        this.contactsCountState == o.contactsCountState;
  }

  @override
  int get hashCode => 0;
}
