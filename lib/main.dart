import 'dart:convert';

import 'package:custom_uploader/services/database.dart';
import 'package:flutter/material.dart';
import 'package:custom_uploader/views/home_page.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

Future<void> main() async {
  // connects to hive database
  await Hive.initFlutter();
  Hive.registerAdapter(ShareAdapter());
  await Hive.openBox<Share>("custom_upload");

  var viewBox = await Hive.openBox('custom_view');
  bool? loadPresets = viewBox.get('shouldLoadPresets', defaultValue: false);

  if (!loadPresets!) {
    String yamlPresetLoader = await rootBundle.loadString('lib/assets/preset_uploaders.yaml');
    var yamlList = loadYaml(yamlPresetLoader);

    Box<Share> shareBox = Hive.box<Share>('custom_upload');

    // Since the dart yaml package does not use an ordinary map type, we need to convert it.
    // Why the hell would you use an custom type in this way instead of an regular type? It drives me insane
    dynamic yamlMapToMap(dynamic value) {
      if (value is Map) {
        List<MapEntry<String, String>> entries = [];
        for (final key in value.keys) {
          entries.add(MapEntry(key, yamlMapToMap(value[key])));
        }
        return Map.fromEntries(entries);
      } else if (value is List) {
        return List.from(value.map(yamlMapToMap));
      } else {
        return value;
      }
    }

    for (var item in yamlList) {
      // advoid adding duplicates
      if (!shareBox.values.where((element) => element.uploaderUrl == item["RequestURL"]).isNotEmpty) {
        shareBox.add(Share(
            item["RequestURL"],
            item["FileFormName"],
            item["UseBytes"],
            yamlMapToMap(item["Headers"] ?? {}),
            yamlMapToMap(item["Parameters"] ?? {}),
            yamlMapToMap(item["Arguments"] ?? {}),
            item["URLResponse"] ?? "",
            item["ErrorResponse"] ?? "",
            false,
            item["RequestMethod"]
        ));
      }
    }

    viewBox.put('shouldLoadPresets', true);
  }
  await viewBox.close();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of the application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return MaterialApp(
      home: const MyHomePage(title: 'Custom Uploader'),
      theme: ThemeData(
        useMaterial3: false,
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
      ),
      darkTheme: ThemeData(
        useMaterial3: false,
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
      ),
      themeMode: ThemeMode.system,
    );
  }
}
