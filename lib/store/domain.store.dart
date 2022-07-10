/*
 * @author Oleg Khalidov <brooth@gmail.com>.
 * -----------------------------------------------
 * Freelance software development:
 * Upwork: https://www.upwork.com/fl/khalidovoleg
 * Freelancer: https://www.freelancer.com/u/brooth
 */

import 'package:acms/actions/auth.actions.dart';
import 'package:acms/actions/domain.actions.dart';
import 'package:acms/models/async.models.dart';
import 'package:acms/models/domain.models.dart';

class DomainState {
  final AsyncState<List<UserContact>> userContactsState;
  final AsyncState<List<UserContact>> syncUserContactsState;
  final AsyncState<List<Contact>> findContactsState;
  final AsyncState<String> saveContactNoteState;
  final AsyncState<bool> changeLikeState;
  final AsyncState<List<Contact>> searchContactsState;
  final AsyncState<List<Contact>> loadDislikeContactsState;
  final AsyncState<List<Contact>> locateContactsState;
  final AsyncState<Location> lookupLocationState;
  final AsyncState saveManualPhoneLocationState;
  final AsyncState<bool> changePublicState;
  final AsyncState<String> saveContactCommentState;
  final AsyncState<List<IdName>> loadHoldersState;
  final AsyncState<int> contactsCountState;
  final AsyncState<Map<String, List<String>>> findCommonContactsState;

  const DomainState(
    this.userContactsState,
    this.syncUserContactsState,
    this.findContactsState,
    this.saveContactNoteState,
    this.changeLikeState,
    this.searchContactsState,
    this.loadDislikeContactsState,
    this.locateContactsState,
    this.lookupLocationState,
    this.saveManualPhoneLocationState,
    this.changePublicState,
    this.saveContactCommentState,
    this.loadHoldersState,
    this.contactsCountState,
    this.findCommonContactsState,
  );

  DomainState.initial()
      : this(
          AsyncState.create(),
          AsyncState.create(),
          AsyncState.create(),
          AsyncState.create(),
          AsyncState.create(),
          AsyncState.create(),
          AsyncState.create(),
          AsyncState.create(),
          AsyncState.create(),
          AsyncState.create(),
          AsyncState.create(),
          AsyncState.create(),
          AsyncState.create(),
          AsyncState.create(),
          AsyncState.create(),
        );

  DomainState copyWith({
    AsyncState<List<UserContact>> userContactsState,
    AsyncState<List<UserContact>> syncUserContactsState,
    AsyncState<List<Contact>> findContactsState,
    AsyncState<String> saveContactNoteState,
    AsyncState<bool> changeLikeState,
    AsyncState<List<Contact>> searchContactsState,
    AsyncState<List<Contact>> loadDislikeContactsState,
    AsyncState<List<Contact>> locateContactsState,
    AsyncState<Location> lookupLocationState,
    AsyncState saveManualPhoneLocationState,
    AsyncState<bool> changePublicState,
    AsyncState<String> saveContactCommentState,
    AsyncState<List<IdName>> loadHoldersState,
    AsyncState<int> contactsCountState,
    AsyncState<Map<String, List<String>>> findCommonContactsState,
  }) =>
      DomainState(
        userContactsState ?? this.userContactsState,
        syncUserContactsState ?? this.syncUserContactsState,
        findContactsState ?? this.findContactsState,
        saveContactNoteState ?? this.saveContactNoteState,
        changeLikeState ?? this.changeLikeState,
        searchContactsState ?? this.searchContactsState,
        loadDislikeContactsState ?? this.loadDislikeContactsState,
        locateContactsState ?? this.locateContactsState,
        lookupLocationState ?? this.lookupLocationState,
        saveManualPhoneLocationState ?? this.saveManualPhoneLocationState,
        changePublicState ?? this.changePublicState,
        saveContactCommentState ?? this.saveContactCommentState,
        loadHoldersState ?? this.loadHoldersState,
        contactsCountState ?? this.contactsCountState,
        findCommonContactsState ?? this.findCommonContactsState,
      );
}

DomainState domainReducer(final DomainState state, dynamic action) {
  if (action is LoginStateAction && action.state.isNotSuccessful()) {
    return DomainState.initial();
  }
  if (action is SyncUserContactsStateAction) {
    return state.copyWith(
        syncUserContactsState: action.state,
        userContactsState: action.state.copyWith(
          value: action.state.value?.where((c) => c.deleted == null)?.toList(),
        ));
  }
  if (action is FindContactsActionProgress) {
    return state.copyWith(
      findContactsState: action.state,
    );
  }
  if (action is SaveContactNoteStateAction) {
    return state.copyWith(
      saveContactNoteState: action.state,
    );
  }
  if (action is ChangeLikeStateAction) {
    return state.copyWith(
      changeLikeState: action.state,
    );
  }
  if (action is SearchContactsStateAction) {
    return state.copyWith(
      searchContactsState: action.state,
    );
  }
  if (action is LoadDislikeContactsStateAction) {
    return state.copyWith(
      loadDislikeContactsState: action.state,
    );
  }
  if (action is LocateContactsStateAction) {
    return state.copyWith(
      locateContactsState: action.state,
    );
  }
  if (action is LookupLocationStateAction) {
    return state.copyWith(
      lookupLocationState: action.state,
    );
  }
  if (action is SaveManualPhoneLocationStateAction) {
    return state.copyWith(
      saveManualPhoneLocationState: action.state,
    );
  }
  if (action is ChangePublicStateAction) {
    return state.copyWith(
      changePublicState: action.state,
    );
  }
  if (action is SaveContactCommentStateAction) {
    final newState = state.copyWith(
      saveContactCommentState: action.state,
    );
    if (action.state.isSuccessful()) {
      final comment = ContactComment(DateTime.now(), action.text);
      var addToContact = true;
      if (newState.searchContactsState.hasValue) {
        newState.searchContactsState.value.forEach((c) {
          if (c.id == action.contact.id) c.comments.add(comment);
          if (c == action.contact) addToContact = false;
        });
      }
      if (newState.findContactsState.hasValue) {
        newState.findContactsState.value.forEach((c) {
          if (c.id == action.contact.id) c.comments.add(comment);
          if (c == action.contact) addToContact = false;
        });
      }
      if (addToContact) {
        action.contact.comments.add(comment);
      }
    }
    return newState;
  }
  if (action is LoadHoldersStateAction) {
    return state.copyWith(
      loadHoldersState: action.state,
    );
  }
  if (action is GetContactsCountStateAction) {
    return state.copyWith(
      contactsCountState: action.state,
    );
  }
  if (action is FindCommonContactsStateAction) {
    return state.copyWith(
      findCommonContactsState: action.state,
    );
  }
  return state;
}
