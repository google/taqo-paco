import 'dart:async';

import "package:googleapis_auth/auth_io.dart";
import "package:http/http.dart" as http;
import 'package:taqo_client/storage/unsecure_token_storage.dart';

class GoogleAuth {
  static const String AUTH_TOKEN_TYPE_USERINFO_EMAIL =
      "https://www.googleapis.com/auth/userinfo.email";

  static const String AUTH_TOKEN_TYPE_USERINFO_PROFILE =
      "https://www.googleapis.com/auth/userinfo.profile";

  static const _clientId = "619519633889.apps.googleusercontent.com";
  static const _secret = "LOwVPys7lruBjjsI8erzh7KK";
  static final id = new ClientId(_clientId, _secret);
  static const scopes = [AUTH_TOKEN_TYPE_USERINFO_EMAIL];

  var tokenStore = new UnsecureTokenStorage();

  StreamController<bool> _authenticationStreamController =
      StreamController<bool>.broadcast();

  Stream<bool> get onAuthChanged => _authenticationStreamController.stream;

  GoogleAuth._privateConstructor();

  static final GoogleAuth _instance = GoogleAuth._privateConstructor();

  factory GoogleAuth() {
    return _instance;
  }

  Future doIt(urlCallback, successCallback) async {
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

        if (successCallback != null) {
          successCallback();
        }
      });
    } else {
      //TODO choose a Future or a callback not this mishmash
      if (successCallback != null) {
        successCallback();
      }
      //await getExperimentsWithSavedCredentials(savedTokens, scopes, client);
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

  Future<String> _getExperimentsByIds(
      http.Client client, Map<String, String> headers, Iterable<int> experimentIds) async {
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

  Future<String> getExperimentsByIdWithSavedCredentials(Iterable<int> keys) async {
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

}

void prompt(String url) {
  print("Please go to the following URL and grant access:");
  print("  => $url");
  print("");
}

main(List<String> arguments) {
  try {
    var googleAuth = GoogleAuth();
    googleAuth.doIt(prompt, googleAuth.getExperimentsWithSavedCredentials);
  } catch (e) {
    print(e);
  }
}
