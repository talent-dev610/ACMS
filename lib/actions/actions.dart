/*
 * @author Oleg Khalidov <brooth@gmail.com>.
 * -----------------------------------------------
 * Freelance software development:
 * Upwork: https://www.upwork.com/fl/khalidovoleg
 * Freelancer: https://www.freelancer.com/u/brooth
 */
import 'package:acms/api/api.dart';
import 'package:acms/store/app.store.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

abstract class AsyncAction {
  ThunkAction<AppState> execute(Api api);
}

void asyncActionMiddleware<State>(
    Store<State> store, dynamic action, NextDispatcher next) {
  if (action is AsyncAction) {
    final api = (store as AppStore).api;
    store.dispatch(action.execute(api));
  } else {
    next(action);
  }
}
