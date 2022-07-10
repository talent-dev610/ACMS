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
import 'package:acms/views/components/background.dart';
import 'package:acms/views/components/bars.dart';
import 'package:acms/views/components/domain.dart';
import 'package:acms/views/theme.dart';
import 'package:acms/views/views.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

class CommonContactsScreen extends StatefulWidget {
  final List<ContactHolder> holders;
  final Function(Contact c) onOpenComments;
  final Function(Contact c) onOpenHolderMap;

  const CommonContactsScreen(this.holders,
      {this.onOpenComments, this.onOpenHolderMap});

  @override
  _CommonContactsScreenState createState() {
    return new _CommonContactsScreenState();
  }
}

class _CommonContactsScreenState extends State<CommonContactsScreen>
    with WidgetStateUtilsMixin {
  AlertData _notification;

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, _ViewModel>(
      distinct: true,
      converter: (store) => _ViewModel(store),
      builder: (_, model) => Scaffold(
            backgroundColor: AppColors.lightBg,
            appBar: _buldTopbar(model),
            body: SafeArea(
              child: _buildBody(model),
            ),
          ),
      onInitialBuild: (model) {
        model.findCommonContacts(widget.holders);
      },
      onDidChange: (model) {
        if (model.hasFindCommonContactsFailed()) {
          this.setState(() => _notification =
              AlertData.fromAsyncError(model.findCommonContactsState.error));
        }
      },
    );
  }

  _buildBody(_ViewModel model) {
    return Stack(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(5.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: model.findCommonContactsState.hasValue
                    ? _buildList(model)
                    : SizedBox(),
              ),
            ],
          ),
        ),
        buildNotification(_notification),
      ],
    );
  }

  _buildList(_ViewModel model) {
    final matches = model.findCommonContactsState.value;
    final data = new Map<String, List<_ResultItem>>();
    widget.holders.forEach((h1) {
      widget.holders.forEach((h2) {
        if (h1 == h2 || h1.locality != h2.locality) return;
        final locality = h1.locality;
        h1.contacts.forEach((c1) {
          h2.contacts.forEach((c2) {
            if (matches[c1] != null && matches[c1].contains(c2) ||
                matches[c2] != null && matches[c2].contains(c1)) {
              if (data.containsKey(locality) == false) data[locality] = [];
              var item = data[locality].firstWhere(
                  (i) => i.contactIds.contains(c1) || i.contactIds.contains(c2),
                  orElse: () {
                final ri = new _ResultItem([], [], []);
                data[locality].add(ri);
                return ri;
              });
              item.contactIds.add(c1);
              item.contactIds.add(c2);
              if (!item.holders.contains(h1)) item.holders.add(h1);
              if (!item.holders.contains(h2)) item.holders.add(h2);
            }
          });
        });
      });
    });

    data.keys.forEach((locality) {
      final items = data[locality];
      for (var i = 0; i < items.length; i++) {
        final item1 = items[i];
        if (item1.holders.isEmpty) continue;
        item1.contacts.add(item1.contactIds[0]);
        for (var j = 0; j < items.length; j++) {
          final item2 = items[j];
          if (i == j || item2.holders.isEmpty) continue;
          final common = item2.holders.where((h) => item1.holders.contains(h));
          if (item1.holders.length == common.length) {
            item1.contacts.add(item2.contactIds[0]);
            if (item1.holders.length == item2.holders.length)
              item2.holders.clear();
          }
        }
      }
    });

    final listItems = List<Widget>();
    data.keys.forEach((locality) {
      data[locality].forEach((item) {
        if (item.holders.isNotEmpty) {
          listItems.add(Container(
            constraints: BoxConstraints(minHeight: 60.0),
            padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 5.0),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(
              color: Color(0xffe5e5e5),
            ))),
            child: RichText(
              text: TextSpan(
                style: _Styles.itemText,
                children: item.holders
                    .map(
                      (holder) => TextSpan(
                            text: holder.name +
                                (holder == item.holders.last ? '' : ', '),
                            style: _Styles.holderName,
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => showModalBottomSheet(
                                  context: context,
                                  builder: (_) => ContactInfoPanel(
                                        holder,
                                        holderHint: (_) => '',
                                        onOpenComments: widget.onOpenComments ==
                                                null
                                            ? null
                                            : () =>
                                                widget.onOpenComments(holder),
                                        onOpenHolderMap:
                                            widget.onOpenHolderMap == null
                                                ? null
                                                : () => widget
                                                    .onOpenHolderMap(holder),
                                      )),
                          ),
                    )
                    .toList()
                      ..add(TextSpan(
                          text: I18N.commonContactsRecord(
                              locality, item.contacts.length))),
              ),
            ),
          ));
        }
      });
    });

    if (listItems.isEmpty)
      return BackPrint(
          icon: Icons.people, message: I18N.commonContactsNotFound);
    return ListView(
      shrinkWrap: true,
      children: listItems,
    );
  }

  _buldTopbar(_ViewModel model) {
    return TopBar(
      title: I18N.commonContactsTitle,
      leftAction: TopBarAction.cancel(() => Navigator.of(context).pop()),
      rightAction: model.hasFindCommonContactsFailed()
          ? TopBarAction.refresh(() => model.findCommonContacts(widget.holders))
          : null,
      progress: model.findCommonContactsState.isInProgress(),
    );
  }
}

class _ResultItem {
  final List<String> contactIds;
  final List<ContactHolder> holders;
  final List<String> contacts;

  _ResultItem(this.contactIds, this.holders, this.contacts);
}

class _Styles {
  static final itemText = TextStyle(
    fontFamily: 'NotoSans',
    fontSize: 14.0,
    color: Color(0xff444444),
  );
  static final holderName = itemText.copyWith(color: Colors.blue);
}

class _ViewModel {
  final AppState _state;
  final Function _dispatch;

  _ViewModel(Store<AppState> store)
      : _state = store.state,
        _dispatch = store.dispatch;

  AsyncState<Map<String, List<String>>> get findCommonContactsState =>
      _state.domainState.findCommonContactsState;

  void findCommonContacts(List<ContactHolder> holders) {
    final ids = List<String>();
    holders.forEach((h) {
      ids.addAll(h.contacts);
    });
    _dispatch(new FindCommonContactsAction(ids));
  }

  bool hasFindCommonContactsFailed() {
    final prev = _state.prevState?.domainState?.findCommonContactsState;
    return prev != _state.domainState.findCommonContactsState &&
        _state.domainState.findCommonContactsState.isFailed();
  }

  operator ==(o) {
    return o is _ViewModel &&
        this.findCommonContactsState == o.findCommonContactsState;
  }

  @override
  int get hashCode => 0;
}
