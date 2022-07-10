/*
 * @author Oleg Khalidov <brooth@gmail.com>.
 * -----------------------------------------------
 * Freelance software development:
 * Upwork: https://www.upwork.com/fl/khalidovoleg
 * Freelancer: https://www.freelancer.com/u/brooth
 */

import 'package:contacts_service/contacts_service.dart' as cs;
import 'package:latlong/latlong.dart';

class Location {
  final String country;
  final String countryCode;
  final String locality;
  final double latitude;
  final double longitude;

  const Location(this.country, this.countryCode, this.locality, this.latitude,
      this.longitude);

  Location.fromJson(Map<String, dynamic> json)
      : this(
          json['country'],
          json['countryCode'],
          json['locality'],
          (json['latitude'] as num)?.toDouble(),
          (json['longitude'] as num)?.toDouble(),
        );
}

enum UserContactSource { LOCAL, REMOTE, SYNC_CREATE, SYNC_UPDATE }

class UserContact extends Contact {
  UserContactSource source;
  int updateTs;
  final bool deleted;

  UserContact(this.source, this.updateTs, this.deleted, Contact c)
      : super(c.id, c.localId, c.name, c.phones, c.emails, c.notes, c.liked,
            c.public, c.comments);

  UserContact.fromJson(UserContactSource source, Map<String, dynamic> json)
      : this(source, json['uts'], json['d'] ?? false, Contact.fromJson(json));

  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['uts'] = updateTs;
    json['d'] = deleted;
    return json;
  }

  UserContact copyWith({
    String id,
    String name,
    List<ContactPhone> phones,
    List<ContactEmail> emails,
    List<ContactNote> notes,
    bool liked,
    bool public,
    int updateTs,
  }) =>
      UserContact(
          this.source,
          updateTs ?? this.updateTs,
          this.deleted,
          super.copyWith(
            id: id,
            name: name,
            phones: phones,
            emails: emails,
            notes: notes,
            liked: liked,
            public: public,
          ));
}

abstract class SharedContact extends Contact {
  final Contact holder;

  SharedContact(this.holder, Contact c)
      : super(c.id, c.localId, c.name, c.phones, c.emails, c.notes, c.liked,
            c.public, c.comments);

  SharedContact.fromJson(Map<String, dynamic> json)
      : holder = ContactHolder.fromJson(json['h']),
        super.fromJson(json);
}

class PublicContact extends SharedContact {
  PublicContact(Contact holder, Contact c) : super(holder, c);
  PublicContact.fromJson(Map<String, dynamic> json) : super.fromJson(json);
}

class BlackListContact extends SharedContact {
  BlackListContact(Contact holder, Contact c) : super(holder, c);
  BlackListContact.fromJson(Map<String, dynamic> json) : super.fromJson(json);
}

class VipContact extends Contact {
  VipContact(Contact c)
      : super(c.id, c.localId, c.name, c.phones, c.emails, c.notes, c.liked,
            c.public, c.comments);

  VipContact.fromJson(Map<String, dynamic> json) : super.fromJson(json);
}

class MapBounds {
  final LatLng southEast;
  final LatLng northWest;

  const MapBounds(this.southEast, this.northWest);

  MapBounds.max() : this(LatLng(90.0, -180.0), LatLng(-90.0, 180.0));
}

enum SyncContactOperation { CREATE, UPDATE, DELETE }

class SyncContact {
  final SyncContactOperation operation;
  final Contact contact;

  const SyncContact(this.operation, this.contact);

  Map<String, dynamic> toJson() {
    var json = contact.toJson();
    json['o'] = operation.toString().substring('SyncContactOperation.'.length);
    // 'o': operation.toString().substring('SyncContactOperation.'.length),
    // 'c': contact.toJson(),
    return json;
  }
}

class SyncOperationResult {
  final SyncContactOperation operation;
  final UserContact contact;

  const SyncOperationResult(this.operation, this.contact);

  static SyncOperationResult fromJson(Map<String, dynamic> json) {
    final operation = SyncContactOperation.values.firstWhere(
        (i) => i.toString() == 'SyncContactOperation.${json["operation"]}');
    final source = operation == SyncContactOperation.CREATE
        ? UserContactSource.SYNC_CREATE
        : UserContactSource.SYNC_UPDATE;
    return new SyncOperationResult(
      operation,
      json['contact'] != null
          ? UserContact.fromJson(source, json['contact'])
          : null,
    );
  }
}

class Contact {
  final String id;
  String localId;
  final String name;
  final List<ContactPhone> phones;
  final List<ContactEmail> emails;
  final List<ContactNote> notes;
  bool liked;
  bool public;
  final List<ContactComment> comments;

  Contact(
    this.id,
    this.localId,
    this.name,
    this.phones,
    this.emails,
    this.notes,
    this.liked,
    this.public,
    this.comments,
  );

  Contact.fromPhoneContact(cs.Contact contact)
      : this(
          null,
          contact.identifier,
          contact.displayName,
          contact.phones
              .map((i) => ContactPhone(null, i.label, i.value))
              .toList(),
          contact.emails.map((i) => ContactEmail(i.label, i.value)).toList(),
          [],
          null,
          false,
          null,
        );

