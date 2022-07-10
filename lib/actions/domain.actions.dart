/*
 * @author Oleg Khalidov <brooth@gmail.com>.
 * -----------------------------------------------
 * Freelance software development:
 * Upwork: https://www.upwork.com/fl/khalidovoleg
 * Freelancer: https://www.freelancer.com/u/brooth
 */

import 'dart:async' as Async;
import 'dart:convert';

import 'package:acms/api/api.dart';
import 'package:acms/i18n/i18n.dart';
import 'package:acms/utils/phone_log.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong/latlong.dart';
import 'package:path/path.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:contacts_service/contacts_service.dart' as cs;
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';
import 'package:rxdart/rxdart.dart';

import 'package:acms/actions/actions.dart';
import 'package:acms/models/async.models.dart';
import 'package:acms/models/domain.models.dart';
import 'package:acms/store/app.store.dart';

final permissionHandler = PermissionHandler();

class FindContactsActionProgress {
  final AsyncState<List<Contact>> state;

  FindContactsActionProgress(this.state);
}

class FindContactAction implements AsyncAction {
  final MapBounds bounds;

  FindContactAction(this.bounds);

  @override
  ThunkAction<AppState> execute(api) => (store) async {
        print('LoadContactHoldersAction.execute()');

        final session = store.state.authState.loginState.value;
        if (session == null) return;

        store.dispatch(FindContactsActionProgress(AsyncState.inProgress(
            store.state.domainState.findContactsState.value)));
        try {
          final data = await api.domain.locateContacts(session, bounds);
          store.dispatch(FindContactsActionProgress(AsyncState.success(data)));
        } catch (error) {
          store.dispatch(FindContactsActionProgress(AsyncState.failed(
              error, store.state.domainState.findContactsState.value)));
        }
      };
}

Future _updateSyncContact(Store<AppState> store, UserContact contact) async {
  final session = store.state.authState.loginState.value;
  final state = store.state.domainState.syncUserContactsState;
  if (session != null && state.isSuccessful()) {
    final idx = state.value.indexWhere((c) => c.id == contact.id);
    if (idx >= 0) {
      final newValue = List<UserContact>.from(state.value);
      newValue[idx] = contact;
      store.dispatch(SyncUserContactsStateAction(AsyncState.success(newValue)));
      final db = await getDbConnection(session.user.id);
      await updateContact(db, contact);
    }
  }
}

UserContact _getSyncContact(Store<AppState> store, String id) {
  final state = store.state.domainState.syncUserContactsState;
  if (state.isSuccessful()) {
    final idx = state.value.indexWhere((uc) => uc.id == id);
    if (idx >= 0) {
      return state.value[idx];
    }
  }
  return null;
}

class SyncUserContactsStateAction {
  final AsyncState<List<UserContact>> state;

  SyncUserContactsStateAction(this.state);
}

class SyncUserContactsAction implements AsyncAction {
  @override
  ThunkAction<AppState> execute(api) => (store) {
        print('SyncContactsAction.execute()');

        final session = store.state.authState.loginState.value;
        if (session == null) return;

        final currentState =
            () => store.state.domainState.syncUserContactsState;
        if (currentState().isInProgress()) return;

        store.dispatch(SyncUserContactsStateAction(
            AsyncState.inProgress(currentState().value)));

        Observable.fromFuture(_checkPermission())
            .concatMap((_) {
              return Observable.fromFuture(_loadUserContacts(store, api));
            })
            .flatMap((userContacts) {
              return Observable.fromFuture(_getPhoneContacts())
                  .map((phoneContacts) =>
                  _findSyncs(userContacts, phoneContacts))
                  .flatMap((syncItems) {
                if (syncItems.isEmpty) return Observable.just(userContacts);

                return Observable.fromIterable(syncItems)
                    .bufferCount(100)
                    .concatMap((batch) =>
                    api.domain.syncContacts(session, batch).asStream())
                    .flatMap((results) =>
                    _handleSyncResponse(store, results).asStream())
                    .last
                    .asObservable()
                // MapTab -> onDidChange fires 2 times w/out this delay
                    .delay(Duration(milliseconds: 200));
              });
            })
            .listen(
              (results) {
                store.dispatch(SyncUserContactsStateAction(AsyncState.success(results)));
              },
              onError: (error) {
                return store.dispatch(SyncUserContactsStateAction(AsyncState.failed(error, currentState().value)));
              },
            );
      };

