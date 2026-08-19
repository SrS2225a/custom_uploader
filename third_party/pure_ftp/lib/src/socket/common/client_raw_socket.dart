import 'dart:async';

import 'package:pure_ftp/src/socket/common/client_socket_direction.dart';
import 'package:pure_ftp/src/socket/html/client_raw_socket.dart'
    if (dart.library.io) 'package:pure_ftp/src/socket/io/client_raw_socket.dart';

export 'package:pure_ftp/src/socket/common/client_socket_direction.dart';

abstract class ClientRawSocket {
  static Future<ClientRawSocket> connect(String host, int port,
      {Duration? timeout}) async {
    final result = ClientRawSocketImpl();
    await result.connect(host, port, timeout: timeout);
    return result;
  }

  Future<ClientRawSocket> secureSocket({bool ignoreCertificateErrors = false});

  List<int>? readMessage();

  void write(
    List<int> data, [
    int offset = 0,
    int? count,
  ]);

  Future<void> close();

  Future<void> shutdown(ClientSocketDirection how);

  int available();
}
