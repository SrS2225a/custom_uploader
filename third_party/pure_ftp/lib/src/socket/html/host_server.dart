import 'package:pure_ftp/src/socket/common/client_socket.dart';
import 'package:pure_ftp/src/socket/common/host_server.dart';

class HostServerImpl extends HostServer {
  Future<void> bind(String host, int port) async {
    throw UnimplementedError();
  }

  @override
  Future<ClientSocket> get firstSocket {
    throw UnimplementedError();
  }

  @override
  String get address {
    throw UnimplementedError();
  }

  @override
  int get port {
    throw UnimplementedError();
  }

  @override
  Future<void> close() {
    throw UnimplementedError();
  }
}
