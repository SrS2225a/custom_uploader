import 'package:custom_uploader/views/upload_logs.dart';
import 'package:custom_uploader/services/database.dart';
import 'package:custom_uploader/services/import_export.dart';
import 'package:custom_uploader/views/add_uploader.dart';
import 'package:custom_uploader/utils/build_favicon.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:dio/dio.dart';
import 'package:collection/collection.dart';

class Uploader extends StatefulWidget {
  const Uploader({super.key, required this.title});
  final String title;

  @override
  State<Uploader> createState() => _MyUploaderState();
}

class _MyUploaderState extends State<Uploader> {
  late Dio dio;

  @override
  void initState() {
    // for keeping track of the selected index
    Box<Share> shareBox = Hive.box<Share>("custom_upload");
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
                int selectedIndex = shareBox.values.toList().indexWhere((share) => share.selectedUploader);

                if (selectedIndex != -1) {
                  ImportExportService.export(context: context, index: selectedIndex);
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<int>(value: 0, child: Text("Import from file")),
              const PopupMenuItem<int>(value: 1, child: Text("Export selected to file")),
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

          // remove the protocol from the url, then sorts by it
          String removeProtocol(String url) {
            return url.replaceFirst(RegExp(r'^[a-zA-Z]+:\/\/'), '');
          }
          final indexedShares = box.values
              .mapIndexed((index, share) => {'index': index, 'share': share})
              .toList()
              ..sort((a, b) => removeProtocol((a['share'] as Share).uploaderUrl)
                  .compareTo(removeProtocol((b['share'] as Share).uploaderUrl))); // DESC

          return ListView.builder(
            itemCount: indexedShares.length,
            itemBuilder: (context, index) {
              final item = indexedShares[index]['share'] as Share?;
              if (item == null) return const SizedBox();
              final originalIndex = indexedShares[index]['index'] as int; // get the original index of the item so we can update/delete it
              final String parsedUrl = removeProtocol(item.uploaderUrl); // Parsed URL without protocol

              return GestureDetector(
                onLongPress: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) {
                      return Wrap(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.edit, color: Colors.amber),
                            title: const Text("Edit"),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => Creator(editor: item, index: originalIndex),
                                ),
                              );
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.delete, color: Colors.red),
                            title: const Text("Delete"),
                            onTap: () async {
                              Navigator.of(context).pop();
                              bool? confirmDelete = await showDialog(
                                context: context,
                                barrierDismissible: true,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text("Delete $parsedUrl"),
                                    content: const Text("Are you sure you want to delete this uploader?"),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(true),
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
                              if (confirmDelete == true) {
                                await box.deleteAt(originalIndex);
                              }
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Dismissible(
                  key: Key(parsedUrl),
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
                          builder: (context) => Creator(editor: item, index: originalIndex),
                        ),
                      );
                      return false;
                    } else if (direction == DismissDirection.endToStart) {
                      return await showDialog(
                        context: context,
                        barrierDismissible: true,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text("Delete $parsedUrl"),
                            content: const Text("Are you sure you want to delete this uploader?"),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
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
                      await box.deleteAt(originalIndex);
                    }
                  },
                  child: Column(
                    children: [
                      ListTile(
                        leading: buildFaviconImage(item.uploaderUrl),
                        title: Text(
                          parsedUrl,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 16,
                            color: item.selectedUploader ? Colors.blueAccent : null,
                          ),
                        ),
                        subtitle: Text('Upload Method: ${item.method ?? "POST"}'),
                        onTap: () {
                          Box<Share> shareBox = Hive.box<Share>("custom_upload");

                          // Find the previously selected item and update it to "false"
                          for (int i = 0; i < shareBox.length; i++) {
                            var pre = shareBox.getAt(i);
                            if (pre != null && pre.selectedUploader) { // Assuming there's a field indicating selection
                              shareBox.putAt(i, Share(
                                pre.uploaderUrl, pre.formDataName, pre.uploadFormData,
                                pre.uploadHeaders, pre.uploadParameters, pre.uploadArguments,
                                pre.uploaderResponseParser, pre.uploaderErrorParser,
                                false, pre.method,
                              ));
                              break; // Stop after updating the first found selection
                            }
                          }

                          // Update the new selected item to "true"
                          shareBox.putAt(originalIndex, Share(
                            item.uploaderUrl, item.formDataName, item.uploadFormData,
                            item.uploadHeaders, item.uploadParameters, item.uploadArguments,
                            item.uploaderResponseParser, item.uploaderErrorParser,
                            true, item.method,
                          ));
                        },
                      ),
                      Divider(height: 1, thickness: 1, color: Colors.grey[700]),
                    ],
                  ),
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
