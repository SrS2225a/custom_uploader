import 'dart:io';

import 'package:pure_ftp/pure_ftp.dart';
import 'package:yaml/yaml.dart';

void main() async {
  final configFile = File('test_connection2.yml');
  final config = loadYaml(await configFile.readAsString());
  final client = FtpClient(
    socketInitOptions: FtpSocketInitOptions(
      host: config['host'],
      port: config['port'],
    ),
    authOptions: FtpAuthOptions(
      username: config['username'],
      password: config['password'],
      account: config['account'],
    ),
  );
  await client.connect();

  await client.changeDirectory(
      '/capscraft.com/repo/modstore/mods/012042e4d2c8124c006e60b56204b675871390bb/1.10');

  await client.currentDirectory.listNames().then(print);

  print(await client
      .getFile('012042e4d2c8124c006e60b56204b675871390bb-1.10.jar')
      .size());
  await client.disconnect();
}
