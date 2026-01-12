import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:custom_uploader/l10n/app_localizations.dart';

import '../../services/database.dart';
import '../../utils/show_message.dart';
import 'package:custom_uploader/services/pgp_service.dart';

// create the state
class SimpleView extends StatefulWidget {
  const SimpleView(
      this.editor, {
        super.key,
        required this.pgpEnabled,
        required this.onPgpChanged,
      });

  final Share? editor;
  final bool pgpEnabled;
  final ValueChanged<bool> onPgpChanged;

  @override
  State<StatefulWidget> createState() => SimpleViewState();
}

// create the view
class SimpleViewState extends State<SimpleView> {
  late Share cursor;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _pgpKeyController = TextEditingController();
  late bool _pgpEnabled = false;
  late bool _switchValue = false;

  @override
  void dispose() {
    _pgpKeyController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    if (widget.editor != null) {
      cursor = widget.editor!;
      _switchValue = cursor.uploadFormData;

      if (widget.editor?.pgpPublicKey != null) {
        _pgpKeyController.text = widget.editor!.pgpPublicKey!;
        _pgpEnabled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onPgpChanged(true);
        });
      }
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
    }
  }

  @override
  void didUpdateWidget(covariant SimpleView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.pgpEnabled != widget.pgpEnabled) {
      setState(() {
        _pgpEnabled = widget.pgpEnabled;
      });
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
    final media = MediaQuery.of(context);
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
                  .toInt() - 50,
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
              if(_pgpEnabled) ...[
                Column(
                    children: [
                      Text(
                        'PGP Encryption',
                      ),

                      TextFormField(
                        controller: _pgpKeyController,
                        minLines: 4,
                        maxLines: 8,
                        decoration: const InputDecoration(
                          labelText: 'PGP Public Key',
                          alignLabelWithHint: true,
                        ),
                        validator: (v) =>
                        (_pgpEnabled && (v == null || v.isEmpty))
                            ? 'Public key required'
                            : null,
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          OutlinedButton.icon(
                              icon: const Icon(Icons.upload_file),
                              label: const Text('Import key'),
                              onPressed: () async {
                                final result =  await FilePicker.platform.pickFiles(
                                    type: FileType.custom,
                                    allowedExtensions: ['asc', 'pgp', 'txt']
                                );
                                final key = await importPgpKeyFromFile(result, context);
                                _pgpKeyController.text = key!.trim();
                              }
                          ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                              icon: const Icon(Icons.key),
                              label: const Text('Generate key'),
                              onPressed: () async {
                                final result = await generateNewPgpKey(context, cursor.uploaderUrl);
                                _pgpKeyController.text = result!;
                              }
                          ),
                        ],
                      ),
                    ]
                ),
              ],
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
                            if(cursor.pgpPublicKey != null && !_pgpEnabled) {
                              // show alert dialog choice to remove key
                              showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: Text('Remove PGP Public Key'),
                                      content: Text('Are you sure you want to disable PGP encryption? This will clear your PGP public key'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context), child: Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            cursor.pgpPublicKey = null;
                                            Navigator.pop(context);
                                            _saveShare();
                                          },
                                          child: Text('Remove'),
                                        ),
                                      ],
                                    );
                                  }
                              );
                            } else {
                              cursor.pgpPublicKey = _pgpKeyController.text;
                              _formKey.currentState?.save();
                              _saveShare();
                            }
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