import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:trina_grid/trina_grid.dart';
import 'package:custom_uploader/l10n/app_localizations.dart';

import '../../services/database.dart';
import '../../services/pgp_service.dart';
import '../../utils/show_message.dart';

class AdvancedView extends StatefulWidget {
  const AdvancedView(
      this.editor, {
        super.key,
        required this.pgpEnabled,
        required this.onPgpChanged,
      });

  final Share? editor;
  final bool pgpEnabled;
  final ValueChanged<bool> onPgpChanged;

  @override
  State<StatefulWidget> createState() => AdvancedViewState();
}

class AdvancedViewState extends State<AdvancedView> {
  late TrinaGridStateManager stateManager;
  late TrinaGridStateManager state2Manager;
  late TrinaGridStateManager state3Manager;

  late Share cursor;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _pgpKeyController = TextEditingController();
  late bool _switchValue = false; // hack to get the switch to work
  late bool _pgpEnabled = false;

  @override
  void dispose() {
    _pgpKeyController.dispose();
    super.dispose();
  }

  Widget _getHeadersTable() {
    final List<TrinaColumn> columns = [];
    final List<TrinaColumnGroup> columnGroups = [];
    final List<TrinaRow> rows = [];

    columns.addAll([
      TrinaColumn(
        title: AppLocalizations.of(context)!.key,
        field: 'key',
        type: TrinaColumnType.text(),
        footerRenderer: (rendererContext) {
          return IconButton(
            onPressed: () {
              rendererContext.stateManager.insertRows(
                rendererContext.stateManager.rows.length,
                [rendererContext.stateManager.getNewRow()],
              );
            },
            icon: const Icon(Icons.add_circle),
            iconSize: 20,
            color: Colors.green,
            padding: EdgeInsets.zero,
          );
        },
      ),
      TrinaColumn(
        title: AppLocalizations.of(context)!.value,
        field: 'value',
        type: TrinaColumnType.text(),
        footerRenderer: (rendererContext) {
          return IconButton(
            onPressed: () {
              if (rendererContext.stateManager.rows.isNotEmpty) {
                rendererContext.stateManager
                    .removeRows([rendererContext.stateManager.rows.last]);
              }
            },
            icon: const Icon(Icons.remove_circle),
            iconSize: 20,
            color: Colors.red,
            padding: EdgeInsets.zero,
          );
        },
      ),
    ]);

    if (cursor.uploadHeaders.isNotEmpty) {
      for (final entry in cursor.uploadHeaders.entries) {
        rows.add(
          TrinaRow(
            cells: {
              "key": TrinaCell(value: entry.key),
              "value": TrinaCell(value: entry.value),
            },
          ),
        );
      }
    }

    columnGroups.addAll([
      TrinaColumnGroup(
        title: AppLocalizations.of(context)!.upload_headers_label,
        fields: ['key', 'value'],
      ),
    ]);

    return TrinaGrid(
      columns: columns,
      rows: rows,
      columnGroups: columnGroups,
      onLoaded: (TrinaGridOnLoadedEvent event) {
        event.stateManager.setSelectingMode(TrinaGridSelectingMode.row);
        stateManager = event.stateManager;
      },
      configuration: const TrinaGridConfiguration(
        columnSize: TrinaGridColumnSizeConfig(
          autoSizeMode: TrinaAutoSizeMode.scale,
          resizeMode: TrinaResizeMode.none,
        ),
        style: TrinaGridStyleConfig(
          gridBackgroundColor: Colors.transparent,
          rowColor: Colors.transparent,
          cellColorInEditState: Colors.transparent,
          cellTextStyle: TextStyle(color: Color(0xFF828282)),
          columnTextStyle: TextStyle(color: Color(0xFF828282)),
        ),
      ),
    );
  }

