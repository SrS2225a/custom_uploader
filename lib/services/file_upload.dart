import 'dart:io';
import 'dart:math';
import 'package:custom_uploader/services/pgp_service.dart';
import 'package:custom_uploader/services/share_target_resolver.dart';
import 'package:custom_uploader/utils/response_parser.dart';
import 'package:custom_uploader/utils/show_message.dart';
import 'package:custom_uploader/services/response_logger.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:dio/dio.dart';
import 'package:pure_ftp/pure_ftp.dart';
import 'package:mime/mime.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:custom_uploader/l10n/app_localizations.dart';

import 'dart:async';

import 'database.dart';

typedef OnUploadProgressCallback = void Function(int sentBytes, int totalBytes);
typedef IsEncryptingCallback = void Function(bool isEncrypting);

class CustomFtpUploadResult {
  final bool success;
  final String? errorMessage;
  final int uploadedBytes;
  final FtpResponse? initialResponse;

  CustomFtpUploadResult({
    required this.success,
    this.errorMessage,
    this.uploadedBytes = 0,
    this.initialResponse,
  });
}

// for some reason the uploadFileStream from pure_ftp
// does not give back status codes and error messages after
// an upload so I have to do it myself using an custom implementation.
// *Sigh* why does pure_ftp not already expose the FtpReponse? Lame
Future<CustomFtpUploadResult> uploadFtpFile({
  required FtpClient ftpClient,
  required FtpFile targetFile,
  required Stream<List<int>> fileData,
  required int fileSize,
  bool append = false,
  OnTransferProgress? onUploadProgress,
}) async {
  final socketLayer = ftpClient.socket;
  int uploaded = 0;

  try {
    return await socketLayer.openTransferChannel((socketFuture, log) async {
      // Send STOR or APPE command
      (append ? FtpCommand.APPE : FtpCommand.STOR).write(socketLayer, [targetFile.path]);

      final transferSocket = await socketFuture;
      final initialResponse = await socketLayer.read();

      if (!initialResponse.isSuccessfulForDataTransfer) {
        return CustomFtpUploadResult(
          success: false,
          errorMessage: 'Upload refused: ${initialResponse.message}',
          initialResponse: initialResponse,
        );
      }

      final byteStream = fileData.transform<Uint8List>(
        StreamTransformer.fromHandlers(
          handleData: (chunk, sink) {
            final bytes = Uint8List.fromList(chunk);
            uploaded += bytes.length;
            final total = max(fileSize, uploaded);
            onUploadProgress?.call(uploaded, total, uploaded / total * 100);
            sink.add(bytes);
          },
        ),
      );

      await transferSocket.addSteam(byteStream);
      await transferSocket.flush;
      await transferSocket.close(ClientSocketDirection.readWrite);

      final finalResponse = await socketLayer.read();
      final success = finalResponse.isSuccessful;

      return CustomFtpUploadResult(
        success: success,
        errorMessage: success ? null : 'Final response: ${finalResponse.message}',
        uploadedBytes: uploaded,
        initialResponse: initialResponse,
      );
    });
  } catch (e) {
    return CustomFtpUploadResult(
      success: false,
      errorMessage: 'Exception: $e',
      uploadedBytes: uploaded,
      initialResponse: null,
    );
  }
}

class FileService {
  static bool shouldAddFile = true;

  static Future<String?> fileUploadMultiPart({
    required File file,
    required OnUploadProgressCallback setOnUploadProgress,
    required IsEncryptingCallback setOnEncrypting,
    required BuildContext context,
    required ShareTarget target,
  }) async {
    Share? uploader = target.http;
    NetworkShare? networkUploader = target.network;

    // Perform file upload
    if(uploader != null) {
      try {
        String mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
        FormData formData = await _buildFormData(uploader, file, mimeType, setOnEncrypting);
        Map<String, String> headers = await _getHeaders(uploader);

        return await _uploadFile(
          method: uploader.method ?? "POST",
          url: uploader.uploaderUrl,
          headers: headers,
          parameters: uploader.uploadParameters,
          formData: formData,
          onUploadProgress: setOnUploadProgress,
          context: context,
          uploader: uploader,
        );
      } catch (e) {
        _handleError(context, e, uploader);
        return null;
      }
    } else if (networkUploader != null) {
      final socketInitOptions = FtpSocketInitOptions(host: networkUploader.domain, port: networkUploader.port);
      final authOptions = FtpAuthOptions(username: networkUploader.username, password: networkUploader.password);
      final client = FtpClient(socketInitOptions: socketInitOptions, authOptions: authOptions);

      try {
        await client.connect();

        final remotePath = networkUploader.folderPath.isEmpty ? "/" : networkUploader.folderPath;
        final remoteFilename = networkUploader.pgpPublicKey != null
            ? "${file.path.split("/").last}.pgp"
            : file.path.split("/").last;
        final ftpFile = FtpFile(path: remotePath.endsWith("/") ? remotePath + remoteFilename : "$remotePath/$remoteFilename}", client: client);

        final encryptedStream = encryptPgpStream(
          file.openRead(),
          networkUploader.pgpPublicKey,
            setOnEncrypting
        );

        final encryptedSize = networkUploader.pgpPublicKey != null
            ? null // unknown after encryption
            : await file.length();

        final result = await uploadFtpFile(
          ftpClient: client,
          targetFile: ftpFile,
          fileData: encryptedStream,
          fileSize: encryptedSize ?? 0,
          onUploadProgress: (sent, total, percent) {
            setOnUploadProgress(sent, total);
          },
        );

        await client.disconnect();

        if (result.success) {
          final ftpUrl = (networkUploader.urlPath?.endsWith("/") ?? false
              ? networkUploader.urlPath!
              : "${networkUploader.urlPath!}/") + file.path.split("/").last;

          Logger.logResponse(
            endpoint: networkUploader.domain,
            statusCode: result.initialResponse?.code ?? 200,
            responseBody: ftpUrl,
          );

          if (ftpUrl.isEmpty) {
            return "";
          } else {
            return ftpUrl;
          }
        } else {
          showSnackBar(
            context,
            result.errorMessage ?? AppLocalizations.of(context)!.upload_failed_unexpectedly,
          );

          Logger.logResponse(
            endpoint: networkUploader.domain,
            statusCode: result.initialResponse?.code ?? 500,
            responseBody: result.errorMessage ?? AppLocalizations.of(context)!.upload_error_unknown,
          );
          return null;
        }
      } catch(error) {
        showSnackBar(
          context,
          AppLocalizations.of(context)!.upload_error_with_message(networkUploader.domain, error.toString()));
        Logger.logResponse(
          endpoint: networkUploader.domain,
          statusCode: 500,
          responseBody: error.toString(),
      );
        print(error);
        return null;
      }
    } else {
      return null;
    }
  }

