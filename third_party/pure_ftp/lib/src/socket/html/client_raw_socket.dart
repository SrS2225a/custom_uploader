import 'dart:async';

import 'package:pure_ftp/src/socket/common/client_raw_socket.dart';

class ClientRawSocketImpl extends ClientRawSocket {
  @override
  Future<void> close() {
    throw UnimplementedError();
  }

  Future<void> connect(String host, int port, {Duration? timeout}) async {
    throw UnimplementedError();
  }

  @override
  List<int>? readMessage([int? length]) {
    throw UnimplementedError();
  }

  @override
  Future<ClientRawSocket> secureSocket({
    bool ignoreCertificateErrors = false,
  }) async {
    throw UnimplementedError();
  }

  @override
  void write(List<int> data, [int offset = 0, int? count]) {
    throw UnimplementedError();
  }

  @override
  Future<void> shutdown(ClientSocketDirection how) {
    throw UnimplementedError();
  }

  @override
  int available() {
    throw UnimplementedError();
  }
}
