import 'dart:convert';
import 'dart:io';

import 'package:custom_uploader/utils/show_message.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
        showAlert(context, AppLocalizations.of(context)!.failed_to_import, AppLocalizations.of(context)!.invalid_json(e.toString()));
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
      return Share(
        uploaderUrl: json["RequestURL"] ?? "",
        formDataName: json["FileFormName"] ?? "upload",
        uploadFormData: useBytes,
        uploadHeaders: getCorrectTypes(json["Headers"]) ?? {},
        uploadParameters: getCorrectTypes(json["Parameters"]) ?? {},
        uploadArguments: arguments,
        uploaderResponseParser: convertParser(json["URL"] ?? ""),
        uploaderErrorParser: convertParser(json["ErrorMessage"] ?? ""),
        selectedUploader: false,
        method: json["RequestMethod"],
      );
    }

    var json = readData(file);
    if (json != null) {
      // check if the file is a valid uploader
      if (json["RequestURL"] != null && json["FileFormName"] != null && json["RequestMethod"] != null) {
        // Check if the RequestMethod is one of the supported methods
        String requestMethod = json["RequestMethod"].toUpperCase();
        if (requestMethod == "GET" || requestMethod == "POST" || requestMethod == "PUT" || requestMethod == "PATCH") {
          Box<Share> shareBox = Hive.box<Share>("custom_upload");
          if (shareBox.values.where((element) => element.uploaderUrl == json["RequestURL"]).isNotEmpty) {
            // tell the user that the uploader already exists
            showAlert(context, AppLocalizations.of(context)!.failed_to_import, AppLocalizations.of(context)!.import_uploader_already_exists);
          } else {
            // add the uploader to the database
            Share? share = readJson(json);
            if (share != null) {
              shareBox.add(share);
              showSnackBar(context, AppLocalizations.of(context)!.import_successful);
            } else {
              // tell the user that the uploader is invalid
              showAlert(context, AppLocalizations.of(context)!.failed_to_import, AppLocalizations.of(context)!.import_uploader_invalid);
            }
          }
        } else {
          // tell the user that the request method is not supported
          showAlert(context, AppLocalizations.of(context)!.failed_to_import, AppLocalizations.of(context)!.import_request_method_not_supported(json["RequestMethod"]));
        }
      } else {
        // tell the user that the file is not a valid uploader
        showAlert(context, AppLocalizations.of(context)!.failed_to_import,  AppLocalizations.of(context)!.import_not_valid_uploader);
      }
    }
  }

  static export ({required int index, required BuildContext context}) async {
    // get the uploader from the database
    Box<Share> shareBox = Hive.box<Share>("custom_upload");
    Share share = shareBox.getAt(index)!;

    Future<void> _saveFileToMediaStore(File file, String name) async {
      const channel = MethodChannel('flutter_media_store');

      Future<void> addItem({required File file, required String name}) async {
        await channel.invokeMethod('addItem', {'path': file.path, 'name': name});
        await file.delete();
      }

      addItem(file: file, name: name);
    }

    try {
      final fileName = '${share.uploaderUrl.replaceAll(RegExp(r'[^\w\s]+'), "_")}.sxcu.json';
      // convert the uploader to json
      Map<String, dynamic> json = {
        "RequestURL": share.uploaderUrl,
        "FileFormName": share.formDataName,
        "RequestMethod": share.method,
        if (share.uploadFormData) "Body": "MultipartFormData",
        if (share.uploadHeaders.isNotEmpty) "Headers": share.uploadHeaders,
        if (share.uploadParameters.isNotEmpty) "Parameters": share.uploadParameters,
        if (share.uploadArguments.isNotEmpty) "Arguments": share.uploadArguments,
        if (share.uploaderResponseParser.isNotEmpty) "URL": share.uploaderResponseParser,
        if (share.uploaderErrorParser.isNotEmpty) "ErrorMessage": share.uploaderErrorParser
      };

      if(Platform.isAndroid) {
        // request permission to write to storage using the permission handler plugin
        PermissionStatus legacyPermission = await Permission.storage.request();
        if (legacyPermission == PermissionStatus.granted) {
          // write the file to storage
          final filePath = '/storage/emulated/0/Download/$fileName';
          File file = File(filePath);
          // write file as type json
          await file.writeAsString(jsonEncode(json), flush: true, mode: FileMode.write, encoding: Encoding.getByName("utf-8")!);
          showSnackBar(context, AppLocalizations.of(context)!.export_successful);
        } else {
          final deviceInfo = DeviceInfoPlugin();
          final androidInfo = await deviceInfo.androidInfo;
          final sdkVersion = androidInfo.version.sdkInt;
          if(sdkVersion  >= 10) {
            final tempDir = await getTemporaryDirectory();
            final path = '${tempDir.path}/$fileName';
            final file = File(path);
            await file.writeAsString(jsonEncode(json), flush: true, encoding: Encoding.getByName("utf-8")!);
            await _saveFileToMediaStore(file, fileName);
            showSnackBar(context, AppLocalizations.of(context)!.export_successful);
          } else {
            // tell the user that the permission was denied
            showAlert(context, AppLocalizations.of(context)!.failed_to_export, AppLocalizations.of(context)!.permission_denied("storage"));
          }
      }
      } else if(Platform.isIOS) {
        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/$fileName';
        final file = File(path);
        await file.writeAsString(jsonEncode(json), flush: true, encoding: Encoding.getByName("utf-8")!);
        showSnackBar(context, AppLocalizations.of(context)!.export_successful);
      } else {
        // tell the user that the platform is not supported
        showAlert(context, AppLocalizations.of(context)!.failed_to_export, AppLocalizations.of(context)!.platform_not_supported(Platform.operatingSystem));
      }
    } catch (e) {
      // tell the user why it failed
      print(e);
      showAlert(context, AppLocalizations.of(context)!.failed_to_export, AppLocalizations.of(context)!.export_failed(e.toString()));
    }
  }
}
