/*
 * @author Oleg Khalidov <brooth@gmail.com>.
 * -----------------------------------------------
 * Freelance software development:
 * Upwork: https://www.upwork.com/fl/khalidovoleg
 * Freelancer: https://www.freelancer.com/u/brooth
 */

import 'package:acms/api/api.dart';
import 'package:acms/store/app.store.dart';
import 'package:acms/views/app.dart';
import 'package:flutter/material.dart';

final store = new AppStore(Api.create());
void main() => runApp(App(store));