  Async.Future _checkPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      var permission = await permissionHandler
          .checkPermissionStatus(PermissionGroup.contacts);
      if (permission != PermissionStatus.granted) {
        final permissions = await permissionHandler
            .requestPermissions([PermissionGroup.contacts]);
        permission = permissions.values.first;
      }
      if (permission != PermissionStatus.granted)
        throw AsyncError(
            AsyncErrorType.PERMISSION_DENIED, AsyncErrorSeverity.ERROR);
    }
  }

  Async.Future<List<UserContact>> _handleSyncResponse(
      Store<AppState> store, List<SyncOperationResult> results) async {
    final session = store.state.authState.loginState.value;
    if (session == null) return [];

    final db = await getDbConnection(session.user.id);
    final newValue =
        await db.transaction<List<UserContact>>((transaction) async {
      final newContacts = List<UserContact>.from(
          store.state.domainState.syncUserContactsState.value ?? []);
      results.forEach((result) async {
        switch (result.operation) {
          case SyncContactOperation.CREATE:
            newContacts.add(result.contact);
            await insertContact(transaction, result.contact);
            return;
          case SyncContactOperation.UPDATE:
          case SyncContactOperation.DELETE:
            final idx =
                newContacts.indexWhere((c) => c.id == result.contact.id);
            if (idx >= 0) // why???
              newContacts[idx] = result.contact;
            await updateContact(transaction, result.contact);
            return;
        }
      });
      return newContacts;
    });
    store
        .dispatch(SyncUserContactsStateAction(AsyncState.inProgress(newValue)));
    return newValue;
  }

  List<SyncContact> _findSyncs(
      List<UserContact> userContacts, Iterable<Contact> phoneContacts) {
    final toSync = List<SyncContact>();
    phoneContacts.forEach((phoneContact) {
      final existing = userContacts.firstWhere(
          (c) => c.localId == phoneContact.localId,
          orElse: () => null);
      // create?
      if (existing == null) {
        toSync.add(SyncContact(SyncContactOperation.CREATE, phoneContact));
        return;
      }
      // update?
      if (existing.isNotEqual(phoneContact) || existing.deleted != null) {
        toSync.add(SyncContact(
            SyncContactOperation.UPDATE,
            existing.copyWith(
              name: phoneContact.name,
              phones: phoneContact.phones,
              emails: phoneContact.emails,
            )));
      }
    });
    return toSync;
  }

  Async.Future<List<Contact>> _getPhoneContacts() async {
    // contact service doesn't request the permission automatically

    final phoneContacts = (await cs.ContactsService.getContacts())
        .map((c) => Contact.fromPhoneContact(c))
        .where((c) => c.name != null && c.phones.isNotEmpty)
        .toList();

    // read phone numbers from call log
    if (defaultTargetPlatform == TargetPlatform.android) {
      final phoneLog = new PhoneLog();
      bool permission = await phoneLog.checkPermission();
      if (permission != true) permission = await phoneLog.requestPermission();
      if (permission == true) {
        final logs = await phoneLog.getPhoneLogs();
        logs.forEach((log) {
          final number = log.formattedNumber;
          if (number != null) {
            final existing = phoneContacts.firstWhere(
                (c) => c.phones.indexWhere((p) => p.value == number) != -1,
                orElse: () => null);
            if (existing == null) {
              print('$number from call logs not found in contacts');
              phoneContacts.add(new Contact(
                  null,
                  'phonelog-$number',
                  I18N.callLogContactName,
                  [new ContactPhone(null, null, number)],
                  [],
                  [],
                  null,
                  false,
                  null));
            }
          }
        });
      }
    }
    return phoneContacts;
  }

  Async.Future<List<UserContact>> _loadUserContacts(
      Store<AppState> store, Api api) async {
    final session = store.state.authState.loginState.value;
    if (session == null) return [];

    List<UserContact> userContacts;
    if (store.state.domainState.syncUserContactsState.isSuccessful()) {
      userContacts =
          store.state.domainState.syncUserContactsState.value.map((contact) {
        if (contact.source != UserContactSource.LOCAL)
          contact.source = UserContactSource.LOCAL;
        return contact;
      }).toList();
    } else {
      String path = join(await getDatabasesPath(), "${session.user.id}.db");
      Database db = await openDatabase(path,
          version: 1,
          onCreate: (db, _) async => await db.execute(
              'CREATE TABLE contacts_json(id VARCHAR(50), json TEXT)'));
      final contactsJson = await db.query('contacts_json');
      userContacts = contactsJson
          .map((data) => UserContact.fromJson(
              UserContactSource.LOCAL, jsonDecode(data['json'])))
          .toList();
      store.dispatch(SyncUserContactsStateAction(AsyncState.inProgress(userContacts)));
    }

    int since = 0;
    for (UserContact c in userContacts) {
      if (c.updateTs > since) since = c.updateTs;
    }
    const limit = 100;
    bool shouldLoadNextBatch = true;
    while (shouldLoadNextBatch) {
      final apiContacts = await api.domain.loadUserContacts(session, since, limit);

      if (apiContacts.length > 0) {
        final db = await getDbConnection(session.user.id);
        await db.transaction((transaction) async {
          for (var apiContact in apiContacts) {
            final idx = userContacts.indexWhere((dbc) => dbc.id == apiContact.id);

            if (idx == -1) {
              apiContact.localId = null; //legacy api support
              final similarPhoneContacts =
                  await cs.ContactsService.getContacts(query: apiContact.name);

              for (var similarPhoneContact in similarPhoneContacts) {
                final similarContact =
                    Contact.fromPhoneContact(similarPhoneContact);
                if (apiContact.isEqual(similarContact)) {
                  apiContact.localId = similarContact.localId;
                  break;
                }
              }

              if (apiContact.localId == null) {
                try {
                  await cs.ContactsService.addContact(new cs.Contact(
                    givenName: apiContact.name,
                    phones: apiContact.phones
                        .map((i) => new cs.Item(label: '', value: i.value)),
                    emails: apiContact.emails
                        .map((i) => new cs.Item(label: '', value: i.value)),
                  ));
                  final pc = await cs.ContactsService.getContacts(
                      query: apiContact.name);
                  if (pc.isNotEmpty) {
                    apiContact.localId = pc.last.identifier;
                  }
                } catch (e) {
                  print('Failed to create contact. ${e}');
                  apiContact.localId = '';
                }
              }

              if (apiContact.localId != null) {
                userContacts.add(apiContact);
                await insertContact(transaction, apiContact);
              }
            } else {
              apiContact.localId = userContacts[idx].localId;
              userContacts[idx] = apiContact;
              await updateContact(transaction, apiContact);
            }
          }
        });
        store.dispatch(SyncUserContactsStateAction(AsyncState.success(userContacts)));
        since = apiContacts.last.updateTs;
        //shouldLoadNextBatch = false;
      }
      if (apiContacts.length < limit) break;
    }
    return userContacts;
  }
}

