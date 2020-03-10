import 'dart:async';
import 'dart:convert';

import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

import '../model/event.dart';
import '../service/experiment_service.dart';
import '../storage/unsecure_token_storage.dart';

class GoogleAuth {
  static const _authTokenTypeUserInfoEmail = "https://www.googleapis.com/auth/userinfo.email";
  static const _scopes = [
    _authTokenTypeUserInfoEmail,
  ];

  //static const _stagingServer = "http://quantifiedself-staging.appspot.com";
  static const _prodServer = "https://www.pacoapp.com";
  static const _server = _prodServer;

  static const _experimentUrl = "$_server/experiments?mine&limit=100";
  static const _experimentByIdUrl = "$_server/experiments?id=";
  static const _pubExperimentByIdUrl = "$_server/pubexperiments?id=";
  static const _inviteUrl = "$_server/invite?code=";
  static final _eventsUri = Uri.https('www.pacoapp.com', '/events');

  static const _clientId = "619519633889.apps.googleusercontent.com";
  static const _secret = "LOwVPys7lruBjjsI8erzh7KK";
  static final _id = ClientId(_clientId, _secret);

  static final _tokenStore = UnsecureTokenStorage();

  final _authenticationStreamController = StreamController<bool>.broadcast();
  Stream<bool> get onAuthChanged => _authenticationStreamController.stream;

  static final _instance = GoogleAuth._();

  GoogleAuth._();

  factory GoogleAuth() {
    return _instance;
  }

  void _saveCredentials(credentials) {
    _tokenStore.saveTokens(
        credentials.refreshToken, credentials.accessToken.data, credentials.accessToken.expiry);
  }

  Future<List<String>> _readTokens() => _tokenStore.readTokens();

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
        _authenticationStreamController.add(true);
      }).catchError((e) {
        print("Authentication error: $e");
        _authenticationStreamController.add(false);
      });
    } else {
      _authenticationStreamController.add(true);
    }
  }

  /// Logout
  Future<void> clearCredentials() async {
    await _tokenStore.clear();
    (await ExperimentService.getInstance()).clear();
    _authenticationStreamController.add(false);
  }

  Future<Map<String, String>> _refreshCredentials(http.Client client) async {
    final savedTokens = await _readTokens();
    if (savedTokens == null || savedTokens.length < 3) {
      clearCredentials();
      return null;
    }

    final accessToken =
        AccessToken("Bearer", savedTokens.elementAt(1), DateTime.parse(savedTokens.elementAt(2)));
    return refreshCredentials(
            _id, AccessCredentials(accessToken, savedTokens.elementAt(0), _scopes), client)
        .then((newCredentials) {
      _saveCredentials(newCredentials);
      final at = newCredentials.accessToken.data;
      return {"Authorization": "Bearer $at"};
    }).catchError((e) {
      print("Error refreshing tokens: $e");
      clearCredentials();
      return null;
    });
  }

  Future<String> _get(http.Client client, String url, Map<String, String> headers) {
    return client.get(url, headers: headers).then((response) {
      client.close();
      return response.body;
    }).catchError((e) {
      print("Error getting experiments ($url): $e");
      client.close();
      return "";
    });
  }

  Future<String> _refreshAndGet(String url, {String defValue = ""}) async {
    final client = http.Client();
    return _refreshCredentials(client).then((headers) {
      if (headers == null) {
        return Future.value(defValue);
      }
      return _get(client, url, headers);
    }).catchError((e) {
      client.close();
      return Future.value(defValue);
    });
  }

  Future<http.Response> _post(http.Client client, Uri url, Map<String, String> headers, String body) {
    return client.post(url, headers: headers, body: body).then((response) {
      client.close();
      return response;
    }).catchError((e) {
      print("Error getting experiments ($url): $e");
      client.close();
      return "";
    });
  }

  Future<http.Response> _refreshAndPost(Uri url, String body) async {
    final client = http.Client();
    return _refreshCredentials(client).then((headers) {
      if (headers == null) {
        throw http.ClientException('Failed to refresh credentials');
      }
      return _post(client, url, headers, body);
    }).catchError((e) {
      client.close();
      throw http.ClientException(e.toString());
    });
  }

  // Public API

  Future<http.Response> postEvents(Iterable<Event> events) async {
    return _refreshAndPost(_eventsUri, jsonEncode(events));
  }

  /// Gets all Experiments
  Future<String> getExperimentsWithSavedCredentials() {
    return _refreshAndGet(_experimentUrl);
  }

  /// Gets the Experiment with id [experimentId]
  Future<String> getExperimentByIdWithSavedCredentials(int experimentId) {
    return _refreshAndGet("$_experimentByIdUrl$experimentId");
  }

  /// Gets the Experiments with ids [ids]
  Future<String> getExperimentsByIdWithSavedCredentials(Iterable<int> ids) {
    return _refreshAndGet("$_experimentByIdUrl${ids.join(',')}");
  }

  Future<String> checkInvitationWithSavedCredentials(String code) {
    return _get(http.Client(), "$_inviteUrl$code", null);
  }

  Future<String> getPubExperimentById(int experimentId) {
    return _get(http.Client(), "$_pubExperimentByIdUrl$experimentId", null);
  }
}
