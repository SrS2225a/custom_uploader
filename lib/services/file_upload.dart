import 'dart:io';

import 'package:custom_uploader/utils/response_parser.dart';
import 'package:custom_uploader/utils/show_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:dio/dio.dart';

import 'database.dart';

typedef OnUploadProgressCallback = void Function(int sentBytes, int totalBytes);
typedef OnSetStateCallback = void Function(String name);

class FileService {

  static bool shouldAddFile = true;

    static fileUploadMultiPart (
        {required File file, required OnUploadProgressCallback onUploadProgress, required OnSetStateCallback onSetState, required BuildContext context}) async {
        // finds the selected uploader that the user wants to use
        Box<Share> shareBox = Hive.box<Share>("custom_upload");
        var cursor = shareBox.toMap();
        late Share data;
        bool found = false;
        for (var entry in cursor.entries) {
          if (entry.value.selectedUploader) {
            data = entry.value;
            found = true;
            break;
          }
        }

        if (found) {
          final url = data.uploaderUrl;

          onSetState(file.path.split("/").last);
          Map<String, String>? headers = Map.from(data.uploadHeaders ?? {});
          headers.addEntries([const MapEntry("User-Agent", "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36")]);

          getCorrectFormData(bool uploadFormData) {
            if (uploadFormData) {
              // for if the server expects bytes instead of a file
              return FormData.fromMap({
                data.formDataName: MultipartFile.fromBytes(file.readAsBytesSync())
              });
            } else {
              // for if the server expects a file
              return FormData.fromMap({
                data.formDataName: MultipartFile.fromFileSync(file.path, filename: file.path.split("/").last)
              }); // FormData.formMap
            }
          }

          // load body arguments
          var formData = getCorrectFormData(data.uploadFormData);
          for (var cell in data.uploadArguments.entries) {
            formData.fields.add(MapEntry(cell.key, cell.value));
          }

          // uploads file to the chosen server with the chosen parameters
          String? parseAs;
          if(data.method == "GET") {
            try {
              await Dio().get(
                url,
                queryParameters: data.uploadParameters,
                options: Options(
                  headers: headers,
                  followRedirects: false,
                ),
                data: formData,
              ).then((value) =>
              {
                onSetState(""),
                parseAs = parseResponse(value.data, data.uploaderResponseParser),
                // tries to parse the url response, if it fails, it will just show that it was successful
                if (parseAs == "") {
                  showSnackBar(context, "Upload successful"),
                } else
                  {
                    Clipboard.setData(ClipboardData(text: parseAs ?? 'default')),
                    showSnackBar(context, "File upload successfully as: $parseAs. It has been copied to your clipboard")
                  }
              });
            } on DioException catch (error) {
              onSetState("");
              if (error.response?.data != null) {
                parseAs = parseResponse(error.response?.data, data
                    .uploaderErrorParser); // tries to parse the error response, if it fails, it will just show the error
                if (parseAs == "") {
                  showSnackBar(context, "Error transferring to $url: (${error.response?.statusCode}) ${error.response?.statusMessage}");
                } else {
                  showSnackBar(context, "Error transferring to $url: (${error.response?.statusCode}) ${error.response?.statusMessage}; $parseAs");
                }
              } else {
                showSnackBar(context, "Failed to connect to server. Please check your internet connection.");
              }
              print(error);
            }
          } else if (data.method == "PUT") {
            try {
              await Dio().put(
                url,
                queryParameters: data.uploadParameters,
                options: Options(
                  headers: headers,
                  followRedirects: false,
                ),
                data: formData,
                onSendProgress: (int sent, int total) {
                  onUploadProgress(sent, total);
                },
              ).then((value) =>
              {
                onSetState(""),
                parseAs = parseResponse(value.data, data.uploaderResponseParser),
                // tries to parse the url response, if it fails, it will just show that it was successful
                if (parseAs == "") {
                  showSnackBar(context, "Upload successful"),
                } else
                  {
                    Clipboard.setData(ClipboardData(text: parseAs ?? 'default')),
                    showSnackBar(context, "File upload successfully as: $parseAs. It has been copied to your clipboard")
                  }
              });
            } on DioException catch (error) {
              onSetState("");
              if (error.response?.data != null) {
                parseAs = parseResponse(error.response?.data, data
                    .uploaderErrorParser); // tries to parse the error response, if it fails, it will just show the error
                if (parseAs == "") {
                  showSnackBar(context, "Error transferring to $url: (${error.response?.statusCode}) ${error.response?.statusMessage}");
                } else {
                  showSnackBar(context, "Error transferring to $url: (${error.response?.statusCode}) ${error.response?.statusMessage}; $parseAs");
                }
              } else {
                showSnackBar(context, "Failed to connect to server. Please check your internet connection.");}
              print(error);
            }
          } else {
            try {
              await Dio().post(
                url,
                queryParameters: data.uploadParameters,
                options: Options(
                  headers: headers,
                  followRedirects: false,
                ),
                data: formData,
                onSendProgress: (int sent, int total) {
                  onUploadProgress(sent, total);
                },
              ).then((value) =>
              {
                onSetState(""),
                parseAs = parseResponse(value.data, data.uploaderResponseParser),
                // tries to parse the url response, if it fails, it will just show that it was successful
                if (parseAs == "") {
                  showSnackBar(context, "Upload successful"),
                } else
                  {
                    Clipboard.setData(ClipboardData(text: parseAs ?? 'default')),
                    showSnackBar(context, "File upload successfully as: $parseAs. It has been copied to your clipboard")
                  }
              });
            } on DioException catch (error) {
              onSetState("");
              if (error.response?.data != null) {
                parseAs = parseResponse(error.response?.data, data
                    .uploaderErrorParser); // tries to parse the error response, if it fails, it will just show the error
                if (parseAs == "") {
                  showSnackBar(context, "Error transferring to $url: (${error.response?.statusCode}) ${error.response?.statusMessage}");
                } else {
                  showSnackBar(context, "Error transferring to $url: (${error.response?.statusCode}) ${error.response?.statusMessage}; $parseAs");
                }
              } else {
                showSnackBar(context, "Failed to connect to server. Please check your internet connection.");
              }
              print(error);
            }
          }
    } else {
      showSnackBar(context, "Please select an uploader first.");
    }
  }
}