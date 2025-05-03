import 'dart:convert';
import 'package:xml/xml.dart';

String? parseResponse(dynamic response, String parse) {
  try {
    final buffer = StringBuffer();

    final expressionRegex = RegExp(r'\$(.*?)\$');
    final matches = expressionRegex.allMatches(parse).toList();

    // Fallback: if no $...$ expressions are present, try to auto-detect a URL
    if (matches.isEmpty) {
      final urlRegex = RegExp(r"((https?|ftp)\:\/\/|)([A-Za-z0-9.-]+\.[A-Za-z]{2,}|(\d{1,3}\.){3}\d{1,3})(:\d+)?(\/[A-Za-z0-9\-\._~%?!$&'()*+=:@]+)+");
      final urlMatches =
      urlRegex
          .allMatches(response.toString())
          .map((m) => m.group(0))
          .toList();
      if (urlMatches.isNotEmpty) {
        return urlMatches.first;
      }
      return "";
    }

    int lastMatchEnd = 0;

    for (final match in matches) {
      buffer.write(parse.substring(lastMatchEnd, match.start));
      final content = match.group(1)!;

      final parts = content.split(":");
      if (parts.length != 2) {
        buffer.write("[Invalid expression: $content]");
        lastMatchEnd = match.end;
        continue;
      }

      final type = parts[0].toLowerCase();
      final path = parts[1];

      switch (type) {
        case "json":
          final jsonData =
          (response is String) ? json.decode(response) : response;
          buffer.write(_extractFromJson(jsonData, path));
          break;

        case "xml":
          final xmlDoc =
          (response is XmlDocument)
              ? response
              : XmlDocument.parse(response.toString());
          buffer.write(_extractFromXml(xmlDoc, path));
          break;

        case "regex":
          final patternParts = path.split("??");
          final pattern = patternParts[0];
          final index =
          patternParts.length > 1 ? int.tryParse(patternParts[1]) ?? 1 : 1;

          final regex = RegExp(pattern);
          final allMatches =
          regex
              .allMatches(response.toString())
              .map((m) => m.group(0))
              .toList();
          if (allMatches.length >= index) {
            buffer.write(allMatches[index - 1]);
          } else {
            buffer.write("[no match]");
          }
          break;

        default:
          buffer.write("[unknown type: $type]");
          break;
      }

      lastMatchEnd = match.end;
    }

    buffer.write(parse.substring(lastMatchEnd));
    return buffer.toString();
  } catch (e) {
    print("Parsing error: $e");
    return "";
  }
}

dynamic _extractFromJson(dynamic object, String path) {
  final segments = path.split(".");
  for (var segment in segments) {
    final match = RegExp(r'([^\[]+)(?:\[(\d+)\])?').firstMatch(segment);
    if (match != null) {
      final key = match.group(1)!;
      final index = match.group(2);

      object = object[key];
      if (index != null && object is List) {
        object = object[int.parse(index)];
      }
    } else {
      return "[invalid path]";
    }
  }
  return object?.toString() ?? "[null]";
}

String _extractFromXml(XmlDocument doc, String path) {
  final segments = path.split("/");
  XmlElement? element = doc.rootElement;

  // Skip the first segment if it matches the root tag name
  int start = segments[0] == element.name.toString() ? 1 : 0;

  for (var i = start; i < segments.length; i++) {
    final match = RegExp(r'([^\[]+)(?:\[(\d+)\])?').firstMatch(segments[i]);
    if (match != null) {
      final tag = match.group(1)!;
      final index = int.tryParse(match.group(2) ?? "0")!;
      final elements = element!.findElements(tag).toList();

      if (elements.length > index) {
        element = elements[index];
      } else {
        return "[missing element]";
      }
    } else {
      return "[invalid XML path]";
    }
  }

  return element?.text ?? "[null]";
}
