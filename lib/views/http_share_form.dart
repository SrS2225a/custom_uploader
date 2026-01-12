import 'package:custom_uploader/services/database.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:custom_uploader/l10n/app_localizations.dart';

import '../utils/ScaffoldFix.dart';
import 'components/add_uploader_advanced.dart';
import 'components/add_uploader_simple.dart';

class HTTPShareForm extends StatefulWidget {
  final Share? editor;
  HTTPShareForm({super.key, required this.editor});

  @override
  State<HTTPShareForm> createState() => _MyCreatorState();
}

class _MyCreatorState extends State<HTTPShareForm> {
  var viewBox =  Hive.openBox("custom_view");
  bool _isAdvancedView = false;
  bool __isPgpEnabled = false;

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
    return ScaffoldFix(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.type_uploader("HTTP")),
          actions: <Widget>[
            PopupMenuButton<int>(itemBuilder: (BuildContext context) {
              return [
                CheckedPopupMenuItem<int>(
                  checked: _isAdvancedView,
                  value: 0,
                  child: Text(AppLocalizations.of(context)!.advanced),
                ),
                CheckedPopupMenuItem<int>(
                  checked: __isPgpEnabled,
                  value: 1,
                  child: Text('PGP Encryption'),
                )
              ];
            },
              onSelected: (value) {
                if (value == 0) {
                  setState(() {
                    _isAdvancedView = !_isAdvancedView;
                    updateSelectedView(_isAdvancedView);
                  });
                }
                if(value == 1) {
                  setState(() {
                    __isPgpEnabled = !__isPgpEnabled;
                  });
                }
              },)
          ],
    ),
      body: SingleChildScrollView(
        key: ValueKey(_isAdvancedView),   // force full teardown
        child: _isAdvancedView
            ? AdvancedView(
          key: const ValueKey('advanced'),
          widget.editor,
          pgpEnabled: __isPgpEnabled,
          onPgpChanged: (v) {
            setState(() => __isPgpEnabled = v);
          },
        )
            : SimpleView(
          key: const ValueKey('simple'),
          widget.editor,
          pgpEnabled: __isPgpEnabled,
          onPgpChanged: (v) {
            setState(() => __isPgpEnabled = v);
          },
        ),
      ),
  );
}

  void updateSelectedView(bool newValue) async {
    viewBox.then((value) => value.put('addNewView', newValue));
  }
}
