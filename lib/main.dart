import 'dart:convert';

import 'package:custom_uploader/services/database.dart';
import 'package:flutter/material.dart';
import 'package:custom_uploader/views/home_page.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  // connects to hive database
  await Hive.initFlutter();
  Hive.registerAdapter(ShareAdapter());
  await Hive.openBox<Share>("custom_upload");

  var viewBox =  Hive.openBox("custom_view");
  viewBox.then((box) async {
    bool? loadPresets = box.get('shouldLoadPresets', defaultValue: false);
    if(!loadPresets!) {
      String jsonPresetLoader = await rootBundle.loadString('assets/preset_uploaders.json');
      Box<Share> shareBox = Hive.box<Share>("custom_upload");
      for(var item in jsonDecode(jsonPresetLoader)) {
        shareBox.add(Share(item["RequestURL"], item["FileFormName"], item["UseByes"], item["Headers"], item["Parameters"], item["Arguments"], item["URL"], item["ErrorMessage"], false, item['RequestMethod']));
      }

      box.put('shouldLoadPresets', true);
    }
    box.close();
  });

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
