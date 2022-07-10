/*
 * @author Oleg Khalidov <brooth@gmail.com>.
 * -----------------------------------------------
 * Freelance software development:
 * Upwork: https://www.upwork.com/fl/khalidovoleg
 * Freelancer: https://www.freelancer.com/u/brooth
 */

import 'dart:async';

import 'package:acms/actions/actions.dart';
import 'package:acms/c.dart';
import 'package:acms/models/async.models.dart';
import 'package:acms/store/app.store.dart';
import 'package:geolocator/geolocator.dart';
import 'package:redux_thunk/redux_thunk.dart';

class GetCurrentPositionStateAction {
  final AsyncState<Position> state;

  GetCurrentPositionStateAction(this.state);
}

class GetCurrentPositionAction implements AsyncAction {
  @override
  ThunkAction<AppState> execute(api) => (store) async {
        store.dispatch(GetCurrentPositionStateAction(AsyncState.inProgress()));
        try {
          if (DEV_MODE) await Future.delayed(Duration(seconds: 1));
          Position position =
              await Geolocator().getCurrentPosition();
          store.dispatch(
              GetCurrentPositionStateAction(AsyncState.success(position)));
        } catch (err) {
          store.dispatch(GetCurrentPositionStateAction(AsyncState.failed(err)));
        }
      };
}
