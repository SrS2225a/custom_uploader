import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dart_pg/dart_pg.dart';

import '../utils/show_message.dart';

Future<String?> importPgpKeyFromFile(FilePickerResult? result, BuildContext context) async {
  if (result == null || result.files.single.path == null) return null;

  final content = await File(result.files.single.path!).readAsString();
  final isValid = await _cryptoValidateKey(content);
  if(isValid) {
    return content.trim();
  } else {
    showSnackBar(
      context,
      'Invalid PGP key',
    );
    return null;
  }
}

Future<bool> _cryptoValidateKey(String key) async {
  return key.contains('BEGIN PGP PUBLIC KEY BLOCK');
}

Future<String?> generateNewPgpKey(BuildContext context, String uploaderName) async {
  final nameCtl = TextEditingController();
  final emailCtl = TextEditingController();
  final passCtl = TextEditingController();

  final confirmed = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Generate New PGP Key'),
          content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtl, decoration: InputDecoration(labelText: 'Name')),
                TextField(controller: emailCtl, decoration: InputDecoration(labelText: 'Email')),
                TextField(controller: passCtl, decoration: InputDecoration(labelText: 'Password' ), obscureText: true),
              ]
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Confirm'),
            ),
          ],
        );}
  );

  if(confirmed) {
    try {
      final userId = [
        nameCtl.text,
        '<${emailCtl.text}>',
      ].join(' ');

      final privateKey = OpenPGP.generateKey(
        [userId],
        passCtl.text,
        type: KeyType.curve25519,
      );

      await _offerPrivateKeyExport(context, privateKey.armor(), uploaderName);

      return privateKey.publicKey.armor();
    } catch (e) {
      showSnackBar(context, 'Key generation failed: $e');
      return null;
    }
  }
  return null;
}

Future<void> _offerPrivateKeyExport(BuildContext context, String privateKey, String uploaderName) async {
  final confirmed = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Export Private Key'),
          content: Text('Do you want to export the private key?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Export'),
            ),
          ],
        );
      }
  );
  if (confirmed) {
    final path = await FilePicker.platform.saveFile(fileName: 'private_key-$uploaderName-${DateTime.now()}.asc', bytes: Uint8List.fromList(privateKey.codeUnits));

    if (path != null) {
      await File(path).writeAsString(privateKey);
    }
  }
}


Future<Uint8List> encryptPgpBytes(
    Uint8List data,
    String? armoredPublicKey,
    void Function(bool isEncrypting) isEncrypting
    ) async {
  if (armoredPublicKey == null || armoredPublicKey.isEmpty) {
    return data;
  }

  // Offload to background isolate
  isEncrypting.call(true);
  final result = await compute(_encryptPgpBytesIsolate, {
    'data': data,
    'publicKey': armoredPublicKey,
  });
  isEncrypting.call(false);
  return result;
}

Stream<List<int>> encryptPgpStream(
    Stream<List<int>> data,
    String? armoredPublicKey,
    void Function(bool isEncrypting) isEncrypting
    ) async* {
  if (armoredPublicKey == null || armoredPublicKey.isEmpty) {
    yield* data;
    return;
  }

  // Collect all chunks into a single Uint8List
  final buffer = BytesBuilder();
  await for (final chunk in data) {
    buffer.add(chunk);
  }
  final bytes = buffer.toBytes();

  // Offload encryption to a background isolate
  isEncrypting.call(true);
  final Uint8List encryptedBytes = await compute(_encryptPgpBytesIsolate, {
    'data': bytes,
    'publicKey': armoredPublicKey,
  });
  isEncrypting.call(false);

  // Yield the encrypted data as a single chunk
  yield encryptedBytes;
}

Future<Uint8List> _encryptPgpBytesIsolate(Map<String, dynamic> args) async {
  final Uint8List data = args['data'];
  final String armoredPublicKey = args['publicKey'];

  final publicKey = OpenPGP.readPublicKey(armoredPublicKey);
  final encrypted = OpenPGP.encryptBinaryData(data, encryptionKeys: [publicKey]);
  final armored = encrypted.armor();

  return Uint8List.fromList(utf8.encode(armored));
}