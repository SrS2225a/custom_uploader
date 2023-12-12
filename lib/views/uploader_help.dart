import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class Help extends StatefulWidget {
  const Help({super.key});

  @override
  State<Help> createState() => _MyUploaderState();
}

String file = "contents.md";
class _MyUploaderState extends State<Help> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Custom Uploader Help"),
        ),
        body: displayMarkdown()
    );
  }

  FutureBuilder<String> displayMarkdown(){

    return FutureBuilder(
      future: DefaultAssetBundle.of(context).loadString
        ("lib/views/markdown/contents.md"),
      builder: (BuildContext context, AsyncSnapshot<String> snapshot){
        if (snapshot.hasData) {
          return Markdown(data: snapshot.data!);
        }
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }
}