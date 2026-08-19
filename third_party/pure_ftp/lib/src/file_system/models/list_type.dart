import 'package:pure_ftp/src/ftp/ftp_commands.dart';

enum ListType {
  // ignore: constant_identifier_names
  LIST(FtpCommand.LIST),
  // ignore: constant_identifier_names
  MLSD(FtpCommand.MLSD),
  ;

  final FtpCommand command;

  const ListType(this.command);
}
