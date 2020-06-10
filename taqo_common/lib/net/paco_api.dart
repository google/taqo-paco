import 'dart:async';

import "package:http/http.dart" as http;

import 'google_auth.dart';

class PacoResponse {
  static const success = 0;
  static const failure = -1;
  static const exception = -2;

  final int statusCode;
  final String statusMsg;

  final String body;

  PacoResponse(this.statusCode, this.statusMsg, {this.body});

  static Future<PacoResponse> futureFromHttpResponseFuture(Future<http.Response> responseFuture) async {
    http.Response response;
    try {
      response = await responseFuture;
    } catch (e) {
      return PacoResponse(PacoResponse.exception, e.toString());
    }

    if (response.statusCode == 200) {
      return PacoResponse(PacoResponse.success, 'Success',
          body: response.body);
    } else {
      return PacoResponse(PacoResponse.failure, response.reasonPhrase);
    }
  }

  bool get isSuccess => statusCode == success;
  bool get isFailure => statusCode == failure;
  bool get isException => statusCode == exception;
}

class PacoApi {
  //static const _stagingServer = "quantifiedself-staging.appspot.com";
  static const _prodServer = "www.pacoapp.com";
  static const _server = _prodServer;

  static Uri _experimentUrl([limit = 100]) =>
      Uri.https(_server, "/experiments", {"mine": null, "limit": "$limit"});
  static Uri _experimentByIdUrl(id) =>
      Uri.https(_server, "/experiments", {"id": "$id"});
  static Uri _pubExperimentByIdUrl(id) =>
      Uri.https(_server, "/pubexperiments", {"id": "$id"});
  static Uri _inviteUrl(code) =>
      Uri.https(_server, "/inviteCheck", {"code": "$code"});
  static final _eventsUri = Uri.https(_server, '/events');
  static final _pubExperimentUri = Uri.https(_server, '/pubexperiments');

  static final _instance = PacoApi._();

  final _gAuth = GoogleAuth();

  PacoApi._();

  factory PacoApi() {
    return _instance;
  }

  Future<http.Response> _get(http.Client client, Uri url,
      {Map<String, String> headers}) {
    return client.get(url, headers: headers);
  }

  Future<http.Response> _refreshAndGet(Uri url, {String defValue = ""}) async {
    final client = http.Client();
    try {
      final headers = await _gAuth.getAuthHeaders(client);
      final response = await _get(client, url, headers: headers);
      return response;
    } catch (_) {
      rethrow;
    } finally {
      client.close();
    }
  }

  Future<http.Response> _post(
      http.Client client, Uri url, Map<String, String> headers, String body) {
    return client.post(url, headers: headers, body: body);
  }

  Future<http.Response> _refreshAndPost(Uri url, String body,
      {bool isPublic = false}) async {
    final client = http.Client();
    try {
      final headers = isPublic ? <String, String>{} : await _gAuth.getAuthHeaders(client);
      headers['Content-Type'] = 'application/json';
      final response = await _post(client, url, headers, body);
      return response;
    } catch (_) {
      rethrow;
    } finally {
      client.close();
    }
  }

  // Public API
  Future<PacoResponse> postEvents(String body) =>
      PacoResponse.futureFromHttpResponseFuture(
        _refreshAndPost(_eventsUri, body));

  Future<PacoResponse> postEventsPublic(String body) =>
      PacoResponse.futureFromHttpResponseFuture(
        _refreshAndPost(_pubExperimentUri, body, isPublic: true));

  Future<PacoResponse> _refreshAndGetPacoResponse(Uri url) =>
      PacoResponse.futureFromHttpResponseFuture(_refreshAndGet(url));

  /// Gets all Experiments
  Future<PacoResponse> getExperimentsWithSavedCredentials() {
    return _refreshAndGetPacoResponse(_experimentUrl());
  }

  /// Gets the Experiment with id [experimentId]
  Future<PacoResponse> getExperimentByIdWithSavedCredentials(int experimentId) {
    return _refreshAndGetPacoResponse(_experimentByIdUrl(experimentId));
  }

  /// Gets the Experiments with ids [ids]
  Future<PacoResponse> getExperimentsByIdWithSavedCredentials(
      Iterable<int> ids) {
    return _refreshAndGetPacoResponse(_experimentByIdUrl(ids.join(',')));
  }

  Future<PacoResponse> _getPacoResponse(Uri url) async {
    final client = http.Client();
    try {
      final response = await _get(client, url);
      if (response.statusCode == 200) {
        return PacoResponse(PacoResponse.success, 'Success',
            body: response.body);
      }
      return PacoResponse(PacoResponse.failure, response.reasonPhrase);
    } catch (e) {
      return PacoResponse(PacoResponse.exception, e.toString());
    } finally {
      client.close();
    }
  }

  Future<PacoResponse> checkInvitationWithSavedCredentials(String code) {
    return _getPacoResponse(_inviteUrl(code));
  }

  Future<PacoResponse> getPubExperimentById(int experimentId) {
    return _getPacoResponse(_pubExperimentByIdUrl(experimentId));
  }
}
