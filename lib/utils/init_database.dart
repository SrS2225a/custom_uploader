import 'package:flutter/services.dart' show rootBundle;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:yaml/yaml.dart';
import 'package:custom_uploader/services/database.dart';


Future<void> initializeDatabase() async {
  await Hive.initFlutter();

  Hive.registerAdapter(ShareAdapter());
  Hive.registerAdapter(NetworkShareAdapter());

  // Open boxes in parallel
  final futures = await Future.wait([
    Hive.openBox<Share>("custom_upload"),
    Hive.openBox<NetworkShare>("share_upload"),
    Hive.openBox('custom_view'),
  ]);

  final shareBox = futures[0] as Box<Share>;
  final viewBox = futures[2];

  final bool loadPresets = viewBox.get('shouldLoadPresets', defaultValue: false);

  if (!loadPresets) {
    final String yamlString = await rootBundle.loadString('lib/assets/preset_uploaders.yaml');
    final yamlList = loadYaml(yamlString);

    for (final item in yamlList) {
      if (!shareBox.values.any((s) => s.uploaderUrl == item["RequestURL"])) {
        shareBox.add(Share(
          uploaderUrl: item["RequestURL"] ?? "",
          formDataName: item["FileFormName"] ?? "upload",
          uploadFormData: item["UseBytes"] ?? false,
          uploadHeaders: yamlMapToMap(item["Headers"] ?? {}),
          uploadParameters: yamlMapToMap(item["Parameters"] ?? {}),
          uploadArguments: yamlMapToMap(item["Arguments"] ?? {}),
          uploaderResponseParser: item["URLResponse"] ?? "",
          uploaderErrorParser: item["ErrorResponse"] ?? "",
          selectedUploader: false,
          method: item["RequestMethod"],
        ));
      }
    }

    await viewBox.put('shouldLoadPresets', true);
  }

  await viewBox.close();
}

dynamic yamlMapToMap(dynamic value) {
  if (value is Map) {
    return Map.fromEntries(
      value.entries.map((e) => MapEntry(e.key.toString(), yamlMapToMap(e.value))),
    );
  } else if (value is List) {
    return value.map(yamlMapToMap).toList();
  } else {
    return value;
  }
}