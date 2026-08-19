import 'package:pure_ftp/src/extensions/ftp_directory_extensions.dart';
import 'package:pure_ftp/src/file_system/entries/ftp_directory.dart';
import 'package:pure_ftp/src/file_system/entries/ftp_entry.dart';
import 'package:pure_ftp/src/file_system/entries/ftp_link.dart';
import 'package:pure_ftp/src/file_system/ftp_entry_info.dart';
import 'package:pure_ftp/src/file_system/models/list_type.dart';
import 'package:pure_ftp/src/ftp/exceptions/ftp_exception.dart';
import 'package:pure_ftp/src/ftp/extensions/string_find_extension.dart';
import 'package:pure_ftp/src/ftp/ftp_response.dart';

abstract class DataParserUtils {
  /// Parse the Passive Mode Port from the Servers [response]
  ///
  /// port format (|||xxxxx|) if [isIPV6] is true
  ///
  /// format 227 Entering Passive Mode (192,168,8,36,8,75) if [isIPV6] is false
  static int parsePort(
    FtpResponse response, {
    required bool isIPV6,
  }) {
    if (!response.isSuccessful) {
      throw FtpException('Could not parse port from response: $response');
    }
    return isIPV6 ? _parsePortEPSV(response) : _parsePortPASV(response);
  }

  /// Parse the Passive Mode Port from the Servers [response]
  ///
  /// port format (|||xxxxx|)
  static int _parsePortEPSV(FtpResponse response) {
    var message = response.message;
    final iParOpen = message.indexOf('(');
    final iParClose = message.indexOf(')');

    if (iParClose > -1 && iParOpen > -1) {
      message = message.substring(iParOpen + 4, iParClose - 1);
    }
    return int.parse(message);
  }

  /// Parse the Passive Mode Port from the Servers [response]
  ///
  /// format 227 Entering Passive Mode (192,168,8,36,8,75).
  static int _parsePortPASV(FtpResponse response) {
    final sParameters = response.message.find('(', ')');
    final lstParameters = sParameters.split(',');

    final iPort1 = int.parse(lstParameters[lstParameters.length - 2]);
    final iPort2 = int.parse(lstParameters[lstParameters.length - 1]);

    return (iPort1 << 8) + iPort2;
  }

  static final RegExp _regexpLIST = RegExp(r''
      r'^([\-ld])' // Directory flag [1]
      r'([\-rwxs]{9})\s+' // Permissions [2]
      r'(\d+)\s+' // Number of items [3]
      r'(\w+)\s+' // File owner [4]
      r'(\w+)\s+' // File group [5]
      r'(\d+)\s+' // File size in bytes [6]
      r'(\w{3}\s+\d{1,2}\s+(?:\d{1,2}:\d{1,2}|\d{4}))\s+' // date[7]
      r'(.+)$' //entry name[8]
      );

  static final _regexpLISTSii = RegExp(r''
      r'^(.{8}\s+.{7})\s+' //date[1]
      r'(.{0,5})\s+' //type file or dir [2]
      r'(\d{0,24})\s+' //size [3]
      r'(.+)$' //entry name [4]
      );

  /// Parse the [response] from the LIST|MLSD command
  static List<FtpEntry> parseListDirResponse(
      String response, ListType type, FtpDirectory parent) {
    switch (type) {
      case ListType.LIST:
        return _parseLISTResponse(response, parent);
      case ListType.MLSD:
        return _parseMLSDResponse(response, parent);
    }
  }

