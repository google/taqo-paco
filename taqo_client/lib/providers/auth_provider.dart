import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import '../net/google_auth.dart';
import '../pages/login_page.dart';
import '../pages/running_experiments_page.dart';

class AuthProvider with ChangeNotifier {
  static final _gAuth = GoogleAuth();

  StreamSubscription<AuthState> _gAuthListener;

  AuthState _authState = AuthState.notAuthenticated;
  String _userInfoName;
  String _userPhotoUrl;

  AuthProvider() {
    // Listen for auth changes
    _gAuthListener = _gAuth.onAuthChanged.listen(
        _gAuthStateListener,
        onError: _gAuthStateError);

    // Check and set initial state
    _gAuth.isAuthenticated.then((bool b) {
      _gAuthStateListener(b ? AuthState.authenticated: AuthState.notAuthenticated);
    });
  }

  void _gAuthStateListener(AuthState newAuthState) {
    //print('AuthProvider newAuthState: $newAuthState');
    _authState = newAuthState;
    notifyListeners();

    if (_authState == AuthState.authenticated) {
      _gAuth.getUserInfo().then((info) {
        _userInfoName = info['name'];
        _userPhotoUrl = info['picture'];
        notifyListeners();
      });
    }
  }

  void _gAuthStateError(error) {
    print('AuthProvider error: $error');
  }

  @override
  void dispose() {
    if (_gAuthListener != null) {
      _gAuthListener.cancel();
    }
    super.dispose();
  }

  void _urlCallback(String url) async {
    if (await canLaunch(url)) {
      await launch(url, forceSafariVC: false, forceWebView: false);
    } else {
      // TODO Handle nicely
    }
  }

  void signIn() {
    _gAuth.authenticate(_urlCallback).then((_) {
      MyApp.navigatorKey.currentState.pushNamed(
          RunningExperimentsPage.routeName);
    });
  }

  void signOut() {
    _gAuth.clearCredentials().then((_) {
      MyApp.navigatorKey.currentState.pushNamed(LoginPage.routeName);
    });
  }

  bool get isAuthenticated => _authState == AuthState.authenticated;

  String get userInfoName => _userInfoName;

  String get userInfoPhoto => _userPhotoUrl;
}
