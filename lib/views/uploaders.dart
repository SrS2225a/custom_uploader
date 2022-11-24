import 'package:custom_uploader/services/database.dart';
import 'package:custom_uploader/services/import_export.dart';
import 'package:custom_uploader/views/add_new.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';

class Uploader extends StatefulWidget {
  const Uploader({super.key, required this.title});
  final String title;
  @override
  State<Uploader> createState() => _MyUploaderState();
}

class _MyUploaderState extends State<Uploader> {
  int previousSelectedIndex = 0;

  @override
  void initState() {
    super.initState();

    // for keeping track of the selected index
    Box<Share> shareBox = Hive.box<Share>("custom_upload");
    var cursor = shareBox.toMap();
    int i = 0;
    for (var entries in cursor.entries) {
      if (entries.value.selectedUploader) {
        previousSelectedIndex = i;
        break;
      }
      i++;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget _buildDivider() => const SizedBox(height: 5);
    return Scaffold(
        appBar: AppBar(
        title: Text(widget.title),
        actions: [
          PopupMenuButton(itemBuilder: (context) {
            return [
              const PopupMenuItem<int>(
                value: 0,
                child: Text("Import from file"),
              ),
              const PopupMenuItem<int>(
                value: 1,
                child: Text("Export to file"),
              ),
            ];
          },
            onSelected: (value) {
              if (value == 0) {
                // allow user to import from file
                final filePicker = FilePicker.platform.pickFiles(allowMultiple: false);
                filePicker.then((value) {
                  if (value != null) {
                    final file = value.files.first;
                    final path = file.path;
                    if (path != null) {
                      // import from file
                      ImportExportService.import(file: file, context: context);
                    }
                  }
                });
              } else if (value == 1) {
                // allow user to export to file
                // get the users index selection
                final shareBox = Hive.box<Share>("custom_upload");
                final cursor = shareBox.toMap();
                int i = 0;
                for (var entries in cursor.entries) {
                  if (entries.value.selectedUploader) {
                    break;
                  }
                  i++;
                }
                ImportExportService.export(context: context, index: i);

              }
            },)
        ],
    ),

      body: ValueListenableBuilder(
        valueListenable: Hive.box<Share>("custom_upload").listenable(),
        builder: (context, Box<Share> box, _) {
          if (box.values.isEmpty) {
            return Center(
              child: Text("You have no custom uploaders. Create one now!", style: Theme.of(context).textTheme.headline6)
            );
          } else {
            return ListView.builder(
              itemCount: box.length,
              itemBuilder: (context, index) {
                // get the share object from the box
                Share? c = box.getAt(index);

                return InkWell(
                  onTap: () {
                      Box<Share> shareBox = Hive.box<Share>("custom_upload");

                      // sets the current selected uploader
                      var pre = shareBox.getAt(previousSelectedIndex);
                      if (pre != null) {
                        shareBox.putAt(previousSelectedIndex, Share(pre.uploaderUrl, pre.formDataName, pre.uploadFormData, pre.uploadHeaders, c.uploadParameters, pre.uploadArguments, pre.uploaderResponseParser, pre.uploaderErrorParser, false));
                      }
                      previousSelectedIndex = index;

                      shareBox.putAt(index, Share(c.uploaderUrl, c.formDataName, c.uploadFormData, c.uploadHeaders, c.uploadParameters, c.uploadArguments, c.uploaderResponseParser, c.uploaderErrorParser, true));

                      setState(() {
                        c.selectedUploader;
                      });
                  },
                  onLongPress: () {
                    // edit
                    Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => Creator(editor: c, index: index,))
                    );
                  },
                  child: Card(
                    color: c!.selectedUploader ? Colors.blueAccent : null,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _buildDivider(),
                          Text(c.uploaderUrl),
                          _buildDivider(),
                          Text(c.formDataName),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              // delete button
                              IconButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    barrierDismissible: true,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text("Delete ${c.uploaderUrl}?"),
                                        content: const Text("Are you sure you want to delete this uploader?"),
                                        actions: <Widget>[
                                          TextButton(
                                              onPressed: () async {
                                                Navigator.of(context).pop();
                                                await box.deleteAt(index);
                                              }, child: const Text("Yes")
                                          ),
                                          TextButton(
                                            child: const Text("No"),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                          )
                                        ],
                                      );
                                    },
                                  );
                                },
                                icon: const Icon(Icons.delete, color: Colors.red)
                              )
                            ],
                          )
                        ],
                      ),
                    ),

                  ),
                );
              },
            );
          }

        },
      ),


      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // add new
          Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => Creator(editor: null, index: 0,))
          );
        },
        tooltip: 'Add new',
        child: const Icon(Icons.add),
      ),
    );

  }
}