class SaveContactNoteStateAction {
  final AsyncState<String> state;

  SaveContactNoteStateAction(this.state);
}

class SaveContactNoteAction implements AsyncAction {
  final Contact contact;
  final String text;

  SaveContactNoteAction(this.contact, this.text);

  @override
  ThunkAction<AppState> execute(api) => (store) async {
        print('SaveContactNoteAction.execute()');

        final session = store.state.authState.loginState.value;
        if (session == null) return;

        store.dispatch(SaveContactNoteStateAction(AsyncState.inProgress()));
        try {
          final updateTs =
              await api.domain.addContactNote(session, contact.id, text);

          final syncContact = _getSyncContact(store, contact.id);
          if (syncContact != null) {
            await _updateSyncContact(
                store,
                syncContact.copyWith(
                    updateTs: updateTs,
                    notes: List<ContactNote>.from(syncContact.notes)
                      ..add(ContactNote(DateTime.now(), text, null))));
          }
          contact.notes.add(ContactNote(DateTime.now(), text, null));

          store.dispatch(
              SaveContactNoteStateAction(AsyncState.success(contact.id)));
        } catch (error) {
          store.dispatch(SaveContactNoteStateAction(AsyncState.failed(error)));
        }
      };
}

class ChangeLikeStateAction {
  final AsyncState<bool> state;

