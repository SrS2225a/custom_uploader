import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:custom_uploader/l10n/app_localizations.dart';

import '../../services/database.dart';
import '../../utils/show_message.dart';

// create the state
class SimpleView extends StatefulWidget {
  const SimpleView(this.editor, {super.key});
  final Share? editor;

  @override
  State<StatefulWidget> createState() {
    return SimpleViewState();
  }
}

// create the view
class SimpleViewState extends State<SimpleView> {
  late Share cursor;
  final _formKey = GlobalKey<FormState>();
  late bool _switchValue; // Value for the switch

  @override
  void initState() {
    super.initState();
    // Initialize cursor and _switchValue based on whether an editor is provided
    if (widget.editor != null) {
      cursor = widget.editor!;
      _switchValue = cursor.uploadFormData;
    } else {
      cursor = Share(
        uploaderUrl: "",
        formDataName: "upload",
        uploadFormData: false,
        uploadHeaders: {},
        uploadParameters: {},
        uploadArguments: {},
        uploaderResponseParser: "",
        uploaderErrorParser: "",
        selectedUploader: false,
        method: "POST",
      );
      _switchValue = cursor.uploadFormData; // Set _switchValue correctly
    }
  }

  void _saveShare() async {
    final box = await Hive.openBox<Share>("custom_upload");

    if (widget.editor != null) {
      // Update existing share
      final index = box.values.toList().indexOf(widget.editor!);
      if (index != -1) {
        cursor.uploadFormData = _switchValue;
        box.putAt(index, cursor);
      }
    } else {
      // Check if the uploader already exists
      if (box.values
          .where((element) => element.uploaderUrl == cursor.uploaderUrl)
          .isEmpty) {
        cursor.uploadFormData = _switchValue;
        box.add(cursor);
      } else {
        showSnackBar(
            context, AppLocalizations.of(context)!.share_already_exists);
      }
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Form(
        key: _formKey,
        child: SizedBox(
          height: MediaQuery
              .of(context)
              .size
              .height -
              Scaffold
                  .of(context)
                  .appBarMaxHeight!
                  .toInt() -
              1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.max,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(
                        hintText:
                        AppLocalizations.of(context)!.upload_url_hint,
                        labelText:
                        AppLocalizations.of(context)!.upload_url_label,
                      ),
                      validator: (value) {
                        var regex = RegExp(
                            r"^(?:https?|s?ftp):\/\/[-A-Za-z0-9+&@#\/\[\]%?=~_!:.]*[-A-Za-z0-9+@#\/\]%=~_|]$")
                            .hasMatch(value!);
                        if (value.isEmpty || !regex) {
                          return AppLocalizations.of(context)!
                              .upload_url_error;
                        }
                        return null;
                      },
                      initialValue: cursor.uploaderUrl,
                      onSaved: (value) {
                        cursor.uploaderUrl = value!;
                      },
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!
                            .form_data_name_hint,
                        labelText: AppLocalizations.of(context)!
                            .form_data_name_label,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocalizations.of(context)!
                              .form_data_name_error;
                        }
                        return null;
                      },
                      initialValue: cursor.formDataName,
                      onSaved: (value) {
                        cursor.formDataName = value!;
                      },
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Switch(
                    value: _switchValue,
                    onChanged: (value) {
                      setState(() {
                        _switchValue = value;
                      });
                    },
                  ),
                  Text(AppLocalizations.of(context)!.use_file_encoding),
                ],
              ),
              const Spacer(),
              Text(
                AppLocalizations.of(context)!.advanced_view_tip,
                textAlign: TextAlign.center,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                      child: FilledButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _formKey.currentState?.save();
                            _saveShare();
                          }
                        },
                        child:
                        Text(AppLocalizations.of(context)!.save),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child:
                        Text(AppLocalizations.of(context)!.cancel),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}