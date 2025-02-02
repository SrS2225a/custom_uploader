import 'package:custom_uploader/views/upload_logs.dart';
import 'package:custom_uploader/services/database.dart';
import 'package:custom_uploader/services/import_export.dart';
import 'package:custom_uploader/views/add_uploader.dart';
import 'package:custom_uploader/utils/build_favicon.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:dio/dio.dart';

class Uploader extends StatefulWidget {
  const Uploader({super.key, required this.title});
  final String title;

  @override
  State<Uploader> createState() => _MyUploaderState();
}

class _MyUploaderState extends State<Uploader> {
  late Dio dio;
  int previousSelectedIndex = 0;

  @override
  void initState() {
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

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.list), // Logs button
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UploadLogsScreen()),
              );
            },
            tooltip: "View Logs",
          ),
          PopupMenuButton<int>(
            onSelected: (value) async {
              if (value == 0) {
                final filePicker = await FilePicker.platform.pickFiles(allowMultiple: false);
                if (filePicker != null && filePicker.files.isNotEmpty) {
                  final file = filePicker.files.first;
                  if (file.path != null) {
                    ImportExportService.import(file: file, context: context);
                  }
                }
              } else if (value == 1) {
                final shareBox = Hive.box<Share>("custom_upload");
                final cursor = shareBox.toMap();
                int i = 0;
                for (var entry in cursor.entries) {
                  if (entry.value.selectedUploader) break;
                  i++;
                }
                ImportExportService.export(context: context, index: i);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<int>(value: 0, child: Text("Import from file")),
              const PopupMenuItem<int>(value: 1, child: Text("Export to file")),
            ],
          ),
        ],
      ),
      body: ValueListenableBuilder<Box<Share>>(
        valueListenable: Hive.box<Share>("custom_upload").listenable(),
        builder: (context, box, _) {
          if (box.isEmpty) {
            return Center(
              child: Text(
                "You have no custom uploaders.",
                style: Theme.of(context).textTheme.titleLarge,
              ),
            );
          }
          return ListView.builder(
            itemCount: box.length,
            itemBuilder: (context, index) {
              final Share? c = box.getAt(index);
              if (c == null) return const SizedBox();

              return Dismissible(
                key: Key(c.uploaderUrl),
                background: Container(
                  color: Colors.amber,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.edit, color: Colors.white),
                ),
                secondaryBackground: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.startToEnd) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => Creator(editor: c, index: index),
                      ),
                    );
                    return false;
                  } else if (direction == DismissDirection.endToStart) {
                    return await showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text("Delete ${c.uploaderUrl}"),
                          content: const Text("Are you sure you want to delete this uploader?"),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () async {
                                Navigator.of(context).pop(true);
                              },
                              child: const Text("Yes"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text("No"),
                            ),
                          ],
                        );
                      },
                    );
                  }
                  return false;
                },
                onDismissed: (direction) async {
                  if (direction == DismissDirection.endToStart) {
                    await box.deleteAt(index);
                    if (index == previousSelectedIndex) {
                      previousSelectedIndex = 0;
                    }
                  }
                },
                child: Column(
                  children: [
                    ListTile(
                      leading: buildFaviconImage(c.uploaderUrl),
                      title: Text(
                        c.uploaderUrl,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 16,
                          color: c.selectedUploader ? Colors.blueAccent : null,
                        ),
                      ),
                      subtitle: Text('Upload Method: ${c.method ?? "POST"}'),
                      onTap: () {
                        Box<Share> shareBox = Hive.box<Share>("custom_upload");
                        var pre = shareBox.getAt(previousSelectedIndex);
                        if (pre != null) {
                          shareBox.putAt(previousSelectedIndex, Share(
                            pre.uploaderUrl, pre.formDataName, pre.uploadFormData,
                            pre.uploadHeaders, pre.uploadParameters, pre.uploadArguments,
                            pre.uploaderResponseParser, pre.uploaderErrorParser,
                            false, pre.method,
                          ));
                        }
                        previousSelectedIndex = index;
                        shareBox.putAt(index, Share(
                          c.uploaderUrl, c.formDataName, c.uploadFormData,
                          c.uploadHeaders, c.uploadParameters, c.uploadArguments,
                          c.uploaderResponseParser, c.uploaderErrorParser,
                          true, pre!.method,
                        ));
                      },
                    ),
                    Divider(height: 1, thickness: 1, color: Colors.grey[700]),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => Creator(editor: null, index: 0)),
          );
        },
        tooltip: 'Add Uploader',
        child: const Icon(Icons.add),
      ),
    );
  }
}