  Contact copyWith({
    String id,
    String name,
    List<ContactPhone> phones,
    List<ContactEmail> emails,
    List<ContactNote> notes,
    bool liked,
    bool public,
  }) =>
      Contact(
        id ?? this.id,
        this.localId,
        name ?? this.name,
        phones ?? this.phones,
        emails ?? this.emails,
        notes ?? this.notes,
        liked ?? this.liked,
        public ?? this.public,
        comments,
      );

  Contact.fromJson(Map<String, dynamic> json)
      : this(
          json['id'],
          json['lid'],
          json['n'],
          (json['ps'] as List ?? [])
              .map((i) => ContactPhone.fromJson(i))
              .toList(),
          (json['es'] as List ?? [])
              .map((i) => ContactEmail.fromJson(i))
              .toList(),
          (json['ns'] as List ?? [])
              .map((i) => ContactNote.fromJson(i))
              .toList(),
          json['lk'],
          (json['p'] == 1 ? true : false) ?? false,
          (json['cc'] as List ?? [])
              .map((i) => ContactComment.fromJson(i))
              .toList(),
        );

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'n': name,
    };
    if (localId != null) json['lid'] = localId;
    if (phones != null) json['ps'] = phones.map((i) => i.toJson()).toList();
    if (emails != null) json['es'] = emails.map((i) => i.toJson()).toList();
    if (notes != null) json['ns'] = notes.map((i) => i.toJson()).toList();
    if (liked != null) json['lk'] = liked;
    if (public != null) json['p'] = public;
    return json;
  }

  bool isEqual(Contact o) => !isNotEqual(o);

  bool isNotEqual(Contact o) =>
      this.name != o.name ||
      o.phones.firstWhere(
              (p) =>
                  this.phones.firstWhere((p2) => p.value == p2.value,
                      orElse: () => null) ==
                  null,
              orElse: () => null) !=
          null ||
      o.emails.firstWhere(
              (e) =>
                  this.emails.firstWhere((e2) => e.value == e2.value,
                      orElse: () => null) ==
                  null,
              orElse: () => null) !=
          null;

  bool matchesQuery(String q) {
    if (name.toLowerCase().contains(q)) return true;
    for (int i = 0; i < phones.length; i++) {
      final p = phones[i];
      if (p.value.contains(q)) return true;
      if (p.country != null && p.country.toLowerCase().contains(q)) return true;
      if (p.locality != null && p.locality.toLowerCase().contains(q))
        return true;
      if (p.gsresults != null && p.gsresults.length > 0) {
        for (int j = 0; j < p.gsresults.length; j++) {
          final gsr = p.gsresults[j];
          if (gsr.uri.toLowerCase().contains(q) ||
              gsr.title.toLowerCase().contains(q) ||
              gsr.description.toLowerCase().contains(q)) return true;
        }
      }
    }
    if (emails.map((i) => i.value).join().contains(q)) return true;
    if (notes.map((i) => i.text.toLowerCase()).join().contains(q)) return true;
    return false;
  }

  List<String> getSearchables() {
    final searchables = <String>[name];
    searchables.addAll(phones.map((p) => p.value));
    searchables.addAll(emails.map((e) => e.value));
    searchables.addAll(notes.map((n) => n.text));
    return searchables;
  }

  int compareTo(Contact c2) {
    final w1 = this is VipContact
        ? 5
        : this is ContactHolder
            ? 4
            : this is SharedContact
                ? 3
                : this.liked == true
                    ? 2
                    : this.notes.isNotEmpty
                        ? 1
                        : 0;
    final w2 = c2 is VipContact
        ? 5
        : c2 is ContactHolder
            ? 4
            : c2 is SharedContact
                ? 3
                : c2.liked == true
                    ? 2
                    : c2.notes.isNotEmpty
                        ? 1
                        : 0;
    if (w1 == w2) {
      if ((this.comments ?? []).isNotEmpty || (c2.comments ?? []).isNotEmpty)
        return (c2.comments ?? []).length - (this.comments ?? []).length;
      return c2.notes.length - this.notes.length;
    }
    return w2 - w1;
  }
}

class GSearchResult {
  final int rank;
  final String uri;
  final String title;
  final String description;

  GSearchResult(this.rank, this.uri, this.title, this.description);

  GSearchResult.fromJson(Map<String, dynamic> json)
      : this(json['r'], json['u'], json['t'], json['d']);

  Map<String, dynamic> toJson() => {
        'r': rank,
        'u': uri,
        't': title,
        'd': description,
      };
}

class ContactPhone {
  final String id;
  final String label;
  final String value;
  String rawValue; // used as temporary storage to remove unwanted symbols from phone number
  final bool valid;
  final String country;
  final String countryCode;
  final String locality;
  final double latitude;
  final double longitude;
  final List<GSearchResult> gsresults;