  ChangeLikeStateAction(this.state);
}

class ChangeLikeAction implements AsyncAction {
  final Contact contact;
  final bool value;

  ChangeLikeAction(this.contact, this.value);

  @override
  ThunkAction<AppState> execute(api) => (store) async {
        print('ChangeLikeAction.execute()');
        final session = store.state.authState.loginState.value;
        if (session == null) return;

        store.dispatch(ChangeLikeStateAction(AsyncState.inProgress()));
        try {
          final updateTs =
              await api.domain.changeLike(session, contact.id, value);

          final syncContact = _getSyncContact(store, contact.id);
          if (syncContact != null) {
            await _updateSyncContact(
                store,
                syncContact.copyWith(
                  updateTs: updateTs,
                  liked: value,
                ));
          }
          contact.liked = value;

          store.dispatch(ChangeLikeStateAction(AsyncState.success(value)));
        } catch (error) {
          store.dispatch(ChangeLikeStateAction(AsyncState.failed(error)));
        }
      };
}

class ChangePublicStateAction {
  final AsyncState<bool> state;

  ChangePublicStateAction(this.state);
}

class ChangePublicAction implements AsyncAction {
  final UserContact contact;
  final bool value;
  final List<String> restrictTo;

  ChangePublicAction(this.contact, this.value, {this.restrictTo});

  @override
  ThunkAction<AppState> execute(api) => (store) async {
        print('ChangePublicAction.execute()');
        final session = store.state.authState.loginState.value;
        if (session == null) return;

        store.dispatch(ChangePublicStateAction(AsyncState.inProgress()));
        try {
          final updateTs = await api.domain
              .changePublic(session, contact.id, value, restrictTo: restrictTo);
          final syncContact = _getSyncContact(store, contact.id);
          if (syncContact != null) {
            await _updateSyncContact(
                store,
                syncContact.copyWith(
                  updateTs: updateTs,
                  public: value,
                ));
          }
          contact.public = value;
          store.dispatch(ChangePublicStateAction(AsyncState.success(value)));
        } catch (error) {
          store.dispatch(ChangePublicStateAction(AsyncState.failed(error)));
        }
      };
}

class SearchContactsStateAction {
  final AsyncState<List<Contact>> state;

  SearchContactsStateAction(this.state);
}

class SearchContactsAction implements AsyncAction {
  final List<String> _queries;

  SearchContactsAction(this._queries);

  @override
  ThunkAction<AppState> execute(api) => (store) async {
        print('SeachContactHoldersAction.execute()');

        try {
          final session = store.state.authState.loginState.value;
          if (session == null) return;

          final userContacts =
              store.state.domainState.userContactsState.hasValue
                  ? store.state.domainState.userContactsState.value
                  : <UserContact>[];

          final queries = _queries.where((q) => q.trim().isNotEmpty).toList();
          if (queries.isEmpty) {
            userContacts.sort((c1, c2) => c1.compareTo(c2));
            store.dispatch(
                SearchContactsStateAction(AsyncState.success(userContacts)));
            return;
          }

          store.dispatch(SearchContactsStateAction(AsyncState.inProgress()));
          final matchedUserContacts = userContacts.where((c) {
            for (var query in queries) {
              if (c.matchesQuery(query.toLowerCase())) return true;
            }
            return false;
          }).toList();

          if (matchedUserContacts.isNotEmpty)
            store.dispatch(SearchContactsStateAction(
                AsyncState.inProgress(matchedUserContacts)));

          final data = await api.domain.searchContacts(session, queries);
          final results = matchedUserContacts.isEmpty
              ? data
              : data.isEmpty
                  ? matchedUserContacts
                  : (List<Contact>.from(matchedUserContacts)..addAll(data));
          results.sort((c1, c2) => c1.compareTo(c2));
          store
              .dispatch(SearchContactsStateAction(AsyncState.success(results)));
        } catch (error) {
          store.dispatch(SearchContactsStateAction(AsyncState.failed(error)));
        }
      };
}

class LoadDislikeContactsStateAction {
  final AsyncState<List<Contact>> state;

  LoadDislikeContactsStateAction(this.state);
}

