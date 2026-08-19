import 'package:pure_ftp/src/ftp/ftp_commands.dart';
import 'package:pure_ftp/src/ftp/ftp_response.dart';
import 'package:pure_ftp/src/ftp/ftp_socket.dart';

extension FtpCommandExtension on FtpCommand {
  void write(FtpSocket socket, [List<String>? args]) {
    socket.write(
      [
        name,
        ...?args?.map((e) => e.toString()),
      ].join(' '),
    );
  }

  Future<FtpResponse> writeAndRead(FtpSocket socket, [List<String>? args]) {
    write(socket, args);
    return socket.read();
  }

//todo check usage
// Future<FtpResponse> writeAndListen(FtpSocket s, [List<String>? args]) {
//   return s.openTransferChannel<FtpResponse>((socketFuture, log) async {
//     write(s, args);
//     final socket = await socketFuture;
//     final response = await s.read();
//     final bool transferCompleted = response.isSuccessfulForDataTransfer;
//     if (!transferCompleted) {
//       return response;
//     }
//     final List<int> data = [];
//     await socket.listen(data.addAll).asFuture();
//     final message = String.fromCharCodes(data);
//     log?.call(message);
//     return FtpResponse(code: response.code, message: message);
//   });
// }
}
