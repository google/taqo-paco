import 'src/server.dart';

void main() async {
  print('Server starting');
  final server = PALLocalServer();
  server.run();
  print('Server ready');
}
