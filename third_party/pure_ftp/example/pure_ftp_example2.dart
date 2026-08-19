import 'dart:io';

import 'package:pure_ftp/src/ftp/ftp_socket.dart';
import 'package:pure_ftp/src/main/ftp_client.dart';
import 'package:yaml/yaml.dart';

void main() async {
  var configFile = File('test_connection4.yml');
  if (!configFile.existsSync()) {
    configFile = File('default_connection.yml');
  }
  final config = loadYaml(await configFile.readAsString());
  final client = FtpClient(
    socketInitOptions: FtpSocketInitOptions(
        host: config['host'],
        port: config['port'],
        transferMode: const FtpTransferMode.active(
          host: 'localhost',
          port: 3030,
        )),
    authOptions: FtpAuthOptions(
      username: config['username'],
      password: config['password'],
      account: config['account'],
    ),
    logCallback: print,
  );
  await client.connect();
  await client.socket.setTransferType(FtpTransferType.binary);
  await client.fs.listDirectory();

  await client.disconnect();
}