  Widget _getParametersTable() {
    final List<TrinaColumn> columns = [];
    final List<TrinaColumnGroup> columnGroups = [];
    final List<TrinaRow> rows = [];

    columns.addAll([
      TrinaColumn(
        title: AppLocalizations.of(context)!.key,
        field: 'key',
        type: TrinaColumnType.text(),
        footerRenderer: (rendererContext) {
          return IconButton(
            onPressed: () {
              rendererContext.stateManager.insertRows(
                rendererContext.stateManager.rows.length,
                [rendererContext.stateManager.getNewRow()],
              );
            },
            icon: const Icon(Icons.add_circle),
            iconSize: 20,
            color: Colors.green,
            padding: EdgeInsets.zero,
          );
        },
      ),
      TrinaColumn(
        title: AppLocalizations.of(context)!.value,
        field: 'value',
        type: TrinaColumnType.text(),
        footerRenderer: (rendererContext) {
          return IconButton(
            onPressed: () {
              if (rendererContext.stateManager.rows.isNotEmpty) {
                rendererContext.stateManager
                    .removeRows([rendererContext.stateManager.rows.last]);
              }
            },
            icon: const Icon(Icons.remove_circle),
            iconSize: 20,
            color: Colors.red,
            padding: EdgeInsets.zero,
          );
        },
      ),
    ]);

    if (cursor.uploadParameters.isNotEmpty) {
      for (final entry in cursor.uploadParameters.entries) {
        rows.add(
          TrinaRow(
            cells: {
              "key": TrinaCell(value: entry.key),
              "value": TrinaCell(value: entry.value),
            },
          ),
        );
      }
    }

    columnGroups.addAll([
      TrinaColumnGroup(
        title: AppLocalizations.of(context)!.upload_parameters_label,
        fields: ['key', 'value'],
      ),
    ]);

    return TrinaGrid(
      columns: columns,
      rows: rows,
      columnGroups: columnGroups,
      onLoaded: (TrinaGridOnLoadedEvent event) {
        event.stateManager.setSelectingMode(TrinaGridSelectingMode.row);
        state2Manager = event.stateManager;
      },
      configuration: const TrinaGridConfiguration(
        columnSize: TrinaGridColumnSizeConfig(
          autoSizeMode: TrinaAutoSizeMode.scale,
          resizeMode: TrinaResizeMode.none,
        ),
        style: TrinaGridStyleConfig(
          gridBackgroundColor: Colors.transparent,
          rowColor: Colors.transparent,
          cellColorInEditState: Colors.transparent,
          cellTextStyle: TextStyle(color: Color(0xFF828282)),
          columnTextStyle: TextStyle(color: Color(0xFF828282)),
        ),
      ),
    );
  }

