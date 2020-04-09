import 'dart:async';

import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

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
    _authenticationStreamController.add(false);

    // TODO ExperimentService should observe this somehow
    (await ExperimentService.getInstance()).clear();
  }

  Future<Map<String, String>> _refreshCredentials(http.Client client) async {
    final savedTokens = await _readTokens();
    if (savedTokens == null || savedTokens.length < 3) {
      clearCredentials();
      throw Exception("Couldn't read tokens or invalid tokens read");
    }

    try {
      final accessToken =
          AccessToken("Bearer", savedTokens.elementAt(1), DateTime.parse(savedTokens.elementAt(2)));
      final newCredentials = await refreshCredentials(
          _id, AccessCredentials(accessToken, savedTokens.elementAt(0), _scopes), client);
      _saveCredentials(newCredentials);
      return {"Authorization": "Bearer ${newCredentials.accessToken.data}"};
    } catch (_) {
      clearCredentials();
      rethrow;
    }
  }

  Future<http.Response> _get(http.Client client, String url,
      {Map<String, String> headers}) {
    return client.get(url, headers: headers);
  }

  Future<http.Response> _refreshAndGet(String url, {String defValue = ""}) async {
    final client = http.Client();
    try {
      final headers = await _refreshCredentials(client);
      return _get(client, url, headers: headers);
    } catch (_) {
      rethrow;
    } finally {
      client.close();
    }
  }

  Future<http.Response> _post(http.Client client, Uri url,
      Map<String, String> headers, String body) {
    return client.post(url, headers: headers, body: body);
  }

  Future<http.Response> _refreshAndPost(Uri url, String body) async {
    final client = http.Client();
    try {
      final headers = await _refreshCredentials(client);
      return _post(client, url, headers, body);
    } catch (_) {
      rethrow;
    } finally {
      client.close();
    }
  }

  // Public API

  Future<PacoResponse> postEvents(String body) async {
    return _refreshAndPost(_eventsUri, body).then((response) {
      if (response.statusCode == 200) {
        return PacoResponse(pacoResponseSuccess, 'Success', body: response.body);
      }
      return PacoResponse(pacoResponseFailure, response.reasonPhrase);
    }).catchError((e) {
      return PacoResponse(pacoResponseException, e.toString());
    });
  }

  Future<PacoResponse> _refreshAndGetPacoResponse(String url) {
    return _refreshAndGet(url).then((response) {
      if (response.statusCode == 200) {
        return PacoResponse(pacoResponseSuccess, 'Success', body: response.body);
      }
      return PacoResponse(pacoResponseFailure, response.reasonPhrase);
    }).catchError((e) {
      return PacoResponse(pacoResponseException, e.toString());
    });
  }

  /// Gets all Experiments
  Future<PacoResponse> getExperimentsWithSavedCredentials() {
    return _refreshAndGetPacoResponse(_experimentUrl);
  }

  /// Gets the Experiment with id [experimentId]
  Future<PacoResponse> getExperimentByIdWithSavedCredentials(int experimentId) {
    return _refreshAndGetPacoResponse("$_experimentByIdUrl$experimentId");
  }

  /// Gets the Experiments with ids [ids]
  Future<PacoResponse> getExperimentsByIdWithSavedCredentials(Iterable<int> ids) {
    return _refreshAndGetPacoResponse("$_experimentByIdUrl${ids.join(',')}");
  }

  Future<PacoResponse> _getPacoResponse(String url) async {
    final client = http.Client();
    try {
      final response = await _get(client, url);
      if (response.statusCode == 200) {
        return PacoResponse(pacoResponseSuccess, 'Success', body: response.body);
      }
      return PacoResponse(pacoResponseFailure, response.reasonPhrase);
    } catch (e) {
      return PacoResponse(pacoResponseException, e.toString());
    } finally {
      client.close();
    }
  }

  Future<PacoResponse> checkInvitationWithSavedCredentials(String code) {
    return _getPacoResponse("$_inviteUrl$code");
  }

  Future<PacoResponse> getPubExperimentById(int experimentId) {
    return _getPacoResponse("$_pubExperimentByIdUrl$experimentId");
  }
}

const pacoResponseSuccess = 0;
const pacoResponseFailure = -1;
const pacoResponseException = -2;

class PacoResponse {
  final int statusCode;
  final String statusMsg;

  final String body;

  PacoResponse(this.statusCode, this.statusMsg, {this.body});
}
