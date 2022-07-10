/*
 * @author Oleg Khalidov <brooth@gmail.com>.
 * -----------------------------------------------
 * Freelance software development:
 * Upwork: https://www.upwork.com/fl/khalidovoleg
 * Freelancer: https://www.freelancer.com/u/brooth
 */

import 'package:acms/i18n/i18n.dart';
import 'package:acms/models/domain.models.dart';
import 'package:acms/views/components/background.dart';
import 'package:acms/views/components/bars.dart';
import 'package:acms/views/components/domain.dart';
import 'package:acms/views/screens/main/common_contacts.screen.dart';
import 'package:acms/views/theme.dart';
import 'package:flutter/material.dart';
import 'package:latlong/latlong.dart';

class ClusterListTopBar extends StatelessWidget implements PreferredSizeWidget {
  final List<Contact> contacts;
  final Function(List<Contact>) onFilter;
  final Function() onClose;
  final Function(Contact c) onOpenComments;
  final Function(Contact c) onOpenHolderMap;
  String filter = '';

  ClusterListTopBar(
    this.contacts, {
    Key key,
    this.onFilter,
    this.onClose,
    this.onOpenComments,
    this.onOpenHolderMap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TopBar(
      titleWidget: Container(
        padding: EdgeInsets.only(top: 6.0),
        decoration: BoxDecoration(
          border: Border(
            bottom:
                BorderSide(color: Color(0xFFE2E1DF), style: BorderStyle.solid),
          ),
        ),
        child: TextField(
            style: _Styles.searchFieldText,
            decoration: InputDecoration(
                hintText: I18N.clusterList_placeholder,
                hintStyle: _Styles.searchFieldHint,
                border: InputBorder.none,
                contentPadding: EdgeInsets.fromLTRB(.0, 2.0, .0, 2.0)),
            onChanged: (filter) {
              this.filter = filter;
              if (onFilter != null) {
                final data = contacts
                    .where((c) => filter.isEmpty || c.matchesQuery(filter))
                    .toList();
                onFilter(data);
              }
            }),
      ),
      leftAction: TopBarAction.cancel(onClose),
      rightAction: TopBarAction(
          icon: Icons.people,
          onPress: () {
            final holders = contacts
                .where((c) =>
                    c is ContactHolder &&
                    (filter.isEmpty || c.matchesQuery(filter)))
                .toList()
                .cast<ContactHolder>();
            Navigator.of(context)
                .push(AppRouteTransitions.none((_) => CommonContactsScreen(
                      holders,
                      onOpenComments: onOpenComments,
                      onOpenHolderMap: onOpenHolderMap,
                    )));
          }),
    );
  }

  @override
  Size get preferredSize => Size(double.infinity, 58.0);
}

class ClusterListBody extends StatelessWidget {
  final List<Contact> contacts;
  final Function(LatLng ll) onOpenLocation;
  final Function(Contact c) onTwiceSearchTap;
  final Function(Contact c) onOpenComments;
  final Function(Contact c) onOpenContactOptions;
  final Function(Contact c) onOpenHolderMap;

  const ClusterListBody({
    Key key,
    this.contacts,
    this.onOpenLocation,
    this.onTwiceSearchTap,
    this.onOpenComments,
    this.onOpenContactOptions,
    this.onOpenHolderMap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (contacts.isEmpty)
      return BackPrint(
          icon: Icons.search,
          message: I18N.clusterList_noContactsFoundForQueryError);

    return Material(
      color: AppColors.lightBg,
      child: ListView.builder(
          key: PageStorageKey('clusterListView-${contacts.last.id}'),
          itemCount: contacts.length,
          itemBuilder: (_, index) {
            final contact = contacts[index];
            return ContactListItem(
              contact: contact,
              onOpenLocation: (ll) => onOpenLocation(ll),
              onSearchTap: onTwiceSearchTap != null
                  ? () => onTwiceSearchTap(contact)
                  : null,
              onOpenComments:
                  onOpenComments != null ? () => onOpenComments(contact) : null,
              onOpenContactOptions: onOpenContactOptions != null
                  ? () => onOpenContactOptions(contact)
                  : null,
              onOpenHolderMap: onOpenHolderMap != null
                  ? () => onOpenHolderMap(contact)
                  : null,
            );
          }),
    );
  }
}

class ClusterListScreen extends StatefulWidget {
  final List<Contact> contacts;
  final Function(LatLng ll) onOpenLocation;
  final Function(Contact c) onSearchTap;
  final Function(Contact c) onOpenComments;
  final Function(Contact c) onOpenContactOptions;
  final Function(Contact c) onOpenHolderMap;

  ClusterListScreen(
    this.contacts, {
    this.onOpenLocation,
    this.onSearchTap,
    this.onOpenComments,
    this.onOpenContactOptions,
    this.onOpenHolderMap,
  });

  @override
  _ClusterListScreenState createState() {
    return new _ClusterListScreenState();
  }
}

class _ClusterListScreenState extends State<ClusterListScreen> {
  List<Contact> __contacts;

  List<Contact> get contacts => __contacts ?? widget.contacts;
  set contacts(List<Contact> c) => __contacts = c;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColors.lightBg,
        appBar: _buildAppBar(context),
        body: _buildList(context));
  }

  _buildAppBar(BuildContext context) => ClusterListTopBar(
        contacts,
        onFilter: (contacts) => this.setState(() => this.contacts = contacts),
        onClose: () => Navigator.of(context).pop(),
        onOpenComments: widget.onOpenComments != null
            ? (contact) {
                Navigator.pop(context);
                widget.onOpenComments(contact);
              }
            : null,
        onOpenHolderMap: widget.onOpenHolderMap != null
            ? (contact) {
                Navigator.pop(context);
                widget.onOpenHolderMap(contact);
              }
            : null,
      );

  _buildList(BuildContext context) => ClusterListBody(
        contacts: widget.contacts,
        onOpenLocation: (ll) {
          Navigator.pop(context);
          widget.onOpenLocation(ll);
        },
        onTwiceSearchTap: widget.onSearchTap != null
            ? (contact) {
                Navigator.pop(context);
                widget.onSearchTap(contact);
              }
            : null,
        onOpenComments: widget.onOpenComments != null
            ? (contact) {
                Navigator.pop(context);
                widget.onOpenComments(contact);
              }
            : null,
        onOpenContactOptions: widget.onOpenContactOptions != null
            ? (contact) {
                Navigator.pop(context);
                widget.onOpenContactOptions(contact);
              }
            : null,
        onOpenHolderMap: widget.onOpenHolderMap != null
            ? (contact) {
                Navigator.pop(context);
                widget.onOpenHolderMap(contact);
              }
            : null,
      );
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
