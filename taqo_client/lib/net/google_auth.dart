import 'dart:async';

import "package:googleapis/oauth2/v2.dart";
import "package:googleapis_auth/auth_io.dart";
import 'package:googleapis_auth/src/auth_http_utils.dart';
import "package:http/http.dart" as http;

import '../storage/flutter_file_storage.dart';
import '../storage/unsecure_token_storage.dart';

class GoogleAuth {
  static const _scopes = [
    Oauth2Api.UserinfoEmailScope,
    Oauth2Api.UserinfoProfileScope,
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

  final _authenticationStreamController = StreamController<bool>.broadcast();
  Stream<bool> get onAuthChanged => _authenticationStreamController.stream;

  static final _instance = GoogleAuth._();

  GoogleAuth._();

  factory GoogleAuth() {
    return _instance;
  }

  void _saveCredentials(credentials) async {
    final tokenStore = await UnsecureTokenStorage.get(FlutterFileStorage(UnsecureTokenStorage.filename));
    tokenStore.saveTokens(credentials.refreshToken,
        credentials.accessToken.data, credentials.accessToken.expiry);
  }

  Future<List<String>> _readTokens() async {
    final tokenStore = await UnsecureTokenStorage.get(FlutterFileStorage(UnsecureTokenStorage.filename));
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
    final tokenStore = await UnsecureTokenStorage.get(FlutterFileStorage(UnsecureTokenStorage.filename));
    tokenStore.clear();
    _authenticationStreamController.add(false);
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
      final response = await _get(client, url, headers: headers);
      return response;
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
      final response = await _post(client, url, headers, body);
      return response;
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
        return PacoResponse(PacoResponse.success, 'Success', body: response.body);
      }
      return PacoResponse(PacoResponse.failure, response.reasonPhrase);
    }).catchError((e) {
      return PacoResponse(PacoResponse.exception, e.toString());
    });
  }

  Future<PacoResponse> _refreshAndGetPacoResponse(String url) {
    return _refreshAndGet(url).then((response) {
      if (response.statusCode == 200) {
        return PacoResponse(PacoResponse.success, 'Success', body: response.body);
      }
      return PacoResponse(PacoResponse.failure, response.reasonPhrase);
    }).catchError((e) {
      return PacoResponse(PacoResponse.exception, e.toString());
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
        return PacoResponse(PacoResponse.success, 'Success', body: response.body);
      }
      return PacoResponse(PacoResponse.failure, response.reasonPhrase);
    } catch (e) {
      return PacoResponse(PacoResponse.exception, e.toString());
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
    final savedTokens = await _readTokens();
    final accessToken = AccessToken('Bearer', savedTokens.elementAt(1),
        DateTime.parse(savedTokens.elementAt(2)));
    final accessCredentials = AccessCredentials(accessToken,
        savedTokens.elementAt(0), _scopes);
    final client = clientViaStoredCredentials(_id, accessCredentials);
    final oauth2 = Oauth2Api(client);
    return oauth2.userinfo.get().then((userInfoPlus) {
      return {
        'name': userInfoPlus.name,
        'picture': userInfoPlus.picture,
      };
    });
  }
}

class PacoResponse {
  static const success = 0;
  static const failure = -1;
  static const exception = -2;

  final int statusCode;
  final String statusMsg;

  final String body;

  PacoResponse(this.statusCode, this.statusMsg, {this.body});

  bool get isSuccess => statusCode == success;
  bool get isFailure => statusCode == failure;
  bool get isException => statusCode == exception;
}
