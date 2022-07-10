/*
 * @author Oleg Khalidov <brooth@gmail.com>.
 * -----------------------------------------------
 * Freelance software development:
 * Upwork: https://www.upwork.com/fl/khalidovoleg
 * Freelancer: https://www.freelancer.com/u/brooth
 */

import 'dart:async';

import 'package:acms/actions/auth.actions.dart';
import 'package:acms/i18n/i18n.dart';
import 'package:acms/models/async.models.dart';
import 'package:acms/models/auth.models.dart';
import 'package:acms/models/domain.models.dart';
import 'package:acms/store/app.store.dart';
import 'package:acms/views/components/alerts.dart';
import 'package:acms/views/screens/auth/auth.screen.dart';
import 'package:acms/views/screens/main/black_list.tab.dart';
import 'package:acms/views/screens/main/map.tab.dart';
import 'package:acms/views/screens/main/search.tab.dart';
import 'package:acms/views/theme.dart';
import 'package:acms/views/views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:rxdart/rxdart.dart';

final mainScreenStateKey = new GlobalKey<_MainScreenState>();

abstract class MainScreenTab extends Widget {
  Widget get topBar;

  Widget get tabIcon;

  String get tabIconTitle;

  onTabClick();
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => new _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetStateUtilsMixin {
  List<MainScreenTab> tabs;
  int _activeTabIndex = 0;
  Contact twiceSearchContact;
  AlertData _notification;

  _MainScreenState() {
    tabs = [
      MapTab(
        () => _activeTabIndex == 0,
        (contact) {
          setState(() => _activeTabIndex = 1);
          (tabs[1] as SearchTab).searchByContact(contact);
        },
        () => setState(() {}),
      ),
      SearchTab(_openLocation, () => setState(() {})),
      BlackListTab(_openLocation),
    ];
  }

  _openLocation(ll) {
    setState(() => _activeTabIndex = 0);
    Future.delayed(Duration(milliseconds: 500),
        () => (tabs[0] as MapTab).openLocation(ll));
  }

  @override
  Widget build(BuildContext context) {
    final activeTab = tabs[_activeTabIndex];
    return StoreConnector<AppState, _ViewModel>(
      converter: (store) => _ViewModel(store),
      builder: (context, model) => Scaffold(
            backgroundColor: AppColors.lightBg,
            appBar: activeTab.topBar,
            body: Stack(
              children: <Widget>[
                activeTab,
                buildNotification(_notification, top: 35.0),
              ],
            ),
            bottomNavigationBar: _buildBottomNavBar(),
          ),
      onInitialBuild: (model) {
        this.subscriptions.addAll([
          Observable.periodic(Duration(minutes: 1))
              .delay(Duration(seconds: 3))
              .listen((_) => model.refreshUserPrefs()),
        ]);
        if (model.loginState.value?.user?.name != null)
          setState(() => _notification = AlertData.success(
                I18N.welcomeText(model.loginState.value.user.name),
                duration: Duration(seconds: 3),
              ));
      },
      onDidChange: (model) {
        if (model.isLoggedOut()) {
          Navigator.of(context)
              .pushReplacement(AppRouteTransitions.none((_) => AuthScreen()));
          return;
        }
      },
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      iconSize: 18.0,
      items: tabs.map((tab) => _buildItem(tab)).toList(),
      currentIndex: _activeTabIndex,
      fixedColor: AppColors.bottomBarItem,
      onTap: (index) => _activeTabIndex == index
          ? tabs[_activeTabIndex].onTabClick()
          : setState(() => _activeTabIndex = index),
    );
  }

  BottomNavigationBarItem _buildItem(MainScreenTab tab) {
    bool isActive = _activeTabIndex == tabs.indexOf(tab);
    return BottomNavigationBarItem(
        icon: Padding(
          padding: EdgeInsets.only(bottom: isActive ? 1.0 : .0),
          child: tab.tabIcon,
        ),
        label: tab.tabIconTitle);
  }
}

class _Styles {
  static const botNavBarItemTitle = TextStyle(
    fontFamily: 'NotoSans',
    fontSize: 14.0,
    fontWeight: FontWeight.normal,
  );
}

class _ViewModel {
  final AppState _state;
  final Function _dispatch;

  _ViewModel(Store<AppState> store)
      : _state = store.state,
        _dispatch = store.dispatch;

  AsyncState<Session> get loginState => _state.authState.loginState;

  bool isLoggedOut() {
    return _state.authState.loginState.isNotSuccessful();
  }

  void refreshUserPrefs() => _dispatch(new RefreshUserPrefsAction());

  operator ==(o) {
    return o is _ViewModel &&
        this._state.authState.loginState == o._state.authState.loginState;
  }

  @override
  int get hashCode => 0;
}
