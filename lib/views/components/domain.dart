/*
 * @author Oleg Khalidov <brooth@gmail.com>.
 * -----------------------------------------------
 * Freelance software development:
 * Upwork: https://www.upwork.com/fl/khalidovoleg
 * Freelancer: https://www.freelancer.com/u/brooth
 */

import 'dart:async';
import 'dart:collection';
import 'dart:math' as Math;

import 'package:acms/c.dart';
import 'package:acms/i18n/i18n.dart';
import 'package:acms/models/auth.models.dart';
import 'package:acms/models/domain.models.dart';
import 'package:acms/store/app.store.dart';
import 'package:acms/views/components/base.dart';
import 'package:acms/views/screens/main/cluster_list.screen.dart';
import 'package:acms/views/screens/main/gsearch_results.dart';
import 'package:acms/views/screens/main/search_map.screen.dart';
import 'package:acms/views/theme.dart';
import 'package:acms/views/views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:latlong/latlong.dart';
import 'package:rxdart/rxdart.dart';
import 'package:url_launcher/url_launcher.dart';

class ClusterEntry {
  LatLng ll;
  List<Contact> contacts;

  ClusterEntry(this.ll) : contacts = [];

  centrify(LatLng another) {
    if (ll != another) {
      ll = LatLng((ll.latitude + another.latitude) / 2,
          (ll.longitude + another.longitude) / 2);
    }
  }
}

class ContactsMapController {
  final Function() onReady;
  final Function() onCameraChanged;
  final Function() onCameraMove;
  _ContactsMapState _state;

  ContactsMapController(
      {this.onReady, this.onCameraChanged, this.onCameraMove});

  bool get ready => _state != null;

  MapBounds getBounds() {
    if (ready) return _state._getBounds();
    return null;
  }

  void move(LatLng ll, double zoom) {
    if (ready) _state._mapController.move(ll, zoom);
  }

  void fitBounds(LatLngBounds bounds, FitBoundsOptions options) {
    if (ready) _state._mapController.fitBounds(bounds, options: options);
  }
}

enum MapMode { NORMAL, TERRAIN, SATTELITE }

class ContactsMap extends StatefulWidget {
  static MapMode mapMode = DEV_MODE ? MapMode.NORMAL : MapMode.TERRAIN;

  final List<Contact> contacts;
  final ContactsMapController controller;
  final bool colorHolderMarkers;
  final Function(Contact c) onOpenHolderMap;
  final Function(Contact c) onTwiceSearchTap;
  final Function(Contact c) onOpenComments;
  final Function(Contact c) onOpenContactOptions;
  final Function(List<Contact> c) onOpenClusterList;

  const ContactsMap(
    this.contacts, {
    Key key,
    this.controller,
    this.onOpenHolderMap,
    this.colorHolderMarkers = true,
    this.onTwiceSearchTap,
    this.onOpenComments,
    this.onOpenContactOptions,
    this.onOpenClusterList,
  }) : super(key: key);

  @override
  _ContactsMapState createState() {
    final state = new _ContactsMapState();
    if (controller != null) controller._state = state;
    return state;
  }
}

class _ContactsMapState extends State<ContactsMap> with WidgetStateUtilsMixin {
  static var _mapPosition =
      MapPosition(center: MAP_DEFAULT_CENTER, zoom: MAP_DEFAULT_ZOOM);

  final _mapController = MapController();
  final crs = const Epsg3857();
  final _mapPotitionChanged$ = PublishSubject<MapPosition>();

  List<Marker> _markers;

  @override
  void initState() {
    _mapController.onReady.then((_) {
      _updateMarkers();
      if (widget.controller?.onReady != null) widget.controller.onReady();
    });

    this.subscriptions.addAll([
      _mapPotitionChanged$
          .debounce(Duration(milliseconds: 500))
          .where((_) => _mapController.ready)
          .concatMap((position) => _buildMarkers().asStream())
          .listen((markers) => setState(() => this._markers = markers)),
      _mapPotitionChanged$
          .where((_) => widget.controller?.onCameraChanged != null)
          .debounce(Duration(milliseconds: 1500))
          .distinct((p, n) =>
              p.zoom - n.zoom < .5 &&
              (p.center.latitude - n.center.latitude).abs() /
                      p.center.latitude *
                      100 <
                  10 &&
              (p.center.longitude - n.center.longitude).abs() /
                      p.center.longitude *
                      100 <
                  10)
          .listen((_) => widget.controller.onCameraChanged()),
    ]);

    super.initState();
  }

