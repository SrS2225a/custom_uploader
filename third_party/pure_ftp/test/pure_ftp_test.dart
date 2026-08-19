import 'dart:io';

import 'package:pure_ftp/src/ftp/ftp_socket.dart';
import 'package:pure_ftp/src/main/ftp_client.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() async {
  var configFile = File('test_connection.yml');
  if (!configFile.existsSync()) {
    configFile = File('default_connection.yml');
  }
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
  test('connection test', () async {
    await client.connect();
  });

  test('directory operations test', () async {
    var ftpDirectory = client.getDirectory('test');
    var boolResponse = await ftpDirectory.create();
    expect(boolResponse, true);
    var dirResponse = await ftpDirectory.rename('test1');
    expect(dirResponse.path, '/test1');
    ftpDirectory = dirResponse;
    dirResponse = await ftpDirectory.move('/test2');
    expect(dirResponse.path, '/test2');
    boolResponse = await dirResponse.delete();
    expect(boolResponse, true);
  });

  test('file system test', () async {
    final result = await client.currentDirectory.list();
    result.forEach(print);
  });

  if (config['active_host'] != null) {
    test('file system test in active mode', () async {
      client.socket.transferMode = FtpTransferMode.active(
        host: config['active_host'],
        port: int.tryParse(config['active_port'].toString()),
      );
      final result = await client.currentDirectory.list();
      result.forEach(print);
    });
  }
  client.socket.transferMode = FtpTransferMode.passive;

  test('disconnect test', () async {
    await client.disconnect();
  });
}
