import 'package:custom_uploader/services/database.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'components/add_uploader_advanced.dart';
import 'components/add_uploader_simple.dart';

class Creator extends StatefulWidget {
  var index = 0;
  final Share? editor;
  Creator({super.key, required this.editor, required this.index});

  @override
  State<Creator> createState() => _MyCreatorState();
}

class _MyCreatorState extends State<Creator> {
  var viewBox =  Hive.openBox("custom_view");
  bool _isAdvancedView = false;

  @override
  void initState() {
    super.initState();
    // Initialize checkboxValue from Hive
    viewBox.then((value) {
      bool? advancedView = value.get('addNewView', defaultValue: false);
      setState(() {
        _isAdvancedView = advancedView!;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("HTTP Uploader"),
          actions: <Widget>[
            PopupMenuButton<int>(itemBuilder: (BuildContext context) {
              return [
                CheckedPopupMenuItem<int>(
                  checked: _isAdvancedView,
                  value: 0,
                  child: const Text("Advanced"),
                ),
              ];
            },
              onSelected: (value) {
                if (value == 0) {
                  setState(() {
                    _isAdvancedView = !_isAdvancedView;
                    updateSelectedView(_isAdvancedView);
                  });
                }
              },)
          ],
    ),
    body: SingleChildScrollView(
      child: _isAdvancedView ? AdvancedView(widget.editor, widget.index) : SimpleView(widget.editor, widget.index)
    ),
  );
}

  void updateSelectedView(bool newValue) async {
    viewBox.then((value) => value.put('addNewView', newValue));
  }
}
