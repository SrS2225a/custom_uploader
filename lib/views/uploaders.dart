import 'dart:typed_data';

import 'package:custom_uploader/services/database.dart';
import 'package:custom_uploader/services/import_export.dart';
import 'package:custom_uploader/views/add_uploader.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';

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

    // for caching the responses
    final options = CacheOptions(store: MemCacheStore(), policy: CachePolicy.forceCache, maxStale: const Duration(days: 7));
    dio = Dio()..interceptors.add(DioCacheInterceptor(options: options));

    super.initState();
  }

  Future<Uint8List?> _getFavicon(String url) async {
    try {
      // no need to cache it in the app, since dio caches it for us
      Response<List<int>> response = await dio.get(
        'https://www.google.com/s2/favicons?domain=$url&sz=128',
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        return Uint8List.fromList(response.data!);
      }
    } catch (error) {
      print('Error fetching favicon: $error');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    Map<String, Uint8List?> faviconCache = {};

    Widget _buildDivider() => const SizedBox(height: 5);
    Widget _buildFaviconImage(String uploaderUrl) {
      if (faviconCache.containsKey(uploaderUrl)) {
        return Image.memory(faviconCache[uploaderUrl]!, width: 32, height: 32, fit: BoxFit.fill);
      } else {
        return FutureBuilder<Uint8List?>(
          future: _getFavicon(uploaderUrl),
          builder: (context, snapshot) {
            if (snapshot.hasError || snapshot.data == null) {
              return const Icon(Icons.public);
            } else {
              faviconCache[uploaderUrl] = snapshot.data;
              return Image.memory(snapshot.data!, width: 32, height: 32, fit: BoxFit.fill);
            }
          },
        );
      }
    }

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
            })
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

                Future<Uint8List?> fetchFavicon = _getFavicon(c!.uploaderUrl);

                return InkWell(
                  onTap: () {
                      Box<Share> shareBox = Hive.box<Share>("custom_upload");
                      // sets the current selected uploader
                      var pre = shareBox.getAt(previousSelectedIndex);
                      if (pre != null) {
                        shareBox.putAt(previousSelectedIndex, Share(pre.uploaderUrl, pre.formDataName, pre.uploadFormData, pre.uploadHeaders, c.uploadParameters, pre.uploadArguments, pre.uploaderResponseParser, pre.uploaderErrorParser, false, pre.method));
                      }
                      previousSelectedIndex = index;

                      shareBox.putAt(index, Share(c.uploaderUrl, c.formDataName, c.uploadFormData, c.uploadHeaders, c.uploadParameters, c.uploadArguments, c.uploaderResponseParser, c.uploaderErrorParser, true, pre!.method));
                  },
                  child: Card(
                    margin: const EdgeInsets.all(10),
                    color: c.selectedUploader ? Colors.blueAccent : null,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _buildDivider(),
                          Row(
                            children: <Widget>[
                              _buildFaviconImage(c.uploaderUrl),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width - 86,
                                    child: Text(c.uploaderUrl, overflow: TextOverflow.ellipsis, maxLines: 1),
                                  ),
                                  _buildDivider(),
                                  Text('Upload Method: ${c.method ?? "POST"}'),
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
                                              // fix index out of range error when deleting the last uploader
                                              if (index == previousSelectedIndex) {
                                                previousSelectedIndex = 0;
                                              }
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