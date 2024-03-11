import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:pluto_grid/pluto_grid.dart';

import '../../services/database.dart';
import '../../utils/show_message.dart';

class AdvancedView extends StatefulWidget {

  const AdvancedView(this.editor, this.index, {super.key});
  final Share? editor;
  final int? index;

  @override
  State<StatefulWidget> createState() {
    return AdvancedViewState();
  }
}


class AdvancedViewState extends State<AdvancedView> {
  late PlutoGridStateManager stateManager;
  late PlutoGridStateManager state2Manager;
  late PlutoGridStateManager state3Manager;
  late Share cursor;
  final _formKey = GlobalKey<FormState>();
  late bool _switchValue = false; // hack to get the switch to work

  _getHeadersTable() {
    final List<PlutoColumn> columns = [];
    final List<PlutoColumnGroup> columnGroups = [];
    final List<PlutoRow> rows = [];

    columns.addAll([
      PlutoColumn(
          title: 'Key',
          field: 'key',
          type: PlutoColumnType.text(),
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
              padding: const EdgeInsets.all(0),
            );
          }
      ),

      PlutoColumn(
          title: 'Value',
          field: 'value',
          type: PlutoColumnType.text(),
          footerRenderer: (rendererContext) {
            return IconButton(
              onPressed: () {
                rendererContext.stateManager.removeRows([rendererContext.stateManager.rows.last]);
              },
              icon: const Icon(Icons.remove_circle),
              iconSize: 20,
              color: Colors.red,
              padding: const EdgeInsets.all(0),
            );
          }
      ),
    ]);

    if (cursor.uploadHeaders.isNotEmpty) {
      for (var cell in cursor.uploadHeaders.entries) {
        rows.add(
            PlutoRow(cells: {
              "key": PlutoCell(value: cell.key),
              "value": PlutoCell(value: cell.value)
            })
        );
      }
    }

    columnGroups.addAll([
      PlutoColumnGroup(title: "Upload Headers", fields: ['key', 'value']),
    ]);

    return PlutoGrid(
      columns: columns,
      rows: rows,
      columnGroups: columnGroups,
      onLoaded: (PlutoGridOnLoadedEvent event) {
        event.stateManager.setSelectingMode(PlutoGridSelectingMode.row);
        stateManager = event.stateManager;
      },
      configuration: const PlutoGridConfiguration(
          columnSize: PlutoGridColumnSizeConfig(
              autoSizeMode: PlutoAutoSizeMode.scale,
              resizeMode: PlutoResizeMode.none
          ),
          style: PlutoGridStyleConfig(
            // since pluto grid does not respect the system theme, we have to manually set the colors
            gridBackgroundColor: Colors.transparent,
            rowColor: Colors.transparent,
            cellColorInEditState: Colors.transparent,
            cellTextStyle: TextStyle(color: Color(0xFF828282)),
            columnTextStyle: TextStyle(color: Color(0xFF828282)),
          )
      ),
    );
  }

  _getParametersTable() {
    final List<PlutoColumn> columns = [];
    final List<PlutoColumnGroup> columnGroups = [];
    final List<PlutoRow> rows = [];

    columns.addAll([
      PlutoColumn(
          title: 'Key',
          field: 'key',
          type: PlutoColumnType.text(),
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
              padding: const EdgeInsets.all(0),
            );
          }
      ),
      PlutoColumn(
          title: 'Value',
          field: 'value',
          type: PlutoColumnType.text(),
          footerRenderer: (rendererContext) {
            return IconButton(
              onPressed: () {
                rendererContext.stateManager.removeRows([rendererContext.stateManager.rows.last]);
              },
              icon: const Icon(Icons.remove_circle),
              iconSize: 20,
              color: Colors.red,
              padding: const EdgeInsets.all(0),
            );
          }
      ),
    ]);

    if (cursor.uploadParameters.isNotEmpty) {
      for (var cell in cursor.uploadParameters.entries) {
        rows.add(
            PlutoRow(cells: {
              "key": PlutoCell(value: cell.key),
              "value": PlutoCell(value: cell.value)
            })
        );
      }
    }

    columnGroups.addAll([
      PlutoColumnGroup(title: "Upload Parameters", fields: ['key', 'value']),
    ]);


    return PlutoGrid(
      columns: columns,
      rows: rows,
      columnGroups: columnGroups,
      onLoaded: (PlutoGridOnLoadedEvent event) {
        event.stateManager.setSelectingMode(PlutoGridSelectingMode.row);
        state2Manager = event.stateManager;
      },
      configuration: const PlutoGridConfiguration(
          columnSize: PlutoGridColumnSizeConfig(
              autoSizeMode: PlutoAutoSizeMode.scale,
              resizeMode: PlutoResizeMode.none
          ),
          style: PlutoGridStyleConfig(
            // since pluto grid does not respect the system theme, we have to manually set the colors
            gridBackgroundColor: Colors.transparent,
            rowColor: Colors.transparent,
            cellColorInEditState: Colors.transparent,
            cellTextStyle: TextStyle(color: Color(0xFF828282)),
            columnTextStyle: TextStyle(color: Color(0xFF828282)),
          )
      ),
    );
  }

  _getArgumentsTable() {
    final List<PlutoColumn> columns = [];
    final List<PlutoColumnGroup> columnGroups = [];
    final List<PlutoRow> rows = [];

    columns.addAll([
      PlutoColumn(
          title: 'Key',
          field: 'key',
          type: PlutoColumnType.text(),
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
              padding: const EdgeInsets.all(0),
            );
          }
      ),
      PlutoColumn(
          title: 'Value',
          field: 'value',
          type: PlutoColumnType.text(),
          footerRenderer: (rendererContext) {
            return IconButton(
              onPressed: () {
                rendererContext.stateManager.removeRows([rendererContext.stateManager.rows.last]);
              },
              icon: const Icon(Icons.remove_circle),
              iconSize: 20,
              color: Colors.red,
              padding: const EdgeInsets.all(0),
            );
          }
      ),
    ]);

    if (cursor.uploadArguments.isNotEmpty) {
      for (var cell in cursor.uploadArguments.entries) {
        rows.add(
            PlutoRow(cells: {
              "key": PlutoCell(value: cell.key),
              "value": PlutoCell(value: cell.value)
            })
        );
      }
    }

    columnGroups.addAll([
      PlutoColumnGroup(title: "Upload Arguments", fields: ['key', 'value']),
    ]);


    return PlutoGrid(
      columns: columns,
      rows: rows,
      columnGroups: columnGroups,
      onLoaded: (PlutoGridOnLoadedEvent event) {
        event.stateManager.setSelectingMode(PlutoGridSelectingMode.row);
        state3Manager = event.stateManager;
      },
      configuration: const PlutoGridConfiguration(
          columnSize: PlutoGridColumnSizeConfig(
              autoSizeMode: PlutoAutoSizeMode.scale,
              resizeMode: PlutoResizeMode.none
          ),
          style: PlutoGridStyleConfig(
            // since pluto grid does not respect the system theme, we have to manually set the colors
            gridBackgroundColor: Colors.transparent,
            rowColor: Colors.transparent,
            cellColorInEditState: Colors.transparent,
            cellTextStyle: TextStyle(color: Color(0xFF828282)),
            columnTextStyle: TextStyle(color: Color(0xFF828282)),
          )
      ),
    );
  }

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
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  constraints: const BoxConstraints(maxWidth: 80),
                  child: DropdownButtonFormField(items: <String>['POST', 'GET', 'PUT']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                    isExpanded: true,
                    onChanged: (String? value) { value!; },
                    onSaved: (value) {cursor.method = value!;},
                    value: cursor.method,
                    decoration: const InputDecoration(
                        labelText: "Method *"
                    ),
                  ),
                ),

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
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                Switch(value: _switchValue, onChanged: (value) {setState(() {
                  _switchValue = value;
                });}),
                const Text("Use file encoding"),
              ],
            ),
            // SizedBox prevents the table from overflowing
            SizedBox(
              height: 300,
              child: _getHeadersTable(),
            ),
            SizedBox(
              height: 300,
              child: _getParametersTable(),
            ),
            SizedBox(
              height: 300,
              child: _getArgumentsTable(),
            ),
            TextFormField(
              decoration: const InputDecoration(
                hintText: "The response of the url to parse",
                labelText: "URL Response",
              ),
              initialValue: cursor.uploaderResponseParser,
              onSaved: (value) {cursor.uploaderResponseParser = value!;},
            ),
            TextFormField(
              decoration: const InputDecoration(
                hintText: "The error response of the url to parse",
                labelText: "URL Error Response",
              ),
              initialValue: cursor.uploaderErrorParser,
              onSaved: (value) {cursor.uploaderErrorParser = value!;},
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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

                            cursor.uploadHeaders = stateManager.rows.fold<Map<String, String>>({}, (previousValue, element) {
                              previousValue[element.cells["key"]!.value] = element.cells["value"]!.value;
                              return previousValue;
                            });

                            cursor.uploadParameters = state2Manager.rows.fold<Map<String, String>>({}, (previousValue, element) {
                              previousValue[element.cells["key"]!.value] = element.cells["value"]!.value;
                              return previousValue;
                            });

                            cursor.uploadArguments = state3Manager.rows.fold<Map<String, String>>({}, (previousValue, element) {
                              previousValue[element.cells["key"]!.value] = element.cells["value"]!.value;
                              return previousValue;
                            });

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
          ]
      ),
    );
  }
}