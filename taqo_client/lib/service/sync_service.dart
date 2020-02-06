import 'dart:developer' as developer;
import 'package:http/http.dart' as http;

import 'package:taqo_client/net/google_auth.dart';
import 'package:taqo_client/storage/local_database.dart';

Future<void> syncData() async {
  final db = LocalDatabase();
  final events = await db.getUnuploadedEvents();
  final gAuth = GoogleAuth();

  // TODO: handle upload limit size
  if (events.length > 0) {
    // We use a customized HTTP status code 600 to represent Flutter exception.
    // This is not a true HTTP status because in that case the HTTP connection
    // was not successful and hence there are no real HTTP response.
    final response = await gAuth.postEvents(events).catchError(
        (e) => http.Response('${e}', 600, reasonPhrase: 'Flutter Exception'));
    if (response.statusCode == 200) {
      await db.markEventsAsUploaded(events);
      developer.log('Syncing complete.');
    } else if (response.statusCode == 600) {
      developer.log('Could not complete upload of events '
          'becuase of the following error: '
          '${response.body}\n');
    } else {
      developer.log('Could not complete upload of events. '
          'The server returns the following response: '
          '${response.statusCode} ${response.reasonPhrase}\n${response.body}\n');
    }
  }
}