class LoadDislikeContactsAction implements AsyncAction {
  @override
  ThunkAction<AppState> execute(api) => (store) async {
        print('LoadDislikeContactsAction.execute()');

        final session = store.state.authState.loginState.value;
        if (session == null) return;

        store.dispatch(LoadDislikeContactsStateAction(AsyncState.inProgress(
            store.state.domainState.loadDislikeContactsState.value)));
        try {
          List<Contact> data = await api.domain.loadDislikeContacts(session);
          if (store.state.domainState.userContactsState.hasValue) {
            final userDislikes = store.state.domainState.userContactsState.value
                .where((c) => c.liked == false);
            if (userDislikes.isNotEmpty)
              data = List<Contact>.from(data)..addAll(userDislikes);
          }
          store.dispatch(
              LoadDislikeContactsStateAction(AsyncState.success(data)));
        } catch (error) {
          store.dispatch(
              LoadDislikeContactsStateAction(AsyncState.failed(error)));
        }
      };
}

class LocateContactsStateAction {
  final AsyncState<List<Contact>> state;

  LocateContactsStateAction(this.state);
}

class LocateContactsAction implements AsyncAction {
  final Contact holder;
  final MapBounds bounds;
  final List<String> queries;

  const LocateContactsAction({this.holder, this.bounds, this.queries});

  @override
  ThunkAction<AppState> execute(api) => (store) async {
        print('SearchContactLocationAction.execute()');
        final session = store.state.authState.loginState.value;
        if (session == null) return;

        try {
          final b = bounds?.northWest != null && bounds?.southEast != null
              ? bounds
              : MapBounds.max();
          store.dispatch(LocateContactsStateAction(AsyncState.inProgress(
              store.state.domainState.locateContactsState.value)));

          final data = await api.domain.locateContacts(session, b,
              holderId: holder?.id, queries: queries);
          if (holder == null) {
            if (store.state.domainState.userContactsState.hasValue) {
              final userContacts = store
                  .state.domainState.userContactsState.value
                  .where((c) {
                    for (var query in queries) {
                      if (c.matchesQuery(query.toLowerCase())) return true;
                    }
                    return false;
                  })
                  .map((c) => UserContact(
                      c.source,
                      c.updateTs,
                      c.deleted,
                      c.copyWith(
                          phones:
                              c.phones.where((p) => p.fitsBounds(b)).toList())))
                  .where((c) => c.phones.isNotEmpty)
                  .toList();
              if (userContacts.isNotEmpty) {
                data.addAll(userContacts);
              }
            }
          }
          store.dispatch(LocateContactsStateAction(AsyncState.success(data)));
        } catch (error) {
          store.dispatch(LocateContactsStateAction(AsyncState.failed(
              error, store.state.domainState.locateContactsState.value)));
        }
      };
}

class LookupLocationStateAction {
  final AsyncState<Location> state;

  LookupLocationStateAction(this.state);
}

class LookupLocationAction implements AsyncAction {
  final LatLng ll;

  LookupLocationAction(this.ll);

  @override
  ThunkAction<AppState> execute(api) => (store) async {
        print('LookupLocationAction.execute()');

        store.dispatch(LookupLocationStateAction(AsyncState.inProgress()));
        try {
          final data = await api.domain.lookupLocation(ll);
          store.dispatch(LookupLocationStateAction(AsyncState.success(data)));
        } catch (error) {
          store.dispatch(LookupLocationStateAction(AsyncState.failed(error)));
        }
      };
}

class SaveManualPhoneLocationStateAction {
  final AsyncState state;

  SaveManualPhoneLocationStateAction(this.state);
}

class SaveManualPhoneLocationAction implements AsyncAction {
  final ContactPhone phone;
  final UserContact contact;

  SaveManualPhoneLocationAction(this.phone, this.contact);

  @override
  ThunkAction<AppState> execute(api) => (store) async {
        print('SaveManualLocationsAction.execute()');
        final session = store.state.authState.loginState.value;
        if (session == null) return;

        try {
          store.dispatch(
              SaveManualPhoneLocationStateAction(AsyncState.inProgress()));
          final updateTs = await api.domain
              .saveManualPhoneLocation(session, new List()..add(phone));
          store.dispatch(
              SaveManualPhoneLocationStateAction(AsyncState.success()));

          final syncContact = _getSyncContact(store, contact.id);
          if (syncContact != null) {
            final phonesCopy = List<ContactPhone>.from(syncContact.phones);
            final idx = syncContact.phones.indexWhere((p) => p.id == phone.id);
            phonesCopy[idx] = phone;
            await _updateSyncContact(store,
                syncContact.copyWith(updateTs: updateTs, phones: phonesCopy));
          }
        } catch (error) {
          store.dispatch(
              SaveManualPhoneLocationStateAction(AsyncState.failed(error)));
        }
      };
}

