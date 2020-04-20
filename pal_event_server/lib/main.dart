import 'src/pal_server/pal_server.dart';

void main() async {
  print('Server PAL starting');
  final server = PALLocalServer();
  server.run();
  print('Server ready');
}
