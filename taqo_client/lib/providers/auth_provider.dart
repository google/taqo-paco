// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// @dart=2.9

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:taqo_common/net/google_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import '../pages/login_page.dart';
import '../pages/find_experiments_page.dart';

final _logger = Logger('AuthProvider');

class AuthProvider with ChangeNotifier {
  static final _gAuth = GoogleAuth();

  StreamSubscription<AuthState> _gAuthListener;

  AuthState _authState = AuthState.notAuthenticated;
  String _userInfoName;
  String _userPhotoUrl;

  AuthProvider() {
    // Listen for auth changes
    _gAuthListener = _gAuth.onAuthChanged
        .listen(_gAuthStateListener, onError: _gAuthStateError);

    // Check and set initial state
    _gAuth.isAuthenticated.then((bool b) {
      _gAuthStateListener(
          b ? AuthState.authenticated : AuthState.notAuthenticated);
    });
  }

  void _gAuthStateListener(AuthState newAuthState) {
    //_logger.info('AuthProvider newAuthState: $newAuthState');
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
    _logger.warning('AuthProvider error: $error');
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
      MyApp.navigatorKey.currentState.pushNamed(FindExperimentsPage.routeName);
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
