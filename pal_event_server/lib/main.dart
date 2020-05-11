import 'package:taqo_common/rpc/rpc_constants.dart';

import 'src/tesp_server.dart';

void main() async {
  print('Server PAL starting');
  final server = PALTespServer();
  server.serve(address: localServerHost, port: localServerPort);
  print('Server ready');
}
