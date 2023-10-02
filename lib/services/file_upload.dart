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
          onSetState(file.path.split("/").last);
          Map<String, String>? headers = data.uploadHeaders;

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

          final url = data.uploaderUrl;

          // uploads file to the chosen server with the chosen parameters
          String? parseAs;
          try {
            await Dio().post(
              url,
              queryParameters: data.uploadParameters,
              options: Options(
                headers: headers,
              ),
              data: formData,
              onSendProgress: (int sent, int total) {
                onUploadProgress(sent, total);
              },
            ).then((value) => {
              onSetState(""),
              parseAs = parseResponse(value.data, data.uploaderResponseParser), // tries to parse the url response, if it fails, it will just show that it was successful
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
              parseAs = parseResponse(error.response?.data, data.uploaderErrorParser); // tries to parse the error response, if it fails, it will just show the error
              if (parseAs == "") {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(duration: const Duration(seconds: 8), content: Text('Error transferring $url - server replied: ${error.response?.statusMessage}')));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(duration: const Duration(seconds: 8), content: Text('Error transferring $url - server replied: ${error.response?.statusMessage}; $parseAs')));
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to connect to server. Please check your internet connection.')));
            }
        }
    } else {
      showSnackBar(context, "Please select an uploader first.");
    }
  }
}