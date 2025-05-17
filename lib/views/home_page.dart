import 'dart:io';
import 'dart:math';

import 'package:custom_uploader/services/file_upload.dart';
import 'package:custom_uploader/utils/show_message.dart';
import 'package:custom_uploader/views/uploaders.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart';
import 'package:hive/hive.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter_sharing_intent/flutter_sharing_intent.dart';
import 'package:share_plus/share_plus.dart' as share_plus;
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../services/database.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  Box<Share> shareBox = Hive.box<Share>("custom_upload");

  String _fileName = "";
  double _progressPercentValue = 0;
  bool _hasBeenPressed = false;
  final List<String> _uploadedUrls = [];

  void _setUploadProgress(int sentBytes, int totalBytes) {
    double uploadProgress(double value, double originalMinValue, double originalMaxValue, double translatedMinValue, double translatedMaxValue) {
      double clampedValue = value - originalMinValue;
      double clampedRange = max(0.0, originalMaxValue - originalMinValue);

      return (clampedValue.clamp(0.0, clampedRange) / clampedRange) * (translatedMaxValue - translatedMinValue) + translatedMinValue;
    }

    double progressValue = uploadProgress(sentBytes.toDouble(), 0, totalBytes.toDouble(), 0, 1);
    progressValue = progressValue.clamp(0.0, 1.0);

    if (progressValue != _progressPercentValue) {
      setState(() {
        _progressPercentValue = progressValue;
      });
    }
  }

  void _setState(String name) {
    if (name == "") {
      setState(() {
        _fileName = name;
        _hasBeenPressed = false;
      });
    } else {
      setState(() {
        _fileName = name;
        _hasBeenPressed = true;
        _setUploadProgress(0, 0);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _setUploadProgress(0, 0);

    shareFile(List<SharedFile> value) async {
      if (shareBox.isNotEmpty) {
        if (value.isNotEmpty) {
          List<String> urls = [];

          for (int i = 0; i < value.length; i++) {
            final file = File(value[i].value ?? "");
            _setState(AppLocalizations.of(context)!.uploadingFile(
                i + 1, file.path.split("/").last, value.length
            ));

            File uploadFile;
            if (value[i].type == SharedMediaType.TEXT) {
              final tempDir = await getTemporaryDirectory();
              final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
              uploadFile = File('${tempDir.path}/shared_text_$timestamp.txt');
              await uploadFile.writeAsString(value[i].value ?? "");
            } else {
              uploadFile = file;
            }

            final String? returnedUrl = await FileService.fileUploadMultiPart(
              file: uploadFile,
              setOnUploadProgress: _setUploadProgress,
              context: context,
            );

            if (value[i].type == SharedMediaType.TEXT && await uploadFile.exists()) {
              await uploadFile.delete();
            }

            if (returnedUrl != null) {
              urls.add(returnedUrl);
            }
          }

          setState(() {
            _uploadedUrls.addAll(urls);
          });
          _setState("");
        }
      } else {
        SchedulerBinding.instance.addPostFrameCallback((_) => showAlert(context, AppLocalizations.of(context)!.no_custom_uploaders,  AppLocalizations.of(context)!.before_you_can_upload_files));
      }
      // clear the data from the sharing intent
      FlutterSharingIntent.instance.reset();
    }

    // For sharing files coming from outside the app while the app is open
    FlutterSharingIntent.instance.getMediaStream().listen((List<SharedFile> value) {
      setState(() async {
        if (!_hasBeenPressed) {
          shareFile(value);
        }
      });
    }, onError: (err) {
      print("getIntentDataStream error: $err");
    });

    //For sharing images coming from outside the app while the app is closed
    FlutterSharingIntent.instance.getInitialSharing().then((List<SharedFile> value) {
      setState(() {
        if (!_hasBeenPressed) {
          shareFile(value);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.custom_uploader),
        actions: [
          IconButton(onPressed: () {
            Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => Uploaders(title: AppLocalizations.of(context)!.custom_uploader))
            );
          },
          icon: const Icon(Icons.settings)
          ),
          PopupMenuButton(itemBuilder: (context) {
            return [
              PopupMenuItem<int>(
                  value: 0,
                  child:  Row(
                    children: [
                      const Icon(Icons.code),
                      const SizedBox(width: 8),
                      Text(AppLocalizations.of(context)!.github),
                    ],
                  )
              ),
              PopupMenuItem<int>(
                  value: 1,
                  child: Row(
                    children: [
                      Icon(Icons.favorite),
                      SizedBox(width: 8),
                      Text(AppLocalizations.of(context)!.donate),
                    ],
                  )
              ),
              PopupMenuItem<int>(
                  value: 2,
                  child: Row(
                    children: [
                      Icon(Icons.help),
                      SizedBox(width: 8),
                      Text(AppLocalizations.of(context)!.help),
                    ],
                  )
              )
            ];
          },
            onSelected: (value) {
              if (value == 0) {
                launchUrl(Uri.parse("https://github.com/SrS2225a/custom_uploader"));
              }
              if(value == 1) {
                launchUrl(Uri.parse("https://liberapay.com/Eris"));
              }
              if(value == 2) {
                launchUrl(Uri.parse("https://github.com/SrS2225a/custom_uploader/wiki"));
              }
            },)
        ],
      ),
      body: Column(
        children: [
          Spacer(flex: 1), // Push content down just a bit
          Align(
            alignment: Alignment.topCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularPercentIndicator(
                  radius: 120.0,
                  percent: _progressPercentValue,
                  center: ElevatedButton(
                    onPressed: () async {
                      if (shareBox.isNotEmpty && !_hasBeenPressed) {
                        _uploadedUrls.clear();
                        final filePicker = await FilePicker.platform.pickFiles(allowMultiple: true);
                        if (filePicker == null || filePicker.files.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(AppLocalizations.of(context)!.no_file_selected)),
                          );
                          return;
                        }

                        final files = filePicker.files.map((file) => File(file.path!)).toList();
                        for (int i = 0; i < files.length; i++) {
                          final file = files[i];
                          _setState(AppLocalizations.of(context)!.uploadingFile(
                              i + 1,  file.path.split("/").last, files.length
                          ));

                          final url = await FileService.fileUploadMultiPart(
                            file: file,
                            setOnUploadProgress: _setUploadProgress,
                            context: context,
                          );

                          if (url != null) {
                            setState(() {
                              _uploadedUrls.add(url);
                            });
                          }
                        }
                        _setState("");
                      } else if (shareBox.isEmpty) {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text(AppLocalizations.of(context)!.no_custom_uploaders),
                              content: Text(AppLocalizations.of(context)!.before_you_can_upload_files),
                              actions: <Widget>[
                                TextButton(
                                  child: Text(AppLocalizations.of(context)!.ok),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                )
                              ],
                            );
                          },
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _hasBeenPressed ? Colors.blue.withOpacity(0.38) : Colors.blue,
                      minimumSize: const Size(150, 50),
                      textStyle: const TextStyle(fontSize: 20),
                    ),
                    child: _hasBeenPressed
                        ? Text(AppLocalizations.of(context)!.uploading)
                        : Text(AppLocalizations.of(context)!.choose_files),
                  ),
                  progressColor: Colors.green[400],
                ),
                Text(_fileName),
                const SizedBox(height: 12),
              ],
            ),
          ),

          Expanded(
            flex: 7,

              child: ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: _uploadedUrls.length,
                itemBuilder: (context, index) {
                  final url = _uploadedUrls[index];
                  final isEmptyUrl = url.trim().isEmpty;

                  return Card(
                    child: Padding(
                      // unfortunately, I had to do a a bit of trickery with padding to get the buttons lined up correctly. Too bad!
                      padding: const EdgeInsets.only(left: 12, top: 6, bottom: 6, right: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              isEmptyUrl
                                  ? 'Upload succeeded, but no URL was returned'
                                  : url,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontStyle: isEmptyUrl ? FontStyle.italic : FontStyle.normal,
                                color: isEmptyUrl ? Colors.grey : null,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            style: ButtonStyle(
                              visualDensity: VisualDensity.compact,
                            ),
                            tooltip: isEmptyUrl ? 'No URL to copy' : 'Copy URL',
                            onPressed: isEmptyUrl
                                ? null
                                : () {
                              Clipboard.setData(ClipboardData(text: url));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Copied to clipboard')),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.share, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            style: ButtonStyle(
                              visualDensity: VisualDensity.compact,
                            ),
                            tooltip: isEmptyUrl ? 'No URL to share' : 'Share URL',
                            onPressed: isEmptyUrl
                                ? null
                                : () {
                              final params = share_plus.ShareParams(uri: Uri.tryParse(url));
                              share_plus.SharePlus.instance.share(params);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      )
    );
  }
}