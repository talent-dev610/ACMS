/*
 * @author Oleg Khalidov <brooth@gmail.com>.
 * -----------------------------------------------
 * Freelance software development:
 * Upwork: https://www.upwork.com/fl/khalidovoleg
 * Freelancer: https://www.freelancer.com/u/brooth
 */

import 'package:acms/actions/geo.actions.dart';
import 'package:acms/models/async.models.dart';
import 'package:geolocator/geolocator.dart';

class GeoState {
  final AsyncState<Position> currentPositionState;

  const GeoState(this.currentPositionState);

  GeoState.initial()
      : this(
          AsyncState.create(),
        );

  GeoState copyWith({
    AsyncState<Position> currentPositionState,
  }) =>
      GeoState(
        currentPositionState ?? this.currentPositionState,
      );
}

GeoState geoReducer(final GeoState state, dynamic action) {
  if (action is GetCurrentPositionStateAction) {
    return state.copyWith(
      currentPositionState: action.state,
    );
  }
  return state;
}
