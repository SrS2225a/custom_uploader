import 'dart:convert';
import 'dart:io';

import 'package:custom_uploader/utils/show_message.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:permission_handler/permission_handler.dart';

import 'database.dart';

class ImportExportService {
  static import ({required PlatformFile file, required BuildContext context}) async {
    readData(PlatformFile filepath) {
      // converts selected file to something that can be read as a string
      try {
        File file = File(filepath.path ?? "");
        return jsonDecode(file.readAsStringSync());
      } catch (e) {
        // tell the user why it failed
        // showAlertForExchanger(context, "Failed to import", "The file you selected appears to not be a valid JSON file. \n\nError: ${e.toString()}");
        showAlert(context, "Failed to import", "The file you selected appears to not be a valid JSON file. \n\nError: ${e.toString()}");
        return null;
      }
    }

    Share? readJson(Map<String, dynamic> json) {
      // sharex still takes the old format of "$", syntax and we prefer that old format, so we'll convert it from the new format
      String convertParser(String errorMessage) {
        if (errorMessage.startsWith("{") && errorMessage.endsWith("}")) {
          errorMessage = errorMessage.substring(1, errorMessage.length - 1);
        }
        errorMessage = errorMessage.replaceAll("{", "\$");
        errorMessage = errorMessage.replaceAll("}", "\$");
        return errorMessage;
      }
      var useBytes = false;

      // for converting sharex's format to ours
      if (json["Body"] == "MultipartFormData") {
        useBytes = true;
      }

      // for converting to Map<String, String>
      getCorrectTypes(json) {
        Map<String, String> obj = {};
        if (json != null) {
          for (var key in json.keys) {
            obj[key] = json[key];
          }
        }
        print(obj);
        return obj;
      }

      // makes the nested json readable
      Map<String, String> arguments = {};
      if (json["Arguments"] != null) {
        for (var key in json["Arguments"].keys) {
          if (useBytes) {
            if (json["Arguments"][key] == "\$input\$" || json["Arguments"][key] == "{input}") { // "$" is for legacy sharex support
              json["FileFormName"] = arguments[key];
            }
          }

          // leaving "input" value or "filename" may confuse the file server, so we remove it
          if ( json["Arguments"][key] == "\$input\$" || json["Arguments"][key] == "{input}" || json["Arguments"][key] == "\$filename\$" || json["Arguments"][key] == "{filename}") {
            continue;
          } else {
            arguments[key] = json["Arguments"][key];
          }
        }
      }
      // type of json["Headers"] should be Map<String, dynamic> instead of _InternalLinkedHashMap<String, dynamic>
      return Share(json["RequestURL"], json["FileFormName"], useBytes, getCorrectTypes(json["Headers"]), getCorrectTypes(json["Parameters"]), arguments, convertParser(json["URL"] ?? ""), convertParser(json["ErrorMessage"] ?? ""), false);
    }

    var json = readData(file);
    if (json != null) {
      // check if the file is a valid uploader
      if (json["RequestURL"] != null && json["FileFormName"] != null) {
        Box<Share> shareBox = Hive.box<Share>("custom_upload");
        if (shareBox.values.where((element) => element.uploaderUrl == json["RequestURL"]).isNotEmpty) {
          // tell the user that the uploader already exists
          showAlert(context, "Failed to import", "The uploader you are trying to import already exists.");
        } else {
          // add the uploader to the database
          Share? share = readJson(json);
          if (share != null) {
            shareBox.add(share);
          } else {
            // tell the user that the uploader is invalid
            showAlert(context, "Failed to import", "The uploader you are trying to import is invalid.");
          }
        }
      } else {
        // tell the user that the file is not a valid uploader
        showAlert(context, "Failed to import",  "The file you selected appears to not be a valid uploader.");
      }
    }
  }

  static export ({required int index, required BuildContext context}) async {
    // get the uploader from the database
    Box<Share> shareBox = Hive.box<Share>("custom_upload");
    Share share = shareBox.getAt(index)!;

    Future<String> getFilePath() async {
      Directory? appDocumentsDirectory = Directory("/storage/emulated/0/Download");
      String? appDocumentsPath = appDocumentsDirectory.path; // 2
      // replace all the invalid characters
      String fileName = share.uploaderUrl.replaceAll(RegExp(r'[^\w\s]+'), "_");
      String filePath = '$appDocumentsPath/$fileName.sxcu.json';

      return filePath;
    }

    // convert the uploader to json
    Map<String, dynamic> json = {
      "RequestURL": share.uploaderUrl,
      "FileFormName": share.formDataName,
      if (share.uploadFormData) "Body": "MultipartFormData",
      if (share.uploadHeaders.isNotEmpty) "Headers": share.uploadHeaders,
      if (share.uploadParameters.isNotEmpty) "Parameters": share.uploadParameters,
      if (share.uploaderUrl.isNotEmpty) "Arguments": share.uploadArguments,
      if (share.uploaderResponseParser.isNotEmpty) "URL": share.uploaderResponseParser,
      if (share.uploaderErrorParser.isNotEmpty) "ErrorMessage": share.uploaderErrorParser
    };

    try {
      // request permission to write to storage using the permission handler plugin
      PermissionStatus permission = await Permission.storage.request();
      if (permission == PermissionStatus.granted) {
        // write the file to storage
        String filePath = await getFilePath();
        File file = File(filePath);
        // write file as type json
        file.writeAsStringSync(jsonEncode(json), flush: true, mode: FileMode.write, encoding: Encoding.getByName("utf-8")!);
      } else {
        // tell the user that the permission was denied
        showAlert(context, "Failed to export", "The permission to write to storage was denied.");
      }
    } catch (e) {
      // tell the user why it failed
      showAlert(context, "Failed to export", "Failed to export the uploader. \n\nError: ${e.toString()}");
    } finally {
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("The uploader was exported to ${await getFilePath()}")));
      showSnackBar(context, "The uploader was exported to your downloads");
    }
  }
}