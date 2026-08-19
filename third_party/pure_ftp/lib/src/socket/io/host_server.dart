import 'dart:io';

import 'package:pure_ftp/src/socket/common/client_socket.dart';
import 'package:pure_ftp/src/socket/common/host_server.dart';
import 'package:pure_ftp/src/socket/io/client_socket.dart';

class HostServerImpl extends HostServer {
  late ServerSocket _serverSocket;

  Future<void> bind(String host, int port) async {
    _serverSocket = await ServerSocket.bind(host, port);
  }

  @override
  Future<ClientSocket> get firstSocket =>
      _serverSocket.first.then(ClientSocketImpl.fromSocket);

  @override
  String get address => _serverSocket.address.address;

  @override
  int get port => _serverSocket.port;

  @override
  Future<void> close() => _serverSocket.close();
}