  @override
  void dispose() {
    _mapPotitionChanged$.close();
    super.dispose();
  }

  @override
  void didUpdateWidget(ContactsMap oldWidget) {
    _updateMarkers();
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    List<LayerOptions> layers = [
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
    ];
    if (ContactsMap.mapMode == MapMode.SATTELITE)
      layers.add(
        TileLayerOptions(
          urlTemplate: 'http://{host}:{port}/map_tiles/{x}/{y}/{z}?type=labels',
          additionalOptions: {
            'host': BACKEND_HOST,
            'port': BACKEND_PORT.toString(),
          },
          backgroundColor: Colors.transparent,
        ),
      );
    layers.add(MarkerLayerOptions(markers: _markers ?? []));

    return Stack(
      children: <Widget>[
        FlutterMap(
            mapController: _mapController,
            options: MapOptions(
                crs: crs,
                center: _mapPosition.center,
                zoom: _mapPosition.zoom,
                onPositionChanged: (p) {
                  _mapPosition = p;
                  if (!_mapPotitionChanged$.isClosed)
                    _mapPotitionChanged$.add(p);
                  if (widget.controller?.onCameraMove != null)
                    widget.controller.onCameraMove();
                }),
            layers: layers),
        Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            child: Container(
              margin: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 1.5,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withAlpha(60),
                    offset: Offset(2.5, 2.5),
                    blurRadius: 8.0,
                  ),
                ],
              ),
              child: Image.asset(
                ContactsMap.mapMode == MapMode.NORMAL
                    ? 'assets/images/map_sattelite.png'
                    : ContactsMap.mapMode == MapMode.TERRAIN
                        ? 'assets/images/map_normal.png'
                        : 'assets/images/map_terrain.png',
                width: 25.0,
                height: 25.0,
              ),
            ),
            onTap: () => setState(
                  () => ContactsMap.mapMode =
                      ContactsMap.mapMode == MapMode.NORMAL
                          ? MapMode.SATTELITE
                          : ContactsMap.mapMode == MapMode.TERRAIN
                              ? MapMode.NORMAL
                              : MapMode.TERRAIN,
                ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(2.0),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Image.asset('assets/images/google_logo.png', width: 55.0),
          ),
        ),
      ],
    );
  }

  void _updateMarkers() =>
      _buildMarkers().then((markers) => setState(() => _markers = markers));

  Future<List<Marker>> _buildMarkers() async {
    final bounds = _getBounds();
    if (bounds?.southEast == null || bounds.northWest == null) return [];

    final allContacts = List<MapEntry<LatLng, Contact>>();
    widget.contacts.forEach((contact) {
      if (contact is ContactHolder) {
        if (contact.centerLatitude <= bounds.southEast.latitude &&
            contact.centerLatitude >= bounds.northWest.latitude &&
            contact.centerLongitude >= bounds.southEast.longitude &&
            contact.centerLongitude <= bounds.northWest.longitude)
          allContacts.add(MapEntry(
              LatLng(contact.centerLatitude, contact.centerLongitude),
              contact));
      } else {
        final localityPhones = <String, List<ContactPhone>>{};
        contact.phones
            .where((phone) => phone.fitsBounds(bounds))
            .forEach((phone) {
          if (!localityPhones.containsKey(phone.fullLocality))
            localityPhones[phone.fullLocality] = [];
          localityPhones[phone.fullLocality].add(phone);
        });
        localityPhones.forEach((locality, phones) {
          final copy = contact.copyWith(phones: phones);
          allContacts.add(MapEntry(
              LatLng(phones.first.latitude, phones.first.longitude),
              contact is UserContact
                  ? UserContact(
                      contact.source, contact.updateTs, contact.deleted, copy)
                  : contact is PublicContact
                      ? PublicContact(contact.holder, copy)
                      : copy));
        });
      }
    });

    final clusters = List<ClusterEntry>();
    allContacts.forEach((entry) {
      final cluster = clusters.firstWhere((cluster) {
        final margin = 50;
        final zoom = _mapController.zoom;
        final clusterPoint = crs.latLngToPoint(cluster.ll, zoom);
        final contactPoint = crs.latLngToPoint(entry.key, zoom);
        return clusterPoint.x - margin < contactPoint.x &&
            clusterPoint.x + margin > contactPoint.x &&
            clusterPoint.y - margin < contactPoint.y &&
            clusterPoint.y + margin > contactPoint.y;
      }, orElse: () {
        final e = ClusterEntry(entry.key);
        clusters.add(e);
        return e;
      });
      cluster.contacts.add(entry.value);
      cluster.centrify(entry.key);
    });

    final remove = List<ClusterEntry>();
    clusters.forEach((entry) {
      final cluster = clusters.firstWhere((cluster) {
        if (entry == cluster || remove.contains(cluster)) return false;
        final margin = 50;
        final zoom = _mapController.zoom;
        final clusterPoint = crs.latLngToPoint(cluster.ll, zoom);
        final contactPoint = crs.latLngToPoint(entry.ll, zoom);
        return clusterPoint.x - margin < contactPoint.x &&
            clusterPoint.x + margin > contactPoint.x &&
            clusterPoint.y - margin < contactPoint.y &&
            clusterPoint.y + margin > contactPoint.y;
      }, orElse: () => null);
      if (cluster != null) {
        cluster.contacts.addAll(entry.contacts);
        cluster.centrify(entry.ll);
        remove.add(entry);
      }
    });
    return clusters
        .where((cluster) => !remove.contains(cluster))
        .map((cluster) {
      if (cluster.contacts.length > 1) {
        cluster.contacts.sort((c1, c2) => c1.compareTo(c2));
        return _buildClusterMarker(cluster.ll, cluster.contacts);
      }
      return _buildContactMarker(cluster.ll, cluster.contacts[0]);
    }).toList();
  }

  Marker _buildClusterMarker(LatLng ll, List<Contact> contacts) {
    int count = 0;
    contacts.forEach((c) {
      if (c is ContactHolder)
        count += c.numberOfContacts;
      else
        count++;
    });
    final text = count > 999 ? '999+' : count.toString();
    return Marker(
      width: 42.0,
      height: 100.0,
      point: ll,
      builder: (ctx) => GestureDetector(
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppPalette.primaryColor,
                border: Border.all(
                  color: Colors.white,
                  width: 1.5,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withAlpha(60),
                    offset: Offset(-1.5, 17.0),
                    blurRadius: 10.0,
                  ),
                ],
              ),
              child: Text(text, style: _Styles.clusterText, softWrap: false),
            ),
            onTap: () {
              if (widget.onOpenClusterList != null) {
                widget.onOpenClusterList(contacts);
              } else {
                Navigator.push(
                    context,
                    AppRouteTransitions.none((_) => ClusterListScreen(
                          contacts,
                          onOpenLocation: _openLocation,
                          onSearchTap: widget.onTwiceSearchTap,
                          onOpenComments: widget.onOpenComments,
                          onOpenContactOptions: widget.onOpenContactOptions,
                          onOpenHolderMap: widget.onOpenHolderMap,
                        )));
              }
            },
          ),
    );
  }

  Marker _buildContactMarker(LatLng ll, Contact contact) {
    final isPublic = contact is PublicContact;
    final isHolder = !isPublic && contact is ContactHolder;
    final isVip = isHolder || contact is VipContact;
    return Marker(
      point: ll,
      builder: (ctx) => GestureDetector(
            child: Stack(
              children: <Widget>[
                Container(
                  width: 25.0,
                  height: 25.0,
                  margin: EdgeInsets.fromLTRB(5.0, 3.0, .0, .0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: contact.public ? Color(0xffbee8ff) : Colors.white,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withAlpha(60),
                        offset: Offset(-1.5, 17.0),
                        blurRadius: 10.0,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.person_pin,
                  color: isVip && widget.colorHolderMarkers
                      ? Color(0xffe8308c)
                      : isPublic ? AppColors.darkBg : Color(0xff646464),
                  size: 34.0,
                ),
              ],
            ),
            onTap: () => showModalBottomSheet(
                context: context,
                builder: (_) => ContactInfoPanel(
                      contact,
                      onOpenLocation: _openLocation,
                      onOpenHolderMap: widget.onOpenHolderMap != null
                          ? () => widget.onOpenHolderMap(contact)
                          : null,
                      onOpenComments: widget.onOpenComments != null
                          ? () => widget.onOpenComments(contact)
                          : null,
                      onOpenContactOptions: widget.onOpenContactOptions != null
                          ? () => widget.onOpenContactOptions(contact)
                          : null,
                    )),
          ),
    );
  }

  MapBounds _getBounds() {
    final size = MediaQuery.of(context).size;
    final margin = Math.max(size.width, size.height);
    final zoom = _mapController.zoom;
    final cp = crs.latLngToPoint(_mapController.center, zoom);
    final sw = crs.pointToLatLng(Point(cp.x - margin, cp.y - margin), zoom);
    final nw = crs.pointToLatLng(Point(cp.x + margin, cp.y + margin), zoom);
    return MapBounds(sw ?? LatLng(90.0, -180.0), nw ?? LatLng(-90.0, 180.0));
  }

  void _openLocation(LatLng ll) => _mapController.move(ll, 10.0);
}

