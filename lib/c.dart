// ignore_for_file: non_constant_identifier_names

/*
 * @author Oleg Khalidov (brooth@gmail.com).
 * -----------------------------------------------
 * Software Development:
 * Upwork: https://www.upwork.com/fl/khalidovoleg
 * Freelancer: https://www.freelancer.com/u/brooth
 */

import 'package:flutter/foundation.dart';
import 'package:latlong/latlong.dart';

final BACKEND_HOST = 'gk200.com';
/*final BACKEND_HOST = !DEV_MODE
    ? 'gk200.com'
    : defaultTargetPlatform == TargetPlatform.android
        ? '10.0.2.2'
        : '127.0.0.1';*/
final BACKEND_PORT = 3003;

final CLIENT_ID = defaultTargetPlatform == TargetPlatform.android
    ? 'DK2SmAmv44IKCDMA13rbynStWMpFjWlt'
    : 'xLIareVEFrxftIZKQ2YuxLue95f58B7T';

bool get DEV_MODE {
  bool inDebugMode = false;
  // assert(inDebugMode = true);
  return inDebugMode;
}

final MAP_DEFAULT_CENTER = LatLng(21.0, 116.0);
final MAP_DEFAULT_ZOOM = 5.0;
