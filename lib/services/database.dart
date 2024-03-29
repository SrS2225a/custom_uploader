import 'package:hive/hive.dart';
part 'database.g.dart';

@HiveType(typeId: 0) // 1
class Share {
  // defines the type of the field
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
  bool selectedUploader;
  @HiveField(9)
  String? method;

  Share(this.uploaderUrl, this.formDataName, this.uploadFormData, this.uploadHeaders, this.uploadParameters, this.uploadArguments, this.uploaderResponseParser, this.uploaderErrorParser, this.selectedUploader, this.method);
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