  Widget _getArgumentsTable() {
    final List<TrinaColumn> columns = [];
    final List<TrinaColumnGroup> columnGroups = [];
    final List<TrinaRow> rows = [];

    columns.addAll([
      TrinaColumn(
        title: AppLocalizations.of(context)!.key,
        field: 'key',
        type: TrinaColumnType.text(),
        footerRenderer: (rendererContext) {
          return IconButton(
            onPressed: () {
              rendererContext.stateManager.insertRows(
                rendererContext.stateManager.rows.length,
                [rendererContext.stateManager.getNewRow()],
              );
            },
            icon: const Icon(Icons.add_circle),
            iconSize: 20,
            color: Colors.green,
            padding: EdgeInsets.zero,
          );
        },
      ),
      TrinaColumn(
        title: AppLocalizations.of(context)!.value,
        field: 'value',
        type: TrinaColumnType.text(),
        footerRenderer: (rendererContext) {
          return IconButton(
            onPressed: () {
              if (rendererContext.stateManager.rows.isNotEmpty) {
                rendererContext.stateManager
                    .removeRows([rendererContext.stateManager.rows.last]);
              }
            },
            icon: const Icon(Icons.remove_circle),
            iconSize: 20,
            color: Colors.red,
            padding: EdgeInsets.zero,
          );
        },
      ),
    ]);

    if (cursor.uploadArguments.isNotEmpty) {
      for (final entry in cursor.uploadArguments.entries) {
        rows.add(
          TrinaRow(
            cells: {
              "key": TrinaCell(value: entry.key),
              "value": TrinaCell(value: entry.value),
            },
          ),
        );
      }
    }

    columnGroups.addAll([
      TrinaColumnGroup(
        title: AppLocalizations.of(context)!.upload_arguments_label,
        fields: ['key', 'value'],
      ),
    ]);

    return TrinaGrid(
      columns: columns,
      rows: rows,
      columnGroups: columnGroups,
      onLoaded: (TrinaGridOnLoadedEvent event) {
        event.stateManager.setSelectingMode(TrinaGridSelectingMode.row);
        state3Manager = event.stateManager;
      },
      configuration: const TrinaGridConfiguration(
        columnSize: TrinaGridColumnSizeConfig(
          autoSizeMode: TrinaAutoSizeMode.scale,
          resizeMode: TrinaResizeMode.none,
        ),
        style: TrinaGridStyleConfig(
          gridBackgroundColor: Colors.transparent,
          rowColor: Colors.transparent,
          cellColorInEditState: Colors.transparent,
          cellTextStyle: TextStyle(color: Color(0xFF828282)),
          columnTextStyle: TextStyle(color: Color(0xFF828282)),
        ),
      ),
    );
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

  Future<void> _saveShare() async {
    final box = await Hive.openBox<Share>("custom_upload");

    if (widget.editor != null) {
      final index = box.values.toList().indexOf(widget.editor!);
      if (index != -1) {
        cursor.uploadFormData = _switchValue;
        box.putAt(index, cursor);
      }
    } else {
      // check if uploader already exists
      if (box.values.where((e) => e.uploaderUrl == cursor.uploaderUrl).isEmpty) {
        cursor.uploadFormData = _switchValue;
        box.add(cursor);
      } else {
        showSnackBar(
          context,
          AppLocalizations.of(context)!.share_already_exists,
        );
      }
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  void didUpdateWidget(covariant AdvancedView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.pgpEnabled != widget.pgpEnabled) {
      setState(() {
        _pgpEnabled = widget.pgpEnabled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 80),
                child: DropdownButtonFormField(
                  items: <String>['POST', 'GET', 'PUT', 'PATCH']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  isExpanded: true,
                  onChanged: (String? value) {
                    value!;
                  },
                  onSaved: (value) {
                    cursor.method = value!;
                  },
                  value: cursor.method,
                  decoration: InputDecoration(
                    labelText:
                    AppLocalizations.of(context)!.method_label,
                  ),
                ),
              ),
              Expanded(
                child: TextFormField(
                  decoration: InputDecoration(
                    hintText:
                    AppLocalizations.of(context)!.upload_url_hint,
                    labelText:
                    AppLocalizations.of(context)!.upload_url_label,
                  ),
                  validator: (value) {
                    final ok = RegExp(
                      r"^(?:https?|s?ftp):\/\/[-A-Za-z0-9+&@#\/\[\]%?=~_!:.]*[-A-Za-z0-9+@#\/\]%=~_|]$",
                    ).hasMatch(value ?? "");
                    if ((value ?? "").isEmpty || !ok) {
                      return AppLocalizations.of(context)!.upload_url_error;
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
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: TextFormField(
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.form_data_name_hint,
                    labelText:
                    AppLocalizations.of(context)!.form_data_name_label,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)!.form_data_name_error;
                    }
                    return null;
                  },
                  initialValue: cursor.formDataName,
                  onSaved: (value) {
                    cursor.formDataName = value!;
                  },
                ),
              ),
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
                        style: OutlinedButton.styleFrom(
                            minimumSize: const Size(50, 30)
                        ),
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Import key'),
                        onPressed: () async {
                          final result =  await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['asc', 'pgp', 'txt', 'key']
                          );
                          final key = await importPgpKeyFromFile(result, context);
                          _pgpKeyController.text = key!.trim();
                        },
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        style: OutlinedButton.styleFrom(
                            minimumSize: const Size(50, 30)
                        ),
                        icon: const Icon(Icons.key),
                        label: const Text('Generate key'),
                        onPressed: () async {
                          final result = await generateNewPgpKey(context, cursor.uploaderUrl);
                          _pgpKeyController.text = result!;
                        },
                      ),
                    ],
                  ),
                ]
            ),
          ],
          const SizedBox(height: 15),
          SizedBox(height: 300, child: _getHeadersTable()),
          const SizedBox(height: 15),
          SizedBox(height: 300, child: _getParametersTable()),
          const SizedBox(height: 15),
          SizedBox(height: 300, child: _getArgumentsTable()),
          const SizedBox(height: 15),
          TextFormField(
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.url_response_hint,
              labelText: AppLocalizations.of(context)!.url_response_label,
            ),
            initialValue: cursor.uploaderResponseParser,
            onSaved: (value) {
              cursor.uploaderResponseParser = value!;
            },
          ),
          TextFormField(
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.url_error_response_hint,
              labelText: AppLocalizations.of(context)!.url_error_response_label,
            ),
            initialValue: cursor.uploaderErrorParser,
            onSaved: (value) {
              cursor.uploaderErrorParser = value!;
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: FilledButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState?.save();

                        cursor.uploadHeaders = stateManager.rows
                            .fold<Map<String, String>>({}, (map, row) {
                          map[row.cells["key"]!.value] =
                              row.cells["value"]!.value;
                          return map;
                        });

                        cursor.uploadParameters = state2Manager.rows
                            .fold<Map<String, String>>({}, (map, row) {
                          map[row.cells["key"]!.value] =
                              row.cells["value"]!.value;
                          return map;
                        });

                        cursor.uploadArguments = state3Manager.rows
                            .fold<Map<String, String>>({}, (map, row) {
                          map[row.cells["key"]!.value] =
                              row.cells["value"]!.value;
                          return map;
                        });

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
                          _saveShare();
                        }
                      }
                    },
                    child: Text(AppLocalizations.of(context)!.save),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(AppLocalizations.of(context)!.cancel),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
