import 'dart:io';

import 'package:pure_ftp/pure_ftp.dart';
import 'package:yaml/yaml.dart';

void main() async {
  final configFile = File('default_connection.yml');

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
    logCallback: print,
  );
  await client.connect();

  await client.currentDirectory.listNames().then(print);

  await _getDirList(client);
  try {
    client.fs.listType = ListType.MLSD;
    await _getDirList(client);
  } catch (e) {
    // maybe server doesn't support MLSD
    print(e);
  }

  await client.disconnect();
}

Future<void> _getDirList(FtpClient client) async {
  final list = await client.fs.listDirectory();
  list.forEach(print);
  for (final entry in list) {
    if (entry is FtpLink) {
      print('LinkTarget: ${entry.path} -> ${await entry.linkTarget}');
    }
  }
}
