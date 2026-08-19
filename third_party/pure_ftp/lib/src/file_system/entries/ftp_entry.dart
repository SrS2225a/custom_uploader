import 'package:meta/meta.dart';
import 'package:pure_ftp/src/file_system/entries/ftp_directory.dart';
import 'package:pure_ftp/src/file_system/entries/ftp_file.dart';
import 'package:pure_ftp/src/file_system/entries/ftp_link.dart';
import 'package:pure_ftp/src/file_system/ftp_entry_info.dart';
import 'package:pure_ftp/src/main/ftp_client.dart';

@immutable
abstract class FtpEntry {
  final String path;
  final FtpEntryInfo? info;
  @protected
  final FtpClient _client;

  const FtpEntry({required this.path, required FtpClient client, this.info})
      : _client = client;

  FtpDirectory get parent => FtpDirectory(
      path: path.split('/').sublist(0, path.split('/').length - 1).join('/'),
      client: _client);

  String get name => path.split('/').last;

  bool get isAbsolute => path.startsWith('/');

  bool get isDirectory;

  bool get isFile => !isDirectory;

  Future<bool> exists();

  Future<bool> create({bool recursive = false});

  Future<bool> delete({bool recursive = false});

  Future<FtpEntry> rename(String newName);

  Future<bool> copy(String newPath);

  Future<FtpEntry> move(String newPath);

  T as<T extends FtpEntry>() {
    if (this is T) {
      return this as T;
    }
    switch (T) {
      case FtpDirectory:
        return FtpDirectory(path: path, client: _client) as T;
      case FtpFile:
        return FtpFile(path: path, client: _client) as T;
      case FtpLink:
        return FtpLink(
          path: path,
          client: _client,
          linkTarget: '__unknown__${path.hashCode ^ _client.hashCode}',
        ) as T;
      default:
        throw UnsupportedError('Cannot cast to $T');
    }
  }

  @override
  String toString() {
    return 'FtpEntry{name: $name, path: $path}';
  }
}
