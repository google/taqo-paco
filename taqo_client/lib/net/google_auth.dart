import 'dart:async';
import 'dart:convert';

import "package:googleapis/oauth2/v2.dart";
import "package:googleapis_auth/auth_io.dart";
import 'package:googleapis_auth/src/auth_http_utils.dart';
import "package:http/http.dart" as http;
import 'package:taqo_client/model/event.dart';
import 'package:taqo_client/storage/unsecure_token_storage.dart';

class GoogleAuth {
  static const String AUTH_TOKEN_TYPE_USERINFO_EMAIL =
      Oauth2Api.UserinfoEmailScope;

  static const String AUTH_TOKEN_TYPE_USERINFO_PROFILE =
      Oauth2Api.UserinfoProfileScope;

  static const _clientId = "619519633889.apps.googleusercontent.com";
  static const _secret = "LOwVPys7lruBjjsI8erzh7KK";
  static final id = new ClientId(_clientId, _secret);
  static const scopes = [AUTH_TOKEN_TYPE_USERINFO_EMAIL,
    AUTH_TOKEN_TYPE_USERINFO_PROFILE, ];

  var tokenStore = new UnsecureTokenStorage();

  StreamController<bool> _authenticationStreamController =
      StreamController<bool>.broadcast();

  Stream<bool> get onAuthChanged => _authenticationStreamController.stream;

  GoogleAuth._privateConstructor();

  static final GoogleAuth _instance = GoogleAuth._privateConstructor();

  factory GoogleAuth() {
    return _instance;
  }

  Future doIt(urlCallback) async {
    List<String> savedTokens = await readTokens();

    if (savedTokens == null || savedTokens.isEmpty) {
      var client = new http.Client();
      obtainAccessCredentialsViaUserConsent(id, scopes, client, urlCallback)
          .then((AccessCredentials credentials) async {
        saveCredentials(credentials);
        var accessToken = credentials.accessToken.data;
        var refreshToken = credentials.refreshToken;

        print("accessToken = $accessToken");
        print("refreshToken = $refreshToken");

        _authenticationStreamController.add(true);
      });
    } else {
      _authenticationStreamController.add(true);
    }
  }

  void saveCredentials(credentials) {
    tokenStore.saveTokens(credentials.refreshToken,
        credentials.accessToken.data, credentials.accessToken.expiry);
  }

  Future<bool> isAuthenticated() async {
    var tokens = await tokenStore.readTokens();
    return Future.value(tokens != null && tokens.isNotEmpty);
  }

  Future<List<String>> readTokens() async {
    var savedTokens = await tokenStore.readTokens();
    return savedTokens;
  }

  Future<String> getExperimentsWithSavedCredentials() async {
    var scopes = [AUTH_TOKEN_TYPE_USERINFO_EMAIL];

    var client = new http.Client();

    List<String> savedTokens = await readTokens();

    var accessToken = new AccessToken("Bearer", savedTokens.elementAt(1),
        DateTime.parse(savedTokens.elementAt(2)));
    return await refreshCredentials(
            id,
            new AccessCredentials(
                accessToken, savedTokens.elementAt(0), scopes),
            client)
        .then((newCredentials) {
      saveCredentials(newCredentials);
      var at = newCredentials.accessToken.data;
      var headers = {"Authorization": "Bearer $at"};
      return getExperiments(client, headers);
    });
  }

  Future<String> getExperimentsWithSavedCredentialsWithoutRefresh() async {
    List<String> savedTokens = await readTokens();
    var at = savedTokens.elementAt(1);
    var headers = {"Authorization": "Bearer $at"};
    var client = new http.Client();
    return getExperiments(client, headers);
  }

  Future<String> getExperiments(
      http.Client client, Map<String, String> headers) async {
    return await client
        .get("https://www.pacoapp.com/experiments?mine&limit=100",
            headers: headers)
        .then((response) {
      print(response.body);
      client.close();
      return response.body;
    });
  }

  Future<void> clearCredentials() async {
    var clearTokens = await tokenStore.clear();
    _authenticationStreamController.add(false);
    return clearTokens;
  }

  Future<String> checkInvitationWithSavedCredentials(String code) async {
//    List<String> savedTokens = await readTokens();
//    var at = savedTokens.elementAt(1);
//    var headers = {"Authorization": "Bearer $at"};
    var client = new http.Client();
    return await client
        .get("https://www.pacoapp.com/invite?code=$code")
        .then((response) {
      print(response.body);
      client.close();
      return response.body;
    });
  }

