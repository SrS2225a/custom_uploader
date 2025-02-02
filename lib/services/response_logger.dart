import 'dart:io';
import 'package:path_provider/path_provider.dart';

class Logger {
  static Future<File> getLogFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/upload_logs');
  }

  static Future<void> clearLogs() async {
    final file = await getLogFile();
    await file.writeAsString(''); // Clear the log file
  }

  static Future<void> logResponse({
    required String endpoint,
    required int? statusCode,
    required String responseBody,
  }) async {
    final file = await getLogFile();
    final logEntry = "[${DateTime.now()}] Endpoint: $endpoint, Status: $statusCode, Response: $responseBody\n";

    await file.writeAsString(logEntry, mode: FileMode.append);
  }
}