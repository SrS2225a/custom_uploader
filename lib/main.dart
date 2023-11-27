import 'package:custom_uploader/services/database.dart';
import 'package:flutter/material.dart';
import 'package:custom_uploader/views/home_page.dart';
import 'package:hive_flutter/adapters.dart';

Future<void> main() async {
  // connects to hive database
  await Hive.initFlutter();
  Hive.registerAdapter(ShareAdapter());
  await Hive.openBox<Share>("custom_upload");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of the application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const MyHomePage(title: 'Custom Uploader'),
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
      ),
      themeMode: ThemeMode.system,
    );
  }
}
