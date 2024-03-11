import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../services/database.dart';
import '../../utils/show_message.dart';

// create the state
class SimpleView extends StatefulWidget {
  const SimpleView(this.editor, this.index, {super.key});
  final Share? editor;
  final int? index;

  @override
  State<StatefulWidget> createState() {
    return SimpleViewState();
  }
}

// create the view
class SimpleViewState extends State<SimpleView> {
  late Share cursor;
  final _formKey = GlobalKey<FormState>();
  late bool _switchValue = false; // hack to get the switch to work

  @override
  void initState() {
    super.initState();
    if (widget.editor != null) {
      cursor = widget.editor!;
      _switchValue = cursor.uploadFormData;
    } else {
      cursor = Share("", "upload", false, {}, {}, {}, "", "", false, "POST");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
        key: _formKey,
        child: SizedBox(
        height: MediaQuery.of(context).size.height - Scaffold.of(context).appBarMaxHeight!.toInt() - 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.max,
          children: [
            Row(
              children: [
                Expanded(child: TextFormField(
                  decoration: const InputDecoration(
                    hintText: "The URL to upload to.",
                    labelText: "Upload URL *",
                  ),
                  validator: (value) {
                    var regex = RegExp(r"^(?:https?|s?ftp):\/\/[-A-Za-z0-9+&@#\/\[\]%?=~_!:.]*[-A-Za-z0-9+@#\/\]%=~_|]$").hasMatch(value!);
                    if (value.isEmpty || !regex) {
                      return 'Please enter a valid url';
                    }
                    return null;
                  },
                  initialValue: cursor.uploaderUrl,
                  onSaved: (value) {cursor.uploaderUrl = value!;},
                )
              ),
              ],
            ),
            Row(
              children: [
                Expanded(child: TextFormField(
                  decoration: const InputDecoration(
                    hintText: "The name of the form data field.",
                    labelText: "Form Data Name *",
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a form nme';
                    }
                    return null;
                  },
                  initialValue: cursor.formDataName,
                  onSaved: (value) {cursor.formDataName = value!;},
                ),
              ),
              ],
            ),
            Row(
              children: [
                Switch(value: _switchValue, onChanged: (value) {setState(() {
                  _switchValue = value;
                });}),
                const Text("Use file encoding"),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(
                    child: ElevatedButton(
                      onPressed: () {
                        // Validate returns true if the form is valid, or false otherwise.
                        if (_formKey.currentState!.validate()) {
                          Box<Share> shareBox = Hive.box<Share>("custom_upload");
                          _formKey.currentState?.save();

                          if (widget.editor != null) {
                            cursor.uploadFormData = _switchValue;
                            shareBox.putAt(widget.index!, cursor);
                          } else {
                            // check if uploader already exists
                            if (shareBox.values.where((element) => element.uploaderUrl == cursor.uploaderUrl).isEmpty) {
                              cursor.uploadFormData = _switchValue;
                              shareBox.add(cursor);
                            } else {
                              showSnackBar(context, "The uploader you are trying to add already exists.");
                            }
                          }
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text('Save'),
                    ),
                  )
                ),
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Cancel'),
                      ),
                    )
                ),
              ],
            )
          ],
        )
      ),
    );
  }
}