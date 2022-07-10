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
import 'package:acms/views/components/domain.dart';
import 'package:acms/views/screens/main/contact_comments.screen.dart';
import 'package:acms/views/theme.dart';
import 'package:acms/views/views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:latlong/latlong.dart';
import 'package:redux/redux.dart';

class SearchMapScreen extends StatefulWidget {
  final Contact holder;
  final String query;
  final Contact searchByContact;
  final Function(Contact c) onTwiceSearchTap;
  final Function(Contact c) onOpenContactOptions;

  const SearchMapScreen({
    this.holder,
    this.query,
    this.searchByContact,
    this.onTwiceSearchTap,
    this.onOpenContactOptions,
  });

  @override
  _SearchMapScreenState createState() => _SearchMapScreenState();
}

class _SearchMapScreenState extends State<SearchMapScreen>
    with WidgetStateUtilsMixin {
  ContactsMapController _mapController;
  AlertData _notification;
  _ViewModel _model;

  @override
  void initState() {
    _mapController = ContactsMapController(
      onReady: () {
        if (widget.query != null || widget.searchByContact != null) _search();
      },
      onCameraChanged: () {
        if (widget.query == null && widget.searchByContact == null) _search();
      },
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, _ViewModel>(
      distinct: true,
      converter: (store) => _ViewModel(store),
      builder: (_, model) => Scaffold(
            backgroundColor: AppColors.lightBg,
            appBar: _buildTopBar(context, model),
            body: _buildBody(context, model),
          ),
      onInitialBuild: (model) {
        _model = model;
        model._dispatch(LocateContactsStateAction(AsyncState.create()));
      },
      onDidChange: (model) {
        _model = model;
        if (model.hasSearchFailed()) {
          setState(() => _notification = AlertData.error(
              I18N.loadContactsFailedError(
                  I18N.fromAsyncError(model.searchState.error))));
        }
        if (model.hasSearchSucceed()) {
          if (widget.query != null || widget.searchByContact != null) {
            if (model.searchState.isValueEmpty) {
              setState(() => _notification =
                  AlertData.error(I18N.searchMap_noLocationFoundError));
            } else {
              LatLngBounds bounds = new LatLngBounds();
              model.searchState.value.forEach((c) {
                if (c is ContactHolder) {
                  bounds.extend(LatLng(c.centerLatitude, c.centerLongitude));
                } else {
                  c.phones.forEach(
                      (p) => bounds.extend(LatLng(p.latitude, p.longitude)));
                }
              });
              if (!bounds.isValid) {
                setState(() => _notification =
                    AlertData.error(I18N.searchMap_noLocationFoundError));
                return;
              }
              _mapController.fitBounds(bounds,
                  FitBoundsOptions(padding: Point(30.0, 30.0), maxZoom: 6.0));
            }
          }
        }
      },
    );
  }

  _buildTopBar(BuildContext context, _ViewModel model) {
    return TopBar(
      lineHeight: 4.0,
      title: widget.searchByContact != null
          ? I18N.searchMap_contactSearchTitle(widget.searchByContact.name)
          : widget.query != null
              ? I18N.searchMap_queryTitle(widget.query)
              : I18N.searchMap_holderAcmsTitle(widget.holder.name),
      leftAction: TopBarAction.cancel(() => Navigator.of(context).pop()),
      rightAction:
          model.hasSearchFailed() ? TopBarAction.refresh(_search) : null,
      progress: model.searchState.isInProgress(),
    );
  }

  _buildBody(BuildContext context, _ViewModel model) {
    final value = model.searchState.value;
    return Stack(
      children: <Widget>[
        ContactsMap(
          value ?? <Contact>[],
          controller: _mapController,
          colorHolderMarkers: false,
          onOpenComments: (contact) => Navigator.push(context,
              AppRouteTransitions.none((_) => ContactCommentsScreen(contact))),
          onTwiceSearchTap: widget.onTwiceSearchTap != null
              ? (contact) {
                  Navigator.pop(context);
                  widget.onTwiceSearchTap(contact);
                }
              : null,
          onOpenContactOptions: widget.onOpenContactOptions,
        ),
        buildNotification(_notification),
      ],
    );
  }

  _search() {
    if (_model == null) return;

    if (widget.searchByContact != null) {
      _model.search(
          holder: widget.holder,
          queries: widget.searchByContact.getSearchables());
    } else if (widget.query == null) {
      if (_mapController.ready) {
        final bounds = _mapController.getBounds();
        if (bounds?.southEast != null && bounds.northWest != null)
          _model.search(holder: widget.holder, bounds: bounds);
      }
    } else {
      _model.search(holder: widget.holder, queries: [widget.query]);
    }
  }
}

class _ViewModel {
  final AppState _state;
  final Function _dispatch;

  _ViewModel(Store<AppState> store)
      : _state = store.state,
        _dispatch = store.dispatch;

  AsyncState<List<Contact>> get searchState =>
      _state.domainState.locateContactsState;

  void search({Contact holder, MapBounds bounds, List<String> queries}) =>
      _dispatch(LocateContactsAction(
          holder: holder, bounds: bounds, queries: queries));

  bool hasSearchFailed() {
    final prev = _state.prevState?.domainState?.locateContactsState;
    return prev != _state.domainState.locateContactsState &&
        _state.domainState.locateContactsState.isFailed();
  }

  bool hasSearchSucceed() {
    final prev = _state.prevState?.domainState?.locateContactsState;
    return prev != _state.domainState.locateContactsState &&
        _state.domainState.locateContactsState.isSuccessful();
  }

  operator ==(o) {
    return o is _ViewModel && searchState == o.searchState;
  }

  @override
  int get hashCode => 0;
}