class ContactInfoPanel extends StatelessWidget {
  final Contact contact;
  final Function(LatLng ll) onOpenLocation;
  final Function(int numberOfContacts) holderHint;
  final Function() onOpenContactOptions;
  final Function() onOpenHolderMap;
  final Function() onOpenComments;

  const ContactInfoPanel(
    this.contact, {
    this.onOpenLocation,
    this.holderHint,
    this.onOpenHolderMap,
    this.onOpenComments,
    this.onOpenContactOptions,
  });

  @override
  Widget build(BuildContext context) {
    final isPublic = contact is PublicContact;
    final isHolder = !isPublic && contact is ContactHolder;
    final isVip = isHolder || contact is VipContact;
    final hasGSResults = contact.phones
            .indexWhere((p) => p.gsresults != null && p.gsresults.isNotEmpty) !=
        -1;

    return GestureDetector(
      onTap: () => null,
      child: Material(
        color: AppColors.lightBg,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  SizedBox(width: 10.0, height: 32.0),
                  isVip
                      ? Padding(
                          padding: const EdgeInsets.only(top: 3.0),
                          child: Image.asset(
                            'assets/images/ic__vip.png',
                            alignment: Alignment.centerLeft,
                            width: 21.0,
                            height: 15.0,
                          ),
                        )
                      : isPublic
                          ? Padding(
                              padding: const EdgeInsets.only(right: 4.0),
                              child: Icon(Icons.link,
                                  size: 18.0, color: AppPalette.primaryColor),
                            )
                          : SizedBox(),
                  Expanded(
                    child: RichText(
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(children: <TextSpan>[
                        TextSpan(
                            text: contact.name, style: _Styles.contactName),
                        isHolder
                            ? TextSpan(
                                text: ' ' +
                                    (holderHint ?? I18N.contactHolderAreaHint)(
                                        (contact as ContactHolder)
                                            .numberOfContacts),
                                style: _Styles.contactHint,
                              )
                            : TextSpan(),
                      ]),
                    ),
                  ),
                  hasGSResults
                      ? InkResponse(
                          child: Padding(
                            padding: EdgeInsets.all(7.0),
                            child: Icon(Icons.find_in_page,
                                size: 20.0, color: AppPalette.primaryColor),
                          ),
                          onTap: () => Navigator.push(
                              context,
                              AppRouteTransitions.none(
                                  (_) => GSearchResultsScreen(contact))),
                        )
                      : SizedBox(),
                  isVip && onOpenComments != null
                      ? InkResponse(
                          child: Padding(
                            padding: EdgeInsets.all(7.0),
                            child: Icon(
                              contact.comments != null &&
                                      contact.comments.isNotEmpty
                                  ? Icons.comment
                                  : Icons.add_comment,
                              size: 20.0,
                              color: AppPalette.primaryColor,
                            ),
                          ),
                          onTap: onOpenComments,
                        )
                      : SizedBox(),
                  isVip
                      ? onOpenHolderMap != null
                          ? InkResponse(
                              child: Padding(
                                padding: EdgeInsets.all(7.0),
                                child: Icon(Icons.public,
                                    size: 20.0, color: AppPalette.primaryColor),
                              ),
                              onTap: onOpenHolderMap,
                            )
                          : SizedBox()
                      : (contact is UserContact ||
                                  contact is BlackListContact) &&
                              onOpenContactOptions != null
                          ? InkResponse(
                              child: Padding(
                                padding: EdgeInsets.all(7.0),
                                child: Icon(Icons.settings,
                                    size: 20.0, color: AppPalette.primaryColor),
                              ),
                              onTap: onOpenContactOptions,
                            )
                          : SizedBox(),
                  SizedBox(width: 5.0),
                ],
              ),
              Separator(),
              _buildInfoPanel(context)
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoPanel(BuildContext context) {
    final widgets = <Widget>[];
    if (onOpenHolderMap != null && contact is PublicContact) {
      final holder = (contact as PublicContact).holder;
      widgets.add(InkWell(
          child: Row(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Image.asset(
                  'assets/images/ic__vip.png',
                  alignment: Alignment.centerLeft,
                  width: 21.0,
                  height: 15.0,
                ),
              ),
              SizedBox(width: 4.0, height: 32.0),
              Text(I18N.sharedBy(holder.name),
                  style: _Styles.contactInfo.copyWith(
                    fontFamily: 'NotoSans',
                    fontSize: 14.5,
                  )),
            ],
          ),
          onTap: () => Navigator.push(
              context,
              AppRouteTransitions.standard(
                  (_) => SearchMapScreen(holder: holder)))));
    }
    if (contact is ContactHolder) {
      final holder = contact as ContactHolder;
      if (holder.country != null && holder.locality != null)
        widgets.add(_buildContactAddress(holder.fullLocality,
            LatLng(holder.centerLatitude, holder.centerLongitude)));
    }
    LinkedHashSet<ContactPhone>(
        // remove duplicates (dart way indeed)
        equals: (p1, p2) =>
            p1.country == p2.country && p1.locality == p2.locality,
        hashCode: (p) => 0)
      ..addAll(contact.phones
          .where((phone) => phone.country != null && phone.locality != null))
      ..forEach((phone) => widgets.add(_buildContactAddress(
          phone.fullLocality, LatLng(phone.latitude, phone.longitude))));
    widgets.addAll(contact.phones
        .map(
          (phone) => InkWell(
                child: Row(
                  children: <Widget>[
                    Icon(Icons.phone, color: Colors.grey, size: 18.0),
                    SizedBox(width: 5.0, height: 32.0),
                    Text(phone.value, style: _Styles.contactInfo),
                    SizedBox(width: 5.0),
                    phone.label != null
                        ? Text(phone.label, style: _Styles.contactInfoHint)
                        : SizedBox(),
                  ],
                ),
                onTap: () => launch('tel://' +
                    phone.value
                        .replaceAllMapped(RegExp(r'[^\d\+]'), (_) => '')),
              ),
        )
        .toList());
    widgets.addAll(contact.emails
        .map(
          (email) => InkWell(
                child: Row(
                  children: <Widget>[
                    Icon(Icons.email, color: Colors.grey, size: 17.0),
                    SizedBox(width: 7.0, height: 32.0),
                    Flexible(
                        child: Text(email.value, style: _Styles.contactInfo)),
                  ],
                ),
                onTap: () => launch('mailto:' + email.value),
              ),
        )
        .toList());
    return Container(
      height: Math.min(
          widgets.length * 32.0 + 20.0, MediaQuery.of(context).size.height / 2),
      padding: EdgeInsets.all(10.0),
      child: ListView.builder(
        itemCount: widgets.length,
        itemBuilder: (_, idx) => widgets[idx],
      ),
    );
  }

  InkWell _buildContactAddress(String text, LatLng ll) {
    return InkWell(
        child: Row(
          children: <Widget>[
            Icon(Icons.location_on, color: Colors.grey, size: 18.0),
            SizedBox(width: 5.0, height: 32.0),
            Text(text, style: _Styles.contactInfo),
          ],
        ),
        onTap: () {
          if (onOpenLocation != null) onOpenLocation(ll);
        });
  }
}