class SaveContactCommentStateAction {
  final AsyncState<String> state;
  final Contact contact;
  final String text;

  SaveContactCommentStateAction(this.state, {this.contact, this.text});
}

class SaveContactCommentAction implements AsyncAction {
  final Contact contact;
  final String text;

  SaveContactCommentAction(this.contact, this.text);

  @override
  ThunkAction<AppState> execute(api) => (store) async {
        print('SaveContactCommentAction.execute()');

        final session = store.state.authState.loginState.value;
        if (session == null) return;

        store.dispatch(SaveContactCommentStateAction(AsyncState.inProgress()));
        try {
          await api.domain.saveContactComment(session, contact.id, text);
          store.dispatch(SaveContactCommentStateAction(
              AsyncState.success(contact.id),
              contact: contact,
              text: text));
        } catch (error) {
          store.dispatch(
              SaveContactCommentStateAction(AsyncState.failed(error)));
        }
      };
}

class LoadHoldersStateAction {
  final AsyncState<List<IdName>> state;

  LoadHoldersStateAction(this.state);
}

class LoadHoldersAction implements AsyncAction {
  @override
  ThunkAction<AppState> execute(api) => (store) async {
        print('LoadHoldersAction.execute()');
        final session = store.state.authState.loginState.value;
        if (session == null) return;

        store.dispatch(LoadHoldersStateAction(AsyncState.inProgress()));
        try {
          final data = await api.domain.loadHolders(session);
          store.dispatch(LoadHoldersStateAction(AsyncState.success(data)));
        } catch (error) {
          store.dispatch(LoadHoldersStateAction(AsyncState.failed(error)));
        }
      };
}

class GetContactsCountStateAction {
  final AsyncState<int> state;

  GetContactsCountStateAction(this.state);
}

class GetContactsCountAction implements AsyncAction {
  @override
  ThunkAction<AppState> execute(api) => (store) async {
        print('GetTotalContactCounAction.execute()');
        final session = store.state.authState.loginState.value;
        if (session == null) return;

        store.dispatch(GetContactsCountStateAction(AsyncState.inProgress()));
        try {
          final data = await api.domain.getContactsCount(session);
          store.dispatch(GetContactsCountStateAction(AsyncState.success(data)));
        } catch (error) {
          store.dispatch(GetContactsCountStateAction(AsyncState.failed(error)));
        }
      };
}

class FindCommonContactsStateAction {
  final AsyncState<Map<String, List<String>>> state;

  FindCommonContactsStateAction(this.state);
}

class FindCommonContactsAction implements AsyncAction {
  final List<String> ids;

  FindCommonContactsAction(this.ids);

  @override
  ThunkAction<AppState> execute(api) => (store) async {
        print('FindCommonContactsAction.execute()');
        final session = store.state.authState.loginState.value;
        if (session == null) return;

        store.dispatch(FindCommonContactsStateAction(AsyncState.inProgress()));
        try {
          final data = await api.domain.findCommonContacts(session, ids);
          store.dispatch(
              FindCommonContactsStateAction(AsyncState.success(data)));
        } catch (error) {
          store.dispatch(
              FindCommonContactsStateAction(AsyncState.failed(error)));
        }
      };
}

Async.Future<Database> getDbConnection(String userId) async {
  final path = await getDatabasesPath();
  final dbPath = join(path, "$userId.db");
  return await openDatabase(dbPath);
}

Async.Future insertContact(DatabaseExecutor db, UserContact contact) async {
  await db.insert('contacts_json', {
    'id': contact.id,
    'json': jsonEncode(contact.toJson()),
  });
}

Async.Future updateContact(DatabaseExecutor db, UserContact contact) async {
  await db.update('contacts_json', {'json': jsonEncode(contact.toJson())},
      where: 'id = ?', whereArgs: [contact.id]);
}
