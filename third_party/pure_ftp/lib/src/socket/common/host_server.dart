import 'package:pure_ftp/src/socket/common/client_socket.dart';
import 'package:pure_ftp/src/socket/html/host_server.dart'
    if (dart.library.io) 'package:pure_ftp/src/socket/io/host_server.dart';

abstract class HostServer {
  static Future<HostServer> bind(String host, int port) async {
    final result = HostServerImpl();
    await result.bind(host, port);
    return result;
  }

  Future<ClientSocket> get firstSocket;

  String get address;

  int get port;

  Future<void> close();
}
