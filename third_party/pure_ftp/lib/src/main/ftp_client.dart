import 'dart:async';

import 'package:meta/meta.dart';
import 'package:pure_ftp/src/extensions/ftp_directory_extensions.dart';
import 'package:pure_ftp/src/file_system/entries/ftp_directory.dart';
import 'package:pure_ftp/src/file_system/entries/ftp_file.dart';
import 'package:pure_ftp/src/file_system/entries/ftp_link.dart';
import 'package:pure_ftp/src/file_system/ftp_file_system.dart';
import 'package:pure_ftp/src/ftp/ftp_socket.dart';
import 'package:pure_ftp/src/ftp/ftp_task.dart';
import 'package:pure_ftp/src/main/task_manager_mixin.dart';

typedef LogCallback = void Function(dynamic message);

class FtpClient with TaskManagerMixin {
  final FtpSocketInitOptions _socketInitOptions;
  final FtpAuthOptions _authOptions;
  final LogCallback? _logCallback;
  late final FtpSocket _socket;
  late final FtpFileSystem _fileSystem;

  var _isConnected = false;

  /// Creates a new FTP client.
  /// [socketInitOptions] - options for socket initialization.
  /// [authOptions] - options for authentication.
  /// [logCallback] - callback for logging any ftp operations.
  ///
  /// This class is abstraction over [FtpSocket] and [FtpFileSystem].
  /// It provides simple API for connecting, authenticating and working with FTP server.
  FtpClient({
    required FtpSocketInitOptions socketInitOptions,
    required FtpAuthOptions authOptions,
    LogCallback? logCallback,
  })  : _socketInitOptions = socketInitOptions,
        _authOptions = authOptions,
        _logCallback = logCallback,
        _socket = FtpSocket(
          options: socketInitOptions,
          logCallback: logCallback,
        ) {
    _fileSystem = FtpFileSystem(
      client: this,
    );
  }

  FtpFileSystem get fs => _fileSystem;

  FtpSocket get socket => _socket;

  /// Connects to the FTP server.
  /// And initializes the file system.
  Future<void> connect() async {
    await _socket.connect(_authOptions.username, _authOptions.password);
    await _fileSystem.init();
    _isConnected = true;
  }

  /// Disconnects from the FTP server.
  Future<void> disconnect({bool safe = true}) async {
    await _socket.disconnect(safe: safe);
    _isConnected = false;
  }

  /// verify that client is connected
  Future<bool> isConnected() async =>
      _isConnected && (_isConnected = await _socket.isConnected());

  /// run any ftp task with verification of connection
  FtpTask<T> runSafe<T>({
    required FutureOr<T> Function() task,
  }) =>
      FtpTask(
        task: () async {
          if (!await isConnected()) {
            await connect();
          }
          late T result;
          try {
            result = await task();
          } catch (e) {
            _logCallback?.call(e);
            await disconnect();
            await connect();
            result = await task();
          }
          return result;
        },
      );

  /// Returns file linked to current file system.
  /// [path] - path to the file. if [path] starts with '/'
  /// then it will be treated as absolute path.
  FtpFile getFile(String path) {
    var file = FtpFile(
      path: path,
      client: this,
    );
    if (!file.isAbsolute) {
      file = _fileSystem.currentDirectory.getChildFile(path);
    }
    return file;
  }

  /// Returns directory linked to current file system.
  /// [path] - path to the directory. if [path] starts with '/'
  /// then it will be treated as absolute path.
  FtpDirectory getDirectory(String path) {
    var directory = FtpDirectory(
      path: path,
      client: this,
    );
    if (!directory.isAbsolute) {
      directory = _fileSystem.currentDirectory.getChildDir(path);
    }
    return directory;
  }

  /// Returns link linked to current file system.
  /// [path] - path to the link. if [path] starts with '/'
  /// then it will be treated as absolute path.
  ///
  /// [target] - target of the link.
  FtpLink getLink(String path, String target) {
    var link = FtpLink(
      path: path,
      client: this,
      linkTarget: '',
    );
    if (!link.isAbsolute) {
      final temp = _fileSystem.currentDirectory.getChildFile(path);
      link = FtpLink(
        path: temp.path,
        client: this,
        linkTarget: target,
      );
    }
    return link;
  }

  /// Returns current directory of file system.
  FtpDirectory get currentDirectory => _fileSystem.currentDirectory;

  Future<bool> changeDirectory(String path) async {
    final task = runSafe(
      task: () => _fileSystem.changeDirectory(path),
    );
    await task.run();
    return task.result;
  }

  Future<bool> changeDirectoryUp() async {
    final task = runSafe(
      task: _fileSystem.changeDirectoryUp,
    );
    await task.run();
    return task.result;
  }

  FtpClient clone() {
    final ftpClient = FtpClient(
      socketInitOptions: _socketInitOptions,
      authOptions: _authOptions,
      logCallback: _logCallback == null
          ? null
          : (message) => _logCallback!('copy:$message'),
    );
    return ftpClient;
  }
}

@immutable
class FtpAuthOptions {
  final String username;
  final String password;
  final String? account;

  const FtpAuthOptions({
    required this.username,
    required this.password,
    this.account,
  });
}
