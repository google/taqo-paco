import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import '../net/google_auth.dart';
import '../pages/login_page.dart';
import '../pages/running_experiments_page.dart';

class AuthProvider with ChangeNotifier {
  static final _gAuth = GoogleAuth();

  bool _authState = false;
  StreamSubscription<bool> _gAuthListener;

  AuthProvider() {
    // Listen for auth changes
    _gAuthListener = _gAuth.onAuthChanged.listen(
        _gAuthStateListener,
        onError: _gAuthStateError);

    // Check and set initial state
    _gAuth.isAuthenticated().then(_gAuthStateListener);
  }

  void _gAuthStateListener(bool newAuthState) {
    print('AuthProvider newAuthState: $newAuthState');
    _authState = newAuthState;
    notifyListeners();
  }

  void _gAuthStateError(error) {
    print('AuthProvider error: $error');
  }

  @override
  void dispose() {
    if (_gAuthListener != null) {
      _gAuthListener.cancel();
      _authState = false;
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
    _gAuth.doIt(_urlCallback);
    MyApp.navigatorKey.currentState.pushNamed(RunningExperimentsPage.routeName);
  }

  void signOut() {
    _gAuth.clearCredentials();
    MyApp.navigatorKey.currentState.pushNamed(LoginPage.routeName);
  }

  bool get isAuthenticated => _authState;
}