  static List<FtpEntry> _parseLISTResponse(
      String response, FtpDirectory parent) {
    final result = <FtpEntry>[];
    final lines =
        response.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty);
    for (final line in lines) {
      final MapEntry<String, FtpEntryInfo>? entry =
          _parseListServerEntry(line) ?? _parseSiiServerEntry(line);
      FtpEntry? ftpEntry;
      final name = entry?.value.name ?? '';
      switch (entry?.key) {
        case 'd':
          ftpEntry = parent.getChildDir(name).copyWith(info: entry!.value);
          break;
        case '-':
          ftpEntry = parent.getChildFile(name).copyWith(info: entry!.value);
          break;
        case 'l':
          var linkTarget = '';
          var linkName = name;
          if (entry!.value.name.contains(' -> ')) {
            final split = entry.value.name.split(' -> ');
            linkTarget = split[1];
            linkName = split[0];
          } else {
            linkTarget = '__unknown__${DateTime.now().millisecondsSinceEpoch}';
          }
          ftpEntry = parent.getChildFile(linkName).as<FtpLink>();
          ftpEntry = (ftpEntry as FtpLink).copyWith(
            path: ftpEntry.path,
            linkTarget: linkTarget,
            info: entry.value,
          );
          break;
      }
      if (ftpEntry != null) {
        result.add(ftpEntry);
      }
    }
    return result;
  }

  static MapEntry<String, FtpEntryInfo>? _parseListServerEntry(
    String line,
  ) {
    final match = _regexpLIST.firstMatch(line);
    if (match == null) {
      return null;
    }
    final type = match.group(1)!;
    final permissions = match.group(2)!;
    final numberOfItems = int.parse(match.group(3)!);
    final owner = match.group(4)!;
    final group = match.group(5)!;
    final size = int.parse(match.group(6)!);
    final date = match.group(7)!;
    final name = match.group(8)!;

    final FtpEntryInfo info = FtpEntryInfo(
      name: name,
      size: type == 'd' ? numberOfItems : size,
      owner: owner,
      group: group,
      permissions: permissions,
      modifyTime: date,
    );

    return MapEntry(
      type,
      info,
    );
  }

  static MapEntry<String, FtpEntryInfo>? _parseSiiServerEntry(String line) {
    final match = _regexpLISTSii.firstMatch(line);
    if (match == null) {
      return null;
    }
    final date = match.group(1)!;
    final type = match.group(2)!;
    final size = int.parse(match.group(3)!);
    final name = match.group(4)!;

    final FtpEntryInfo info = FtpEntryInfo(
      name: name,
      size: size,
      modifyTime: date,
    );
    String resultType;
    if (type.toLowerCase().contains('dir')) {
      resultType = 'd';
    } else if (type.trim().isEmpty || type.toLowerCase().contains('file')) {
      resultType = '-';
    } else {
      resultType = 'l';
    }
    return MapEntry(
      resultType,
      info,
    );
  }

  static List<FtpEntry> _parseMLSDResponse(
      String response, FtpDirectory parent) {
    final lines =
        response.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty);
    final result = <FtpEntry>[];
    for (final line in lines) {
      final entry = _parseMLSDServerEntry(line);
      FtpEntry? ftpEntry;
      final name = entry?.value.name ?? '';
      switch (entry?.key) {
        case 'd':
          ftpEntry = parent.getChildDir(name).copyWith(info: entry?.value);
          break;
        case '-':
          ftpEntry = parent.getChildFile(name).copyWith(info: entry?.value);
          break;
        case 'l':
          ftpEntry = parent.getChildFile(name).as<FtpLink>();
          ftpEntry = (ftpEntry as FtpLink).copyWith(
            path: ftpEntry.path,
            linkTarget: '__unknown__${DateTime.now().millisecondsSinceEpoch}',
            info: entry?.value,
          );
          break;
      }
      if (ftpEntry != null) {
        result.add(ftpEntry);
      }
    }
    return result;
  }

  static MapEntry<String, FtpEntryInfo>? _parseMLSDServerEntry(String line) {
    final parts = line.split(';').toList();
    final name = parts.removeLast().trim();
    if (name == '.' || name == '..') {
      return null;
    }
    late String type;
    late int size;
    String? modifyTime;
    String? owner;
    String? group;
    String? permissions;
    int? uid;
    int? gid;
    for (final part in parts) {
      final keyValue = part.split('=');
      final key = keyValue[0].toLowerCase();
      final value = keyValue[1];

      switch (key) {
        case 'type':
          if (value.toLowerCase().contains('dir')) {
            type = 'd';
          } else if (value.toLowerCase().contains('file')) {
            type = '-';
          } else {
            type = 'l';
          }
          break;
        case 'size':
          size = int.parse(value);
          break;
        case 'sizd':
          size = int.parse(value);
          break;
        case 'modify':
          modifyTime = value;
          break;
        case 'perm':
          permissions = value;
          break;
        case 'unix.mode':
          permissions = value;
          break;
        case 'unix.uid':
          uid = int.parse(value);
          break;
        case 'unix.gid':
          gid = int.parse(value);
          break;
        case 'unix.owner':
          owner = value;
          break;
        case 'unix.group':
          group = value;
          break;
      }
    }
    final FtpEntryInfo info = FtpEntryInfo(
      name: name,
      size: size,
      modifyTime: modifyTime,
      owner: owner,
      group: group,
      permissions: permissions,
      uid: uid ?? -1,
      gid: gid ?? -1,
    );
    return MapEntry(
      type,
      info,
    );
  }
}
