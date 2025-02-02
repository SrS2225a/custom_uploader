import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';

import 'package:custom_uploader/utils/build_favicon.dart';
import 'package:custom_uploader/services/response_logger.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../utils/show_message.dart';



class UploadLogsScreen extends StatefulWidget {
  @override
  _UploadLogsScreenState createState() => _UploadLogsScreenState();
}

class _UploadLogsScreenState extends State<UploadLogsScreen> {
  Future<List<String>>? logData;

  @override
  void initState() {
    super.initState();
    logData = _loadLogs();
  }

  static Future<void> exportLogs({required File file, required String name, required BuildContext context}) async {
    // Method channel to save a file to the media store
    Future<void> saveFileToMediaStore(File file, String name) async {
      const channel = MethodChannel('flutter_media_store');
      await channel.invokeMethod('addItem', {'path': file.path, 'name': name});
    }

    Future<String> getFilePath() async {
      // Use the external storage directory for newer Android versions
      final appDocumentsDirectory = Directory("/storage/emulated/0/Download");
      return '${appDocumentsDirectory.path}/$name';
    }

    Future<String> getMediaStorePath() async {
      // Use the cache directory for apps targeting Android 10 and above
      return '/data/user/0/com.nyx.custom_uploader/cache/$name';
    }

    try {
      // Request permission to write to storage using the permission handler plugin
      PermissionStatus permissionStatus = await Permission.storage.request();
      if (permissionStatus == PermissionStatus.granted || permissionStatus == PermissionStatus.limited) {
        // Write the provided file to storage
        String filePath = await getFilePath();
        File exportFile = file..renameSync(filePath); // Renaming the provided file to the target file path
        // No need for JSON conversion, just copy the file
        await exportFile.copy(filePath);
        showSnackBar(context, "The logs were downloaded successfully");

      } else {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        final sdkVersion = androidInfo.version.sdkInt;

        if (sdkVersion >= 10) {
          // Handle permissions for Android 10 and above
          final filePath = await getMediaStorePath();
          // No need for JSON conversion, just copy the file
          await file.copy(filePath);
          await saveFileToMediaStore(file, name);
          showSnackBar(context, "The logs were downloaded successfully");
        } else {
          // Tell the user that the permission was denied
          showAlert(context, "Failed to export", "The permission to write to storage was denied.");
        }
      }
    } catch (e) {
      // Tell the user why it failed
      print(e);
      showAlert(context, "Failed to export", "Failed to download logs. \n\nError: ${e.toString()}");
    }
  }

  Future<List<String>> _loadLogs() async {
    final file = await Logger.getLogFile();
    if (!await file.exists()) return [];

    final content = await file.readAsString();
    return content.isNotEmpty ? content.split("\n").where((log) => log.isNotEmpty).toList() : [];
  }

  Future<void> _clearLogs() async {
    await Logger.clearLogs();
    setState(() {
      logData = Future.value([]);
    });
  }

  Future<void> _downloadLogs() async {
    final file = await Logger.getLogFile();
    if (await file.exists()) {
      exportLogs(file:file, name: "CustomUploaderLogs_${DateTime.now().toIso8601String()}.log", context: context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No logs available to download.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Custom Uploader"),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _downloadLogs,
            tooltip: "Download Logs",
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _clearLogs,
            tooltip: "Clear Logs",
          ),
        ],
      ),
      body: FutureBuilder<List<String>>(
        future: logData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text("Error loading logs"));
          } else if (snapshot.data == null || snapshot.data!.isEmpty) {
            return const Center(child: Text("No logs available"));
          } else {
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final logEntry = snapshot.data![index];
                final regex = RegExp(r"\[(.*?)\] Endpoint: (.*?), Status: (\d+), Response: (.*)");
                final match = regex.firstMatch(logEntry);

                if (match != null) {
                  final time = match.group(1) ?? "Unknown";
                  final endpoint = match.group(2) ?? "Unknown Endpoint";
                  final status = match.group(3) ?? "N/A";
                  final response = match.group(4) ?? "No response";

                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildFaviconImage(endpoint),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Tooltip(
                                        message: endpoint,
                                        waitDuration: const Duration(milliseconds: 500),
                                        child: Text(
                                          endpoint,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    _buildStatusBadge(status),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  response,
                                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Time: $time",
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  return const SizedBox.shrink();
                }
              },
            );
          }
        },
      ),
    );
  }
}

Widget _buildStatusBadge(String status) {
  Color statusColor = _getStatusColor(status);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: statusColor.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      "Status: $status",
      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
    ),
  );
}

Color _getStatusColor(String status) {
  int statusCode = int.tryParse(status) ?? 0;
  if (statusCode >= 200 && statusCode < 300) {
    return Colors.green;
  } else if (statusCode >= 400 && statusCode < 500) {
    return Colors.orange;
  } else if (statusCode >= 500) {
    return Colors.red;
  }
  return Colors.black;
}