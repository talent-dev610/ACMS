/*
 * @author Oleg Khalidov <brooth@gmail.com>.
 * -----------------------------------------------
 * Freelance software development:
 * Upwork: https://www.upwork.com/fl/khalidovoleg
 * Freelancer: https://www.freelancer.com/u/brooth
 */

import 'package:acms/api/api.dart';
import 'package:acms/store/auth.store.dart';
import 'package:acms/store/domain.store.dart';
import 'package:acms/store/geo.store.dart';
import 'package:acms/store/sync.store.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:acms/actions/actions.dart';

class AppState {
  final AuthState authState;
  final DomainState domainState;
  final GeoState geoState;
  final SyncState syncState;
  final AppState prevState;

  const AppState(
    this.authState,
    this.domainState,
    this.geoState,
    this.syncState,
    this.prevState,
  );

  AppState copyWith({
    AuthState authState,
    DomainState domainState,
    GeoState geoState,
    SyncState syncState,
  }) =>
      AppState(
        authState ?? this.authState,
        domainState ?? this.domainState,
        geoState ?? this.geoState,
        syncState ?? this.syncState,
        this,
      );

  operator ==(o) {
    return o is AppState &&
        authState == o.authState &&
        domainState == o.domainState &&
        syncState == o.syncState &&
        geoState == o.geoState;
  }

  @override
  int get hashCode => 0;
}

AppState appReducer(final AppState state, dynamic action) {
  print('dispatched action: ${action.runtimeType}');

  return state.copyWith(
    authState: authReducer(state.authState, action),
    domainState: domainReducer(state.domainState, action),
    geoState: geoReducer(state.geoState, action),
    syncState: syncReducer(state.syncState, action),
  );
}

class AppStore extends Store<AppState> {
  final Api api;

  AppStore(this.api)
      : super(
          appReducer,
          initialState: new AppState(
            AuthState.initial(),
            DomainState.initial(),
            GeoState.initial(),
            SyncState.initial(),
            null,
          ),
          middleware: [
            thunkMiddleware,
            asyncActionMiddleware,
          ],
          distinct: true,
          syncStream: true,
        );
}