  Future<String> getExperimentById(int experimentId) async {
    var scopes = [AUTH_TOKEN_TYPE_USERINFO_EMAIL];
    var client = new http.Client();
    List<String> savedTokens = await readTokens();

    var accessToken = new AccessToken("Bearer", savedTokens.elementAt(1),
        DateTime.parse(savedTokens.elementAt(2)));
    return await refreshCredentials(
            id,
            new AccessCredentials(
                accessToken, savedTokens.elementAt(0), scopes),
            client)
        .then((newCredentials) {
      saveCredentials(newCredentials);
      var at = newCredentials.accessToken.data;
      var headers = {"Authorization": "Bearer $at"};
      return _getExperimentById(client, headers, experimentId);
    });
  }

  Future<String> _getExperimentById(
      http.Client client, Map<String, String> headers, int experimentId) async {
    return await client
        .get("https://www.pacoapp.com/experiments?id=$experimentId",
            headers: headers)
        .then((response) {
      print(response.body);
      client.close();
      return response.body;
    });
  }

  Future<String> _getExperimentsByIds(http.Client client,
      Map<String, String> headers, Iterable<int> experimentIds) async {
    var experimentIdsAsString = experimentIds.join(",");
    return await client
        .get("https://www.pacoapp.com/experiments?id=$experimentIdsAsString",
            headers: headers)
        .then((response) {
      print(response.body);
      client.close();
      return response.body;
    });
  }

  Future<String> getPubExperimentById(int experimentId) async {
    var client = new http.Client();
    return await client
        .get("https://www.pacoapp.com/pubexperiments?id=$experimentId")
        .then((response) {
      print(response.body);
      client.close();
      return response.body;
    });
  }

  Future<String> getExperimentsByIdWithSavedCredentials(
      Iterable<int> keys) async {
    var scopes = [AUTH_TOKEN_TYPE_USERINFO_EMAIL];
    var client = new http.Client();
    List<String> savedTokens = await readTokens();

    var accessToken = new AccessToken("Bearer", savedTokens.elementAt(1),
        DateTime.parse(savedTokens.elementAt(2)));
    return await refreshCredentials(
            id,
            new AccessCredentials(
                accessToken, savedTokens.elementAt(0), scopes),
            client)
        .then((newCredentials) {
      saveCredentials(newCredentials);
      var at = newCredentials.accessToken.data;
      var headers = {"Authorization": "Bearer $at"};
      return _getExperimentsByIds(client, headers, keys);
    });
  }

  Future<http.Response> postEvents(Iterable<Event> events) async {
    var scopes = [AUTH_TOKEN_TYPE_USERINFO_EMAIL];
    var client = new http.Client();
    List<String> savedTokens = await readTokens();

    var accessToken = new AccessToken("Bearer", savedTokens.elementAt(1),
        DateTime.parse(savedTokens.elementAt(2)));
    return await refreshCredentials(
            id,
            new AccessCredentials(
                accessToken, savedTokens.elementAt(0), scopes),
            client)
        .then((newCredentials) {
      saveCredentials(newCredentials);
      var at = newCredentials.accessToken.data;
      var headers = {"Authorization": "Bearer $at"};
      return client.post(Uri.https('www.pacoapp.com', '/events'),
          headers: headers, body: jsonEncode(events));
    });
  }

  // I created a PR to have this merged into the googleapis plugin 2 years ago,
  // and it was never accepted:
  // https://github.com/dart-lang/googleapis_auth/pull/44
  // To avoid using another forked plugin, we're importing auth_http_utils.dart
  // to just have this as a method. It's not best practice to import that file.
  AutoRefreshingClient clientViaStoredCredentials(ClientId clientId,
      AccessCredentials accessCredentials, {http.Client baseClient}) {
    bool closeUnderlyingClient = false;
    if (baseClient == null) {
      baseClient = http.Client();
      closeUnderlyingClient = true;
    }
    return AutoRefreshingClient(baseClient, clientId, accessCredentials,
        closeUnderlyingClient: closeUnderlyingClient);
  }

  Future<Map<String, String>> getUserInfo() async {
    final savedTokens = await readTokens();
    final accessToken = AccessToken('Bearer', savedTokens.elementAt(1),
        DateTime.parse(savedTokens.elementAt(2)));
    final accessCredentials = AccessCredentials(accessToken,
        savedTokens.elementAt(0), [AUTH_TOKEN_TYPE_USERINFO_PROFILE, ]);
    final client = clientViaStoredCredentials(id, accessCredentials);
    final oauth2 = Oauth2Api(client);
    return oauth2.userinfo.get().then((userInfoPlus) {
      return {
        'name': userInfoPlus.name,
        'picture': userInfoPlus.picture,
      };
    });
  }
}

void prompt(String url) {
  print("Please go to the following URL and grant access:");
  print("  => $url");
  print("");
}

//main(List<String> arguments) {
//  try {
//    var googleAuth = GoogleAuth();
//    googleAuth.doIt(prompt, googleAuth.getExperimentsWithSavedCredentials);
//  } catch (e) {
//    print(e);
//  }
//}
