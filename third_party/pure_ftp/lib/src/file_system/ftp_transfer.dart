import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:pure_ftp/src/file_system/entries/ftp_file.dart';
import 'package:pure_ftp/src/ftp/exceptions/ftp_exception.dart';
import 'package:pure_ftp/src/ftp/extensions/ftp_command_extension.dart';
import 'package:pure_ftp/src/ftp/ftp_commands.dart';
import 'package:pure_ftp/src/ftp/ftp_socket.dart';
import 'package:pure_ftp/src/socket/common/client_raw_socket.dart';

typedef OnTransferProgress = Function(int bytes, int total, double percents);

class FtpTransfer {
  final FtpSocket _socket;

  FtpTransfer({
    required FtpSocket socket,
  }) : _socket = socket;

  Stream<List<int>> downloadFileStream(
    FtpFile file, {
    int restSize = 0,
    OnTransferProgress? onReceiveProgress,
  }) {
    final stream = StreamController<List<int>>();
    unawaited(
      Future.sync(
        () async {
          final fileSize = await file.size();
          await _socket.openTransferChannel(
            (socketFuture, log) async {
              if (restSize > 0) {
                if (restSize > fileSize && fileSize > 0) {
                  throw FtpException(
                    'restSize more than file size. fileSize:$fileSize, restSize:$restSize',
                  );
                }
                await FtpCommand.TYPE
                    .writeAndRead(_socket, [FtpTransferType.binary.type]);
                final ret =
                    await FtpCommand.REST.writeAndRead(_socket, ['$restSize']);
                if (ret.code >= 400) {
                  throw FtpException(ret.message);
                }
              }
              FtpCommand.RETR.write(
                _socket,
                [file.path],
              );
              final dataSocket = await socketFuture;
              final response = await _socket.read();

              // wait 125 || 150 and >200 that indicates the end of the transfer
              final bool transferCompleted =
                  response.isSuccessfulForDataTransfer;
              if (!transferCompleted) {
                throw FtpException('Error while downloading file');
              }
              var downloaded = 0;
              await dataSocket.listenAsync(
                (event) {
                  stream.add(event);
                  downloaded += event.length;
                  final total = max(fileSize, downloaded);
                  onReceiveProgress?.call(
                      downloaded, total, downloaded / total * 100);
                  log?.call('Downloaded $downloaded of $total bytes');
                },
              );
              await stream.close();
            },
            (error, stackTrace) {
              stream.addError(error, stackTrace);
              stream.close();
            },
          );
        },
      ),
    );
    return stream.stream;
  }

  Future<bool> uploadFileStream(
    FtpFile file,
    Stream<List<int>> data,
    int fileSize, {
    bool append = false,
    OnTransferProgress? onUploadProgress,
  }) =>
      _socket.openTransferChannel((socketFuture, log) async {
        (append ? FtpCommand.APPE : FtpCommand.STOR).write(
          _socket,
          [file.path],
        );
        final socket = await socketFuture;
        final response = await _socket.read();

        // wait 125 || 150 and >200 that indicates the end of the transfer
        final bool transferCompleted = response.isSuccessfulForDataTransfer;
        if (!transferCompleted) {
          throw FtpException('Error while uploading file');
        }
        var uploaded = 0;
        final transform = data.transform<Uint8List>(
          StreamTransformer.fromHandlers(
            handleData: (event, sink) {
              sink.add(Uint8List.fromList(event));
              uploaded += event.length;
              final total = max(fileSize, uploaded);
              onUploadProgress?.call(uploaded, total, uploaded / total * 100);
              log?.call('Uploaded $uploaded of $total bytes');
            },
          ),
        );
        await socket.addSteam(transform);
        await socket.flush;
        await socket.close(ClientSocketDirection.readWrite);
        final response2 = await _socket.read();
        return response2.isSuccessful;
      });
}
