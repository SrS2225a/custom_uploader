import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Pure FTP Web Demo',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<String> lines = ['Start Demo'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
      children: lines.map((e) => Text('FTP:$e')).toList(),
    ));
  }

//todo uncomment this code to run the demo
// void _log(dynamic message) {
//   var string = message.toString();
//   lines.addAll(string.split('\n'));
// }
}
