import 'package:hive/hive.dart';
part 'database.g.dart';

@HiveType(typeId: 0) // 1
class Share extends HiveObject {
  @HiveField(0)
  String uploaderUrl;

  @HiveField(1)
  String formDataName;

  @HiveField(2)
  bool uploadFormData;

  @HiveField(3)
  Map<String, String> uploadHeaders;

  @HiveField(4)
  Map<String, String> uploadParameters;

  @HiveField(5)
  Map<String, String> uploadArguments;

  @HiveField(6)
  String uploaderResponseParser;

  @HiveField(7)
  String uploaderErrorParser;

  @HiveField(8)
  bool selectedUploader; // No longer `late` or nullable, initialized in constructor

  @HiveField(9)
  String? method;

  Share({
    required this.uploaderUrl,
    required this.formDataName,
    required this.uploadFormData,
    required this.uploadHeaders,
    required this.uploadParameters,
    required this.uploadArguments,
    required this.uploaderResponseParser,
    required this.uploaderErrorParser,
    this.selectedUploader = false, // Default to false
    this.method,
  });

  // Setter method to safely update selectedUploader
  void setSelectedUploader(bool value) {
    selectedUploader = value;
  }
}

@HiveType(typeId: 1) // 2
class ViewSelection {
  // define the type of the field
  @HiveField(0)
  bool addNewView; // for selecting the simple or advanced view for the add uploader page
  @HiveField(1)
  bool shouldLoadPresets; // for if the default uploader presets should be loaded

  ViewSelection(this.addNewView, this.shouldLoadPresets);
}

@HiveType(typeId: 2) // 3
class NetworkShare extends HiveObject {
  @HiveField(0)
  String protocol; // incase we add any other protocols than ftp

  @HiveField(1)
  String domain;

  @HiveField(2)
  String username;

  @HiveField(3)
  String password;

  @HiveField(4)
  String folderPath;

  @HiveField(5)
  int port; // optional: default to 21 for FTP

  @HiveField(6)
  bool selected;

  @HiveField(7)
  String? urlPath;

  NetworkShare({
    required this.protocol,
    required this.domain,
    required this.username,
    required this.password,
    required this.folderPath,
    this.port = 21, // can set default
    this.selected = false,
    this.urlPath = "",
  });

  void setSelectedShare(bool value) {
    selected = value;
  }
}
