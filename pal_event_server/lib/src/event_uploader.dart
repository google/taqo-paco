import 'dart:convert';

import 'package:http/http.dart' as http;

import 'constants.dart';
import 'sqlite_database.dart';

const _headers = <String, String>{
  'Content-Type': 'application/json',
  'paco-version': '4.1',
};

// Why?
bool hasBlobsToUpload() => false;

// Why?
List<Map<String, dynamic>> uploadBlobs() => <Map<String, dynamic>>[];

Future callPaco(List<Map<String, dynamic>> event) async {
  final postBody = jsonEncode(event);
  print('callPaco() with body: $postBody');

  if (postBody.isEmpty) {
    return;
  }

  return http.post(pacoUrl, headers: _headers, body: postBody).then((http.Response response) {
    print('Response from paco call: [${response.statusCode}] ${response.body} '
        '${response.reasonPhrase}');
  }).catchError((e) {
    print('Error posting to Paco Server: $e');
  });
}

Future storeEvent(List events) async {
  final database = await SqliteDatabase.get();
  for (var e in events) {
    print('storeEvent: $e');
    await database.insertEvent(e);
  }
}
