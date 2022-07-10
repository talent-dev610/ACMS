/*
 * @author Oleg Khalidov <brooth@gmail.com>.
 * -----------------------------------------------
 * Freelance software development:
 * Upwork: https://www.upwork.com/fl/khalidovoleg
 * Freelancer: https://www.freelancer.com/u/brooth
 */

import 'dart:async';

import 'package:acms/api/api.dart';
import 'package:acms/models/auth.models.dart';
import 'package:acms/models/domain.models.dart';
import 'package:latlong/latlong.dart';

class DomainApi {
  final ApiClient client;

  DomainApi(this.client);

  Future<Map<String, List<String>>> findCommonContacts(
      Session session, List<String> ids) async {
    final params = {'ids': ids.join(',')};
    final data = await this
        .client
        .callApi('/contacts/common', session: session, params: params);
    final result = Map<String, List<String>>();
    (data['results'] as Map<String, dynamic>).forEach((k, v) {
      result[k] = (v as List).cast<String>();
    });
    return result;
  }

  Future<List<UserContact>> loadUserContacts(
      Session session, int since, int limit) async {
    final params = <String, String>{
      'since': since.toString(),
      'limit': limit.toString()
    };
    final json =
        await client.callApi('/contacts', params: params, session: session);
    return (json['results'] as List)
        .map((j) => UserContact.fromJson(UserContactSource.REMOTE, j))
        .toList();
  }

  Future<List<SyncOperationResult>> syncContacts(
      Session session, List<SyncContact> items) async {
    final body = {'items': items.map((i) => i.toJson()).toList()};
    final json = await client.callApi('/contacts',
        method: ApiMethod.PATCH, body: body, session: session);
    return (json['results'] as List)
        .map((j) => SyncOperationResult.fromJson(j))
        .toList();
  }

  Future<List<Contact>> locateContacts(Session session, MapBounds bounds,
      {String holderId, List<String> queries}) async {
    final params = {
      'northWestLatitude': bounds.northWest.latitude.toString(),
      'northWestLongitude': bounds.northWest.longitude.toString(),
      'southEastLatitude': bounds.southEast.latitude.toString(),
      'southEastLongitude': bounds.southEast.longitude.toString(),
    };
    if (holderId != null) params['holderId'] = holderId;
    if (queries != null) params['query'] = queries.join('|');
    final json =
        await client.callApi('/contacts', params: params, session: session);
    return (json['results'] as List)
        .map((j) => j['noc'] != null
            ? ContactHolder.fromJson(j)
            : j['h'] != null
                ? PublicContact.fromJson(j)
                : VipContact.fromJson(j))
        .cast<Contact>()
        .toList();
  }

  Future<int> addContactNote(
      Session session, String contactId, String text) async {
    final body = {'contactId': contactId, 'text': text};
    final json = await client.callApi('/contact_notes',
        method: ApiMethod.POST, body: body, session: session);
    return json['updateTs'];
  }

  Future<int> changeLike(Session session, String contactId, bool value) async {
    final body = {'contactId': contactId, 'value': value};
    final json = await client.callApi('/contact_likes',
        method: ApiMethod.PATCH, body: body, session: session);
    return json['updateTs'];
  }

  Future<int> changePublic(Session session, String contactId, bool value,
      {List<String> restrictTo}) async {
    final Map<String, dynamic> body = {'public': value};
    if (restrictTo != null) body['restrictTo'] = restrictTo;

    final json = await client.callApi('/contacts/public/$contactId',
        method: ApiMethod.PATCH, body: body, session: session);
    return json['updateTs'];
  }

  Future<List<Contact>> searchContacts(
      Session session, List<String> queries) async {
    final params = {'query': queries.join('|')};
    final json =
        await client.callApi('/contacts', params: params, session: session);
    return (json['results'] as List)
        .map((j) => j['noc'] != null
            ? ContactHolder.fromJson(j)
            : j['h'] != null
                ? PublicContact.fromJson(j)
                : VipContact.fromJson(j))
        .cast<Contact>()
        .toList();
  }

  Future<List<BlackListContact>> loadDislikeContacts(Session session) async {
    final json = await client.callApi('/contacts/dislike', session: session);
    return (json['results'] as List)
        .map((j) => BlackListContact.fromJson(j))
        .toList();
  }

  Future<Location> lookupLocation(LatLng ll) async {
    final params = {
      'latitude': ll.latitude.toString(),
      'longitude': ll.longitude.toString(),
    };
    final json = await client.callApi('/locations', params: params);
    return Location.fromJson(json);
  }

  Future<int> saveManualPhoneLocation(
      Session session, List<ContactPhone> phones) async {
    final body = {
      'phones': phones
          .map((p) => {
                'id': p.id,
                'c': p.country,
                'cc': p.countryCode,
                'l': p.locality,
                'lt': p.latitude,
                'ln': p.longitude,
                'vl': p.valid,
              })
          .toList()
    };
    final json = await client.callApi('/contact_phones',
        method: ApiMethod.PATCH, body: body, session: session);
    return json['updateTs'];
  }

  Future<String> saveContactComment(
      Session session, String contactId, String text) async {
    final body = {'contactId': contactId, 'text': text};
    final json = await client.callApi('/contact_comments/',
        method: ApiMethod.POST, body: body, session: session);
    return json['id'];
  }

  Future<List<IdName>> loadHolders(Session session) async {
    final json = await client.callApi('/contacts/holders',
        method: ApiMethod.GET, session: session);
    return (json['results'] as List).map((j) => IdName.fromJson(j)).toList();
  }

  Future<int> getContactsCount(Session session) async {
    final json = await client.callApi('/contacts/count',
        method: ApiMethod.GET, session: session);
    return json['result'];
  }
}
