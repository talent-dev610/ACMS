/*
 * @author Oleg Khalidov <brooth@gmail.com>.
 * -----------------------------------------------
 * Freelance software development:
 * Upwork: https://www.upwork.com/fl/khalidovoleg
 * Freelancer: https://www.freelancer.com/u/brooth
 */
import 'package:acms/store/app.store.dart';
import 'package:acms/views/screens/auth/auth.screen.dart';
import 'package:acms/views/screens/main/main.screen.dart';
import 'package:acms/views/screens/sync/sync.screen.dart';
import 'package:acms/views/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

class App extends StatelessWidget {
  final AppStore store;

  const App(this.store);

  @override
  Widget build(BuildContext context) {
    return StoreProvider(
      store: this.store,
      child: MaterialApp(
        theme: appTheme(context),
        debugShowCheckedModeBanner: false,
        home: AuthScreen(),
        routes: {
          'auth': (_) => AuthScreen(),
          'sync': (_) => SyncScreen(),
          'main': (_) => MainScreen(),
        },
      ),
    );
  }
}
