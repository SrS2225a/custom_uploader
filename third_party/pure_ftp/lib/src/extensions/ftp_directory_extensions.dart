import 'package:pure_ftp/src/file_system/entries/ftp_directory.dart';
import 'package:pure_ftp/src/file_system/entries/ftp_file.dart';

extension FtpDirectoryGet on FtpDirectory {
  FtpDirectory getChildDir(String path) => copyWith(
        path: ''
            '${this.path}'
            '${this.path.endsWith('/') || path.startsWith('/') ? '' : '/'}'
            '$path',
      );

  FtpFile getChildFile(String path) => getChildDir(path).as();
}
