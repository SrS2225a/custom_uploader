import 'dart:io';
import 'package:custom_uploader/utils/response_parser.dart';
import 'package:custom_uploader/utils/show_message.dart';
import 'package:custom_uploader/services/response_logger.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:dio/dio.dart';
import 'package:mime/mime.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'database.dart';

typedef OnUploadProgressCallback = void Function(int sentBytes, int totalBytes);
typedef OnSetStateCallback = void Function(String name);

class FileService {
  static bool shouldAddFile = true;

  static Future<void> fileUploadMultiPart({
    required File file,
    required OnUploadProgressCallback onUploadProgress,
    required OnSetStateCallback onSetState,
    required BuildContext context,
  }) async {
    // Fetch selected uploader
    Box<Share> shareBox = Hive.box<Share>("custom_upload");
    Share? uploader = shareBox.values.firstWhere((share) => share.selectedUploader);

    if (uploader == null) {
      showSnackBar(context, "Please select an uploader first.");
      return;
    } else {
      onSetState(file.path.split("/").last);
    }

    // Perform file upload
    try {
      String mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
      FormData formData = _buildFormData(uploader, file, mimeType);
      Map<String, String> headers = await _getHeaders(uploader);

      await _uploadFile(
        method: uploader.method ?? "POST",
        url: uploader.uploaderUrl,
        headers: headers,
        parameters: uploader.uploadParameters,
        formData: formData,
        onUploadProgress: onUploadProgress,
        context: context,
        uploader: uploader,
      );
      onSetState("");
    } catch (e) {
      onSetState("");
      _handleError(context, e, uploader);
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


  static FormData _buildFormData(Share uploader, File file, String mimeType) {
    MultipartFile filePart = uploader.uploadFormData ?
    MultipartFile.fromBytes(file.readAsBytesSync(), contentType: MediaType.parse(mimeType),
    ) :
    MultipartFile.fromFileSync(file.path, filename: file.path.split("/").last, contentType: MediaType.parse(mimeType));

    FormData formData = FormData.fromMap({uploader.formDataName: filePart});
    uploader.uploadArguments.forEach((key, value) {
      formData.fields.add(MapEntry(key, value));
    });

    return formData;
  }

  static Future<void> _uploadFile({
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
        _handleSuccess(context, uploader, response);
        break;
      case "PUT":
        response = await dio.put(
          url,
          queryParameters: parameters,
          options: Options(headers: headers, followRedirects: false),
          data: formData,
          onSendProgress: onUploadProgress,
        );
        _handleSuccess(context, uploader, response);
        break;
      case "PATCH":
        response = await dio.patch(
        url,
        queryParameters: parameters,
        options: Options(headers: headers, followRedirects: false),
        data: formData,
        onSendProgress: onUploadProgress,
        );
        _handleSuccess(context, uploader, response);
        break;
      default: // POST
        response = await dio.post(
          url,
          queryParameters: parameters,
          options: Options(headers: headers, followRedirects: false),
          data: formData,
          onSendProgress: onUploadProgress,
        );
        _handleSuccess(context, uploader, response);
        break;
    }
  }

  static void _handleSuccess(BuildContext context, Share responseParser, dynamic responseData) {
    Logger.logResponse(
        endpoint: responseParser.uploaderUrl,
        statusCode: responseData?.statusCode,
        responseBody: responseData!.data.toString(),
    );

    String? parsedResponse = parseResponse(responseData.data, responseParser.uploaderResponseParser);
    if (parsedResponse!.isEmpty) {
      showSnackBar(context, "Upload successful");
    } else {
      Clipboard.setData(ClipboardData(text: parsedResponse!));
      showSnackBar(context, "File uploaded successfully as: $parsedResponse. It has been copied to your clipboard.");
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
        errorMessage = "Error transferring to ${uploader.uploaderUrl}: (${error.response?.statusCode}) ${error.response?.statusMessage}";
      } else {
        errorMessage = "Error transferring to ${uploader.uploaderUrl}: (${error.response?.statusCode}) ${error.response?.statusMessage}; $errorMessage";
      }
    } else {
      errorMessage = "Failed to connect to server. Please check your internet connection.";
    }

    showSnackBar(context, errorMessage ?? "Unknown error occurred.");
    print(error);
  }
}