class ContactListItem extends StatelessWidget {
  final Contact contact;
  final Function(LatLng ll) onOpenLocation;
  final Function() onTap;
  final Function() onSearchTap;
  final Function() onOpenComments;
  final Function() onOpenContactOptions;
  final Function() onOpenHolderMap;

  const ContactListItem({
    Key key,
    @required this.contact,
    this.onOpenLocation,
    this.onTap,
    this.onSearchTap,
    this.onOpenComments,
    this.onOpenContactOptions,
    this.onOpenHolderMap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, Session>(
      converter: (store) => store.state.authState.loginState.value,
      builder: (_, session) {
        if (session == null) return SizedBox();
        final isPublic = contact is PublicContact;
        final isShared = isPublic || contact is BlackListContact;
        final isHolder = !isPublic && contact is ContactHolder;
        final isVip = isHolder || contact is VipContact;
        final selfNotesCount = contact.notes
            .where((note) =>
                note.author == null || note.author.id == session.user.contacId)
            .length;

        return Container(
            child: ListTile(
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 7.0, vertical: .0),
              title: Row(
                children: <Widget>[
                  isVip
                      ? Padding(
                          padding: const EdgeInsets.only(top: 3.0),
                          child: Image.asset(
                            'assets/images/ic__vip.png',
                            alignment: Alignment.centerLeft,
                            width: 21.0,
                            height: 15.0,
                          ),
                        )
                      : isPublic
                          ? Padding(
                              padding: const EdgeInsets.only(right: 4.0),
                              child: Icon(Icons.link,
                                  size: 18.0, color: AppPalette.primaryColor),
                            )
                          : SizedBox(),
                  Flexible(
                      child:
                          Text(contact.name, style: _Styles.contactItemName)),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 5.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    contact.liked == true
                        ? Padding(
                            padding:
                                const EdgeInsets.fromLTRB(.0, 3.0, 10.0, .0),
                            child: Icon(
                              Icons.thumb_up,
                              size: 15.0,
                              color: AppPalette.secondaryColor,
                            ),
                          )
                        : SizedBox(),
                    selfNotesCount > 0
                        ? Padding(
                            padding: const EdgeInsets.fromLTRB(.0, .0, 6.0, .0),
                            child: Row(
                              children: <Widget>[
                                Icon(
                                  Icons.send,
                                  size: 15.0,
                                  color: AppPalette.secondaryColor,
                                ),
                                Text(selfNotesCount.toString(),
                                    style: _Styles.listItemCounter),
                              ],
                            ),
                          )
                        : SizedBox(),
                    contact.comments != null && contact.comments.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.fromLTRB(.0, .0, 6.0, .0),
                            child: Row(
                              children: <Widget>[
                                Icon(
                                  Icons.mode_edit,
                                  size: 15.0,
                                  color: AppPalette.secondaryColor,
                                ),
                                Text(contact.comments.length.toString(),
                                    style: _Styles.listItemCounter),
                              ],
                            ),
                          )
                        : SizedBox(),
                    Flexible(
                      child: Text(
                          isHolder
                              ? I18N.holderUserSubtitle(
                                  (contact as ContactHolder).numberOfContacts,
                                  (contact as ContactHolder).locality)
                              : isShared
                                  ? I18N.sharedBy(
                                      (contact as SharedContact).holder.name)
                                  : '',
                          style: _Styles.contactItemInfo),
                    ),
                  ],
                ),
              ),
              trailing: onSearchTap != null
                  ? InkResponse(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 3.0),
                        child: Icon(Icons.search,
                            color: Colors.black26, size: 22.0),
                      ),
                      onTap: onSearchTap,
                    )
                  : null,
              onTap: onTap ??
                  () => showModalBottomSheet(
                      context: context,
                      builder: (_) => ContactInfoPanel(
                            contact,
                            onOpenLocation: (ll) {
                              Navigator.of(context).pop();
                              if (onOpenLocation != null) onOpenLocation(ll);
                            },
                            onOpenComments: onOpenComments,
                            onOpenContactOptions: onOpenContactOptions,
                            onOpenHolderMap: onOpenHolderMap,
                          )),
            ),
            decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(
              color: Color(0xffe5e5e5),
            ))));
      },
    );
  }
}

class _Styles {
  static final clusterText = TextStyle(
    fontFamily: 'NotoSans',
    fontSize: 14.0,
    color: Colors.white,
  );
  static final contactName = TextStyle(
    fontFamily: 'NotoSans',
    fontSize: 15.0,
    color: Colors.black87,
  );
  static final contactInfo = TextStyle(
    fontSize: 15.0,
    fontFamily: 'NotoSans',
    color: AppPalette.primaryColor,
  );
  static final contactInfoHint = contactInfo.copyWith(
    color: Colors.grey.withAlpha(130),
    fontStyle: FontStyle.italic,
  );
  static final contactHint = contactName.copyWith(
    fontSize: 14.0,
    color: Colors.grey,
    fontWeight: FontWeight.normal,
  );
  static final contactItemName = contactName;
  static final contactItemInfo = TextStyle(
    fontFamily: 'NotoSans',
    fontSize: 14.0,
    color: Colors.black54,
  );
  static final listItemCounter = TextStyle(
    fontFamily: 'NotoSans',
    fontSize: 14.0,
    color: AppPalette.secondaryColor,
  );
}
