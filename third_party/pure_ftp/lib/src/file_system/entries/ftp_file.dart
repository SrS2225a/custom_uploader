import 'dart:async';

import 'package:pure_ftp/src/extensions/ftp_directory_extensions.dart';
import 'package:pure_ftp/src/file_system/entries/ftp_entry.dart';
import 'package:pure_ftp/src/file_system/ftp_entry_info.dart';
import 'package:pure_ftp/src/ftp/exceptions/ftp_exception.dart';
import 'package:pure_ftp/src/ftp/extensions/ftp_command_extension.dart';
import 'package:pure_ftp/src/ftp/ftp_commands.dart';
import 'package:pure_ftp/src/main/ftp_client.dart';

class FtpFile extends FtpEntry {
  final FtpClient _client;

  const FtpFile({
    required super.path,
    required super.client,
    super.info,
  }) : _client = client;

  @override
  Future<bool> copy(String newPath) async {
    if (path == newPath) {
      return true;
    }
    if (!await exists()) {
      throw FtpException('File does not exist');
    }
    final fileTo = _client.getFile(newPath);
    if (!await fileTo.parent.exists()) {
      throw FtpException('Destination directory does not exist');
    }
    final secondClient = _client.clone();
    await secondClient.connect();
    await secondClient.socket.setTransferType(_client.socket.transferType);
    secondClient.socket.transferMode = _client.socket.transferMode;
    var result = false;
    try {
      final downloadFileStream = _client.fs.downloadFileStream(this);
      //todo search way to provide file size if necessary
      final uploadStream =
          secondClient.fs.uploadFileFromStream(fileTo, downloadFileStream, 0);
      result = await uploadStream;
    } finally {
      try {
        await secondClient.disconnect();
      } catch (e) {
        //ignore
      }
    }
    return result;
  }

  @override
  Future<bool> create({bool recursive = false}) async {
    if (!await parent.exists()) {
      if (recursive) {
        await parent.create(recursive: true);
      } else {
        throw FtpException('Parent directory does not exist');
      }
    }
    return _client.fs.uploadFile(this, []);
  }

  @override
  Future<bool> delete({bool recursive = false}) async {
    final response = await FtpCommand.DELE.writeAndRead(_client.socket, [path]);
    return response.isSuccessful;
  }

  @override
  Future<bool> exists() async {
    final response = await FtpCommand.SIZE.writeAndRead(_client.socket, [path]);
    return response.isSuccessful;
  }

  Future<int> size() async {
    final response = await FtpCommand.SIZE.writeAndRead(_client.socket, [path]);
    if (!response.isSuccessful) {
      return -1;
    }
    return int.tryParse(response.message.substring(4)) ?? -1;
  }

  @override
  bool get isDirectory => false;

  @override
  Future<FtpFile> move(String newPath) async {
    final newFile = newPath.startsWith(_client.fs.rootDirectory.path)
        ? FtpFile(path: newPath, client: _client)
        : parent.getChildFile(newPath);
    if (newFile.path == path) {
      return this;
    }
    if (!await newFile.parent.exists()) {
      throw FtpException('Parent directory of new file does not exist');
    }
    final response = await FtpCommand.RNFR.writeAndRead(_client.socket, [path]);
    if (!response.isSuccessful) {
      throw FtpException('Cannot move file');
    }
    final response2 =
        await FtpCommand.RNTO.writeAndRead(_client.socket, [newFile.path]);
    if (!response2.isSuccessful) {
      throw FtpException('Cannot move file');
    }
    return newFile;
  }

  @override
  Future<FtpFile> rename(String newName) async {
    if (newName.contains('/')) {
      throw FtpException('New name cannot contain path separator');
    }
    final newFile = parent.getChildFile(newName);
    if (newFile.path == path) {
      return this;
    }
    if (!await newFile.parent.exists()) {
      throw FtpException('Parent directory of new file does not exist');
    }
    final response = await FtpCommand.RNFR.writeAndRead(_client.socket, [path]);
    if (!response.isSuccessful) {
      throw FtpException('Cannot rename file');
    }
    final response2 =
        await FtpCommand.RNTO.writeAndRead(_client.socket, [newFile.path]);
    if (!response2.isSuccessful) {
      throw FtpException('Cannot rename file');
    }
    return newFile;
  }

  FtpFile copyWith({
    String? path,
    FtpEntryInfo? info,
  }) {
    return FtpFile(
      path: path ?? this.path,
      info: info ?? this.info,
      client: _client,
    );
  }

  @override
  String toString() {
    return 'FtpFile(path: $path)';
  }
}
