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

import 'dart:async';

import 'package:googleapis/oauth2/v2.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis_auth/src/auth_http_utils.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import '../storage/local_file_storage.dart';
import '../storage/unsecure_token_storage.dart';

final _logger = Logger('GoogleAuth');

enum AuthState {
  authenticated,
  notAuthenticated,
}

class GoogleAuth {
  static const _scopes = [
    Oauth2Api.UserinfoEmailScope,
    Oauth2Api.UserinfoProfileScope,
  ];

  static const _clientId = "619519633889.apps.googleusercontent.com";
  static const _secret = "LOwVPys7lruBjjsI8erzh7KK";
  static final _id = ClientId(_clientId, _secret);

  final _authenticationStreamController =
      StreamController<AuthState>.broadcast();
  Stream<AuthState> get onAuthChanged => _authenticationStreamController.stream;

  static final _instance = GoogleAuth._();

  GoogleAuth._();

  factory GoogleAuth() {
    return _instance;
  }

  void _saveCredentials(credentials) async {
    final tokenStore = await UnsecureTokenStorage.get(
        LocalFileStorageFactory.makeLocalFileStorage(
            UnsecureTokenStorage.filename));
    tokenStore.saveTokens(credentials.refreshToken,
        credentials.accessToken.data, credentials.accessToken.expiry);
  }

  Future<List<String>> _readTokens() async {
    final tokenStore = await UnsecureTokenStorage.get(
        LocalFileStorageFactory.makeLocalFileStorage(
            UnsecureTokenStorage.filename));
    return tokenStore.readTokens();
  }

  Future<bool> get isAuthenticated async {
    final tokens = await _readTokens();
    return tokens != null && tokens.isNotEmpty;
  }

  /// Authenticate
  Future<void> authenticate(urlCallback) async {
    if (!(await isAuthenticated)) {
      final client = http.Client();
      obtainAccessCredentialsViaUserConsent(_id, _scopes, client, urlCallback)
          .then((AccessCredentials credentials) {
        _saveCredentials(credentials);
        _authenticationStreamController.add(AuthState.authenticated);
      }).catchError((e) {
        _logger.warning("Authentication error: $e");
        _authenticationStreamController.add(AuthState.notAuthenticated);
      });
    } else {
      _authenticationStreamController.add(AuthState.authenticated);
    }
  }

  /// Logout
  Future<void> clearCredentials() async {
    final tokenStore = await UnsecureTokenStorage.get(
        LocalFileStorageFactory.makeLocalFileStorage(
            UnsecureTokenStorage.filename));
    tokenStore.clear();
    _authenticationStreamController.add(AuthState.notAuthenticated);
  }

  Future<Map<String, String>> getAuthHeaders(http.Client client) async {
    final savedTokens = await _readTokens();
    if (savedTokens == null || savedTokens.length < 3) {
      clearCredentials();
      throw Exception("Couldn't read tokens or invalid tokens read");
    }

    try {
      final accessToken = AccessToken("Bearer", savedTokens.elementAt(1),
          DateTime.parse(savedTokens.elementAt(2)));
      final newCredentials = await refreshCredentials(
          _id,
          AccessCredentials(accessToken, savedTokens.elementAt(0), _scopes),
          client);
      _saveCredentials(newCredentials);
      return {"Authorization": "Bearer ${newCredentials.accessToken.data}"};
    } catch (_) {
      clearCredentials();
      rethrow;
    }
  }

  // I created a PR to have this merged into the googleapis plugin 2 years ago,
  // and it was never accepted:
  // https://github.com/dart-lang/googleapis_auth/pull/44
  // To avoid using another forked plugin, we're importing auth_http_utils.dart
  // to just have this as a method. It's not best practice to import that file.
  AutoRefreshingClient clientViaStoredCredentials(
      ClientId clientId, AccessCredentials accessCredentials,
      {http.Client baseClient}) {
    bool closeUnderlyingClient = false;
    if (baseClient == null) {
      baseClient = http.Client();
      closeUnderlyingClient = true;
    }
    return AutoRefreshingClient(baseClient, clientId, accessCredentials,
        closeUnderlyingClient: closeUnderlyingClient);
  }

  Future<Map<String, String>> getUserInfo() async {
    final savedTokens = await _readTokens();
    if (savedTokens == null || savedTokens.length < 3) {
      return <String, String>{};
    }

    final accessToken = AccessToken('Bearer', savedTokens.elementAt(1),
        DateTime.parse(savedTokens.elementAt(2)));
    final accessCredentials =
        AccessCredentials(accessToken, savedTokens.elementAt(0), _scopes);

    var client;
    try {
      client = clientViaStoredCredentials(_id, accessCredentials);
    } on AssertionError catch (e) {
      _logger.warning('Failed to obtain gAuth client: $e');
      return <String, String>{};
    }

    final oauth2 = Oauth2Api(client);
    return oauth2.userinfo.get().then((userInfoPlus) {
      return {
        'name': userInfoPlus.name,
        'picture': userInfoPlus.picture,
      };
    }).catchError((e) {
      _logger.warning('Failed to obtain user info: $e');
      return <String, String>{};
    });
  }
}