  ContactPhone(
    this.id,
    this.label,
    this.rawValue, [
    this.valid,
    this.country,
    this.countryCode,
    this.locality,
    this.latitude,
    this.longitude,
    this.gsresults,
  ])
    : value = rawValue.replaceAll(new RegExp(r'-|\s|\(|\)'), '');

  ContactPhone.fromJson(Map<String, dynamic> json)
      : this(
          json['id'],
          json['l'],
          json['v'],
          json['vl'],
          json['c'],
          json['cc'],
          json['lc'],
          (json['lt'] as num)?.toDouble(),
          (json['ln'] as num)?.toDouble(),
          (json['gsr'] as List ?? [])
              .map((i) => GSearchResult.fromJson(i))
              .toList(),
        );

  String get fullLocality => country + ', ' + locality;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {'id': id, 'l': label, 'v': value};
    if (valid != null) json['vl'] = valid;
    if (country != null) json['c'] = country;
    if (countryCode != null) json['cc'] = countryCode;
    if (locality != null) json['lc'] = locality;
    if (latitude != null) json['lt'] = latitude;
    if (longitude != null) json['ln'] = longitude;
    if (gsresults != null)
      json['gsr'] = gsresults.map((i) => i.toJson()).toList();
    return json;
  }

  ContactPhone copyWith({
    bool valid,
    String country,
    String countryCode,
    String locality,
    double latitude,
    double longitude,
  }) =>
      ContactPhone(
        this.id,
        this.label,
        this.value,
        valid ?? this.valid,
        country ?? this.country,
        countryCode ?? this.countryCode,
        locality ?? this.locality,
        latitude ?? this.latitude,
        longitude ?? this.longitude,
      );

  bool fitsBounds(MapBounds b) =>
      latitude != null &&
      longitude != null &&
      latitude <= b.southEast.latitude &&
      latitude >= b.northWest.latitude &&
      longitude >= b.southEast.longitude &&
      longitude <= b.northWest.longitude;
}

class ContactEmail {
  final String label;
  final String value;

  const ContactEmail(this.label, this.value);

  ContactEmail.fromJson(Map<String, dynamic> json)
      : this(
          json['l'],
          json['v'],
        );

  Map<String, dynamic> toJson() => {
        'l': label,
        'v': value,
      };
}

class ContactNote {
  final DateTime createdAt;
  final String text;
  final Contact author;

  ContactNote(this.createdAt, this.text, this.author);

  ContactNote.fromJson(Map<String, dynamic> json)
      : this(
          DateTime.fromMillisecondsSinceEpoch(json['ca']),
          json['t'],
          json['a'] != null ? Contact.fromJson(json['a']) : null,
        );

  Map<String, dynamic> toJson() => {
        'ca': createdAt.millisecondsSinceEpoch,
        't': text,
        'a': author?.toJson(),
      };
}

class ContactComment {
  final DateTime createdAt;
  final String text;

  ContactComment(this.createdAt, this.text);

  ContactComment.fromJson(Map<String, dynamic> json)
      : this(
          DateTime.fromMillisecondsSinceEpoch(json['ca']),
          json['t'],
        );

  Map<String, dynamic> toJson() => {
        'ca': createdAt.millisecondsSinceEpoch,
        't': text,
      };
}

class ContactHolder extends Contact {
  final double centerLatitude;
  final double centerLongitude;
  final int numberOfContacts;
  final String country;
  final String locality;
  final List<String> contacts;

  ContactHolder(
    String id,
    String localId,
    String name,
    List<ContactPhone> phones,
    List<ContactEmail> emails,
    List<ContactNote> notes,
    bool liked,
    List<ContactComment> comments,
    this.centerLatitude,
    this.centerLongitude,
    this.numberOfContacts,
    this.country,
    this.locality,
    this.contacts,
  ) : super(id, localId, name, phones, emails, notes, liked, false, comments);

  factory ContactHolder.fromJson(Map<String, dynamic> json) {
    final c = Contact.fromJson(json);
    return ContactHolder(
      c.id,
      c.localId,
      c.name,
      c.phones,
      c.emails,
      c.notes,
      c.liked,
      c.comments,
      (json['clt'] as num)?.toDouble(),
      (json['cln'] as num)?.toDouble(),
      json['noc'],
      json['cn'],
      json['lc'],
      json['cs'] != null ? (json['cs'] as List).cast<String>() : [],
    );
  }

  ContactHolder copyWith({
    String id,
    String name,
    List<ContactPhone> phones,
    List<ContactEmail> emails,
    List<ContactNote> notes,
    bool liked,
    bool public,
  }) =>
      ContactHolder(
        id ?? this.id,
        this.localId,
        name ?? this.name,
        phones ?? this.phones,
        emails ?? this.emails,
        notes ?? this.notes,
        liked ?? this.liked,
        this.comments,
        this.centerLatitude,
        this.centerLongitude,
        this.numberOfContacts,
        this.country,
        this.locality,
        this.contacts,
      );

  String get fullLocality => country + ', ' + locality;
}

class IdName {
  final String id;
  final String name;

  IdName(this.id, this.name);

  IdName.fromJson(Map<String, dynamic> json) : this(json['id'], json['name']);
}
