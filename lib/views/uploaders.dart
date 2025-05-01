import 'package:custom_uploader/views/upload_logs.dart';
import 'package:custom_uploader/services/database.dart';
import 'package:custom_uploader/services/import_export.dart';
import 'package:custom_uploader/views/http_share_form.dart';
import 'package:custom_uploader/views/ftp_share_form.dart';
import 'package:custom_uploader/utils/build_favicon.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:dio/dio.dart';
import 'package:collection/collection.dart';

class Uploaders extends StatefulWidget {
  const Uploaders({super.key, required this.title});
  final String title;

  @override
  State<Uploaders> createState() => _MyUploaderState();
}

class _MyUploaderState extends State<Uploaders> {
  late Dio dio;

  @override
  void initState() {
    // for keeping track of the selected index
    // Box<Share> shareBox = Hive.box<Share>("custom_upload");
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final httpBox = Hive.box<Share>('custom_upload');
    final ftpBox = Hive.box<NetworkShare>('share_upload');

    void editItem(Object item, String shareType) {
      if (shareType == 'http') {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => HTTPShareForm(editor: item as Share),
          )
        );
      } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => FTPShareForm(editor: item as NetworkShare),
            ),
          );
        }
    }

    Future<void> deleteItem(int delIndex, String shareType, String parsedUrl) async {
      bool? confirmDelete = await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Delete $parsedUrl"),
            content: const Text(
                "Are you sure you want to delete this uploader?"),
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
        if (shareType == 'http') {
          httpBox.deleteAt(delIndex);
        } else {
          ftpBox.deleteAt(delIndex);
        }
      }
    }

    updateSelectedUploader(int index, dynamic item, Box currentBox) async {
      final httpBox = await Hive.openBox<Share>("custom_upload");
      final ftpBox = await Hive.openBox<NetworkShare>("share_upload");

      void updateShare(int index, Share newShare) {
        httpBox.putAt(index, newShare);
      }

      void updateNetworkShare(int index, NetworkShare newShare) {
        ftpBox.putAt(index, newShare);
      }

      // Search for selected item in BOTH boxes
      int previouslySelectedHttp = httpBox.values.toList().indexWhere((element) => element.selectedUploader == true);
      int previouslySelectedFtp = ftpBox.values.toList().indexWhere((element) => element.selected == true);

      // Unselect previous Share if found
      if (previouslySelectedHttp != -1) {
        final selectedShare = httpBox.getAt(previouslySelectedHttp);
        if (selectedShare is Share) {
          selectedShare.setSelectedUploader(false);
          updateShare(previouslySelectedHttp, selectedShare);
        }
      }

      // Unselect previous NetworkShare if found
      if (previouslySelectedFtp != -1) {
        final selectedNetworkShare = ftpBox.getAt(previouslySelectedFtp);
        if (selectedNetworkShare is NetworkShare) {
          selectedNetworkShare.setSelectedShare(false);
          updateNetworkShare(previouslySelectedFtp, selectedNetworkShare);
        }
      }

      // Select the new item in its box
      if (item is Share) {
        item.setSelectedUploader(true);
        updateShare(index, item);
      } else if (item is NetworkShare) {
        item.setSelectedShare(true);
        updateNetworkShare(index, item);
      }
    }

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
                final networkShare = Hive.box<NetworkShare>("share_upload");
                int networkSelectedIndex = networkShare.values.toList().indexWhere((share) => share.selected ?? false);

                if(networkSelectedIndex != -1){
                  const SnackBar(
                    content: Text("Currently, ftp shares cannot be imported or exported"),
                  );
                } else {
                  final shareBox = Hive.box<Share>("custom_upload");
                  int selectedIndex = shareBox.values.toList().indexWhere((share) => share.selectedUploader);
                  if (selectedIndex != -1) {
                    ImportExportService.export(
                      context: context, index: selectedIndex);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("No uploader selected"),
                      ),
                    );
                  }
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

        body: ValueListenableBuilder(
          valueListenable: httpBox.listenable(),
          builder: (context, _, __) {
            return ValueListenableBuilder(
              valueListenable: ftpBox.listenable(),
              builder: (context, __, ___) {
                final httpShares = httpBox.values.toList();
                final ftpShares = ftpBox.values.toList();

                if(httpShares.isEmpty && ftpShares.isEmpty){
                  return Center(
                    child: Text("No Shares",
                      style: Theme.of(context).textTheme.titleLarge,
                    )
                  );
                }

                String removeProtocol(String url) => url.replaceAll(RegExp(r'^[a-zA-Z]+:\/\/'), '');

                final combinedShares = [
                  ...httpShares.mapIndexed((i, share) => {
                    'index': i,
                    'share': share,
                    'type': 'http',
                  }),
                  ...ftpShares.mapIndexed((i, share) => {
                    'index': i,
                    'share': share,
                    'type': 'ftp',
                  })
                ];

                combinedShares.sort((a, b) {
                  final aShare = a['share'];
                  final bShare = b['share'];
                  final aUrl = a['type'] == 'http'
                      ? removeProtocol((aShare as Share).uploaderUrl)
                      :  removeProtocol((aShare as NetworkShare).domain);
                  final bUrl = b['type'] == 'http'
                      ? removeProtocol((bShare as Share).uploaderUrl)
                      : removeProtocol((bShare as NetworkShare).domain);
                  return aUrl.compareTo(bUrl);
                });

                return ListView.builder(
                  itemCount: combinedShares.length,
                  itemBuilder: (context, index) {
                    final shareData = combinedShares[index];
                    final share = shareData['share'];
                    final shareType = shareData['type'];
                    final shareIndex = shareData['index'] as int;
                    final parsedUrl = shareType == 'http'
                        ? removeProtocol((shareData['share'] as Share).uploaderUrl)
                        : removeProtocol((shareData['share'] as NetworkShare).domain);

                    return GestureDetector(
                      onLongPress: () {
                        showModalBottomSheet(context: context, builder: (context) {
                          return Wrap(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.edit, color: Colors.amber),
                                title: const Text("Edit"),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  editItem(share!, shareType.toString());
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.delete, color: Colors.red),
                                title: const Text("Delete"),
                                  onTap: () async {
                                    Navigator.of(context).pop();
                                    deleteItem(shareData['index'] as int, shareType.toString(), parsedUrl);
                                  }
                              ),
                            ],
                          );
                        });
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
                            editItem(share!, shareType.toString());
                          } else if (direction == DismissDirection.endToStart) {;
                            deleteItem(shareData['index'] as int, shareType.toString(), parsedUrl);
                          }
                          return null;
                        },
                        child: Column(
                          children: [
                          ListTile(
                            leading: shareType == 'http'
                                ? buildFaviconImage((share as Share).uploaderUrl)
                                : buildFaviconImage((share as NetworkShare).domain ?? ""),
                            title: Text(
                              parsedUrl,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                color: (share is Share && share.selectedUploader) || (share is NetworkShare && (share.selected ?? false))
                                    ? Colors.blueAccent
                                    : null,
                              ),
                            ),
                            subtitle: share is Share
                                ? Text(
                                    'Upload Method: ${share.method ?? "POST"} • Type: ${shareType.toString().toUpperCase()}',
                                  )
                                : Text(
                                    'Type: ${shareType.toString().toUpperCase()}',
                                  ),
                            onTap: () {
                              final shareBox = shareType == 'http' ? httpBox : ftpBox;
                              updateSelectedUploader(shareIndex, share, shareBox);
                            }
                            ),
                            Divider(height: 1, thickness: 1, color: Colors.grey[700]),
                        ]
                        ),
                      )
                    );
                  },
                );
              },
            );
          },
        ),

      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
        foregroundColor: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // M3 rounded FAB shape
        ),
        spacing: 6,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.storage, size: 32),
            // label: 'FTP Upload',
            labelStyle: Theme.of(context).textTheme.labelLarge,
            labelBackgroundColor: Theme.of(context).colorScheme.surfaceVariant,
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => FTPShareForm(editor: null))),
          ),
          SpeedDialChild(
            child: const Icon(Icons.http, size: 32),
            //  label: 'HTTP Upload',
            labelStyle: Theme.of(context).textTheme.labelLarge,
            labelBackgroundColor: Theme.of(context).colorScheme.surfaceVariant,
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) =>  HTTPShareForm(editor: null))),
          ),
          // SpeedDialChild(
          //   child: const Icon(Icons.folder_shared, size: 32),
          //   label: 'SMB Upload',
          //   labelStyle: Theme.of(context).textTheme.labelLarge,
          //   labelBackgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          //   backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          //   foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
          //   onTap: () => Navigator.pushNamed(context, '/smb'),
          // ),
        ],
      )
    );
  }
}
