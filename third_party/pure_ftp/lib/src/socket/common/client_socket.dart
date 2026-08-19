import 'dart:async';
import 'dart:typed_data';

import 'package:pure_ftp/src/socket/common/client_socket_direction.dart';
import 'package:pure_ftp/src/socket/html/client_socket.dart'
    if (dart.library.io) 'package:pure_ftp/src/socket/io/client_socket.dart';

export 'package:pure_ftp/src/socket/common/client_socket_direction.dart';

abstract class ClientSocket {
  static Future<ClientSocket> connect(String host, int port,
      {Duration? timeout}) async {
    final result = ClientSocketImpl();
    await result.connect(host, port, timeout: timeout);
    return result;
  }

  StreamSubscription<Uint8List> listen(
    void Function(Uint8List event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  });

  Future<void> listenAsync(
    void Function(Uint8List event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  });

  void add(Uint8List data);

  void write(
    List<int> data, [
    int offset = 0,
    int? count,
  ]);

  Future<dynamic> addSteam(Stream<List<int>> stream);

  Future<void> close(ClientSocketDirection how);

  Future<dynamic> get done;

  Future<bool> get isEmpty;

  Future<bool> get isNotEmpty => isEmpty.then((value) => !value);

  Future<dynamic> get flush;
}
