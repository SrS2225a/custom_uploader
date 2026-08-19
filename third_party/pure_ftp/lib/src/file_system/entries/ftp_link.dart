import 'package:pure_ftp/src/file_system/entries/ftp_directory.dart';
import 'package:pure_ftp/src/file_system/entries/ftp_entry.dart';
import 'package:pure_ftp/src/file_system/entries/ftp_file.dart';
import 'package:pure_ftp/src/file_system/ftp_entry_info.dart';
import 'package:pure_ftp/src/main/ftp_client.dart';

class FtpLink extends FtpEntry {
  final String _linkTarget;
  final FtpClient _client;

  const FtpLink({
    required String linkTarget,
    required super.path,
    required super.client,
    super.info,
  })  : _linkTarget = linkTarget,
        _client = client;

  @override
  Future<bool> copy(String newPath) {
    //todo implement later
    throw UnsupportedError('Cannot copy a link');
  }

  @override
  Future<bool> create({bool recursive = false}) {
    //todo implement later
    throw UnsupportedError('Cannot create a link');
  }

  @override
  Future<bool> delete({bool recursive = false}) {
    //todo implement later
    throw UnsupportedError('Cannot delete a link');
  }

  @override
  Future<bool> exists() {
    //todo implement later
    throw UnsupportedError('Cannot check if a link exists');
  }

  @override
  bool get isDirectory => false;

  @override
  Future<FtpEntry> move(String newPath) {
    //todo implement later
    throw UnsupportedError('Cannot move a link');
  }

  @override
  Future<FtpEntry> rename(String newName) {
    //todo implement later
    throw UnsupportedError('Cannot rename a link');
  }

  String get linkTargetPath => _linkTarget;

  Future<FtpEntry> get linkTarget async {
    final isDir = await _client.fs.testDirectory(_linkTarget);
    if (isDir) {
      return FtpDirectory(path: _linkTarget, client: _client);
    } else {
      return FtpFile(path: _linkTarget, client: _client);
    }
  }

  FtpLink copyWith({
    String? path,
    String? linkTarget,
    FtpEntryInfo? info,
  }) {
    return FtpLink(
      path: path ?? this.path,
      linkTarget: linkTarget ?? _linkTarget,
      info: info ?? this.info,
      client: _client,
    );
  }

  @override
  String toString() {
    return 'FtpLink{linkTarget: $_linkTarget, path: $path}';
  }
}
