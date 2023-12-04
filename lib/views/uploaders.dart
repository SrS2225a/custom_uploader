import 'package:custom_uploader/services/database.dart';
import 'package:custom_uploader/services/import_export.dart';
import 'package:custom_uploader/views/add_new.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:dio/dio.dart';
import 'package:xml/xml.dart' as xml;

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

  Future<String?> _getFaviconUrl(String url) async {
    try {
      var websiteUrl = url.split("/")[2];
      // no need to cache it in the app, since the website caches it for us
      Response response = await Dio().get('https://nyxgoddess.org/api/favicon/?domain=$websiteUrl&normalize-url=true');
      if (response.statusCode == 200) {
        Map<String, dynamic> data = response.data;
        if (data.containsKey('icons') && data['icons'].isNotEmpty) {
          return data['icons'][0]['src'];
        }
      }
    } catch (error) {
      print('Error fetching favicon: $error');
    }
    return null;
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
                      ImportExportService.import(file: file, context: context);
                    }
                  }
                });
              } else if (value == 1) {
                // allow user to export to file
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
              child: Text("You have no custom uploaders.", style: Theme.of(context).textTheme.titleLarge)
            );
          } else {
            return ListView.builder(
              itemCount: box.length,
              itemBuilder: (context, index) {
                // get the share object from the box
                Share? c = box.getAt(index);

                late Future<String?> _fetchFavicon = _getFaviconUrl(c!.uploaderUrl);

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
                  child: Card(
                    margin: const EdgeInsets.all(10),
                    color: c!.selectedUploader ? Colors.blueAccent : null,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _buildDivider(),
                          Row(
                            children: <Widget>[
                              FutureBuilder<String?>(
                                future: _fetchFavicon,
                                builder: (context, snapshot) {
                                  if (snapshot.hasError || snapshot.data == null) {
                                    return Icon(Icons.public);
                                  } else {
                                    return Image.network(snapshot.data!, width: 32, height: 32, fit: BoxFit.fill);
                                  }
                                },
                              ),
                              SizedBox(width: 10), // Adjust the spacing as needed
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(c.uploaderUrl),
                                  _buildDivider(),
                                  Text(c.formDataName),
                                ],
                              ),
                            ],
                          ),
                          _buildDivider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              IconButton(
                                onPressed: () {
                                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => Creator(editor: c, index: index)));
                                },
                                icon: const Icon(Icons.edit),
                              ),
                              IconButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    barrierDismissible: true,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text("Delete ${c.uploaderUrl}"),
                                        content: const Text("Are you sure you want to delete this uploader?"),
                                        actions: <Widget>[
                                          TextButton(
                                            onPressed: () async {
                                              Navigator.of(context).pop();
                                              await box.deleteAt(index);
                                            },
                                            child: const Text("Yes"),
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
                                icon: const Icon(Icons.delete, color: Colors.red),
                              ),
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

      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 30),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => Creator(editor: null, index: 0,)));
        },
          child: const Icon(Icons.add),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
    );
  }
}