  static Future<Map<String, String>> _getHeaders(Share uploader) async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String appVersion = packageInfo.version;

    return {
      ...uploader.uploadHeaders,
      "User-Agent": "CustomUploader/$appVersion (https://github.com/SrS2225a/custom_uploader)",
    };
  }

  static Future<FormData> _buildFormData(Share uploader, File file, String mimeType, IsEncryptingCallback setOnEncrypting) async {
    Uint8List bytes = await file.readAsBytes();
    bytes = await encryptPgpBytes(bytes, uploader.pgpPublicKey,  setOnEncrypting);

    final filename =  uploader.pgpPublicKey != null
        ? "${file.path.split("/").last}.asc"
        : file.path.split("/").last;

    MultipartFile filePart = MultipartFile.fromBytes(
      bytes,
      filename: filename,
      contentType: MediaType.parse(
        uploader.pgpPublicKey  != null
            ? 'application/pgp-encrypted'
            : mimeType,
      ),
    );

    FormData formData = FormData.fromMap({
      uploader.formDataName: filePart,
    });

    uploader.uploadArguments.forEach((key, value) {
      formData.fields.add(MapEntry(key, value));
    });

    return formData;
  }

  static Future<String?>  _uploadFile({
    required String method,
    required String url,
    required Map<String, String> headers,
    required Map<String, dynamic>? parameters,
    required FormData formData,
    required OnUploadProgressCallback onUploadProgress,
    required BuildContext context,
    required Share uploader,
  }) async {
    Dio dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));
    Response response;

    switch (method.toUpperCase()) {
      case "GET":
        response = await dio.get(
          url,
          queryParameters: parameters,
          options: Options(headers: headers, followRedirects: false),
          data: formData,
        );
        return _handleSuccess(context, uploader, response);
      case "PUT":
        response = await dio.put(
          url,
          queryParameters: parameters,
          options: Options(headers: headers, followRedirects: false),
          data: formData,
          onSendProgress: onUploadProgress,
        );
        return  _handleSuccess(context, uploader, response);
      case "PATCH":
        response = await dio.patch(
        url,
        queryParameters: parameters,
        options: Options(headers: headers, followRedirects: false),
        data: formData,
        onSendProgress: onUploadProgress,
        );
        return _handleSuccess(context, uploader, response);
      default: // POST
        response = await dio.post(
          url,
          queryParameters: parameters,
          options: Options(headers: headers, followRedirects: false),
          data: formData,
          onSendProgress: onUploadProgress,
        );
        return _handleSuccess(context, uploader, response);
    }
  }

  static String? _handleSuccess(BuildContext context, Share responseParser, dynamic responseData) {
    Logger.logResponse(
        endpoint: responseParser.uploaderUrl,
        statusCode: responseData?.statusCode,
        responseBody: responseData!.data.toString(),
    );

    String? parsedResponse = parseResponse(responseData.data, responseParser.uploaderResponseParser);
    if (parsedResponse!.isEmpty) {
      return "";
    } else {
      return parsedResponse;
    }
  }

  static void _handleError(BuildContext context, dynamic error, Share uploader) {
    String? errorMessage;

    if (error is DioException && error.response?.data != null) {
      Logger.logResponse(
          endpoint: uploader.uploaderUrl,
          statusCode: error.response?.statusCode,
          responseBody: error.response!.data.toString(),
      );

      errorMessage = parseResponse(error.response?.data, uploader.uploaderErrorParser);
      if (errorMessage!.isEmpty) {
        errorMessage = AppLocalizations.of(context)!.upload_error_message(error.response?.statusCode as Object, error.response?.statusMessage as Object, uploader.uploaderUrl);
      } else {
        errorMessage = AppLocalizations.of(context)!.upload_error_message_with_details(errorMessage, error.response?.statusCode as Object, error.response?.statusMessage as Object, uploader.uploaderUrl);
      }
    } else {
      errorMessage = AppLocalizations.of(context)!.failed_to_connect;
    }

    showSnackBar(context, errorMessage);
    print(error);
  }
}
