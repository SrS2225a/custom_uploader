import 'package:xml/xml.dart';


String? parseResponse(response, String parse, bool statusCode) {
  try {
    final parseAs = parse.split("\$");
    final values = [];
    for (var i = 0; i < parseAs.length; i++) {
      String fromJSON(object, String reference) {
        var dotDeref = reference.split(".");
        for (var i = 0; i < dotDeref.length; i++) {
          var array = dotDeref[i].split("[");
          if (array.length > 1) {
            var arrayIndex = array[1].split("]")[0];
            object = object[array[0]][int.parse(arrayIndex)];
          } else {
            object = object[dotDeref[i]];
          }
        }
        return object;
      }

      String fromXML(XmlDocument? object, String refrence) {
        final xmlDeref = refrence.split("/");
        XmlElement? element;
        for (var i = 0; i < xmlDeref.length; i++) {
          var array = xmlDeref[i].split("[");
          if (array.length > 1) {
            var arrayIndex = array[1].split("]")[0];
            element =
            object!.findAllElements(array[0]).toList()[int.parse(arrayIndex)];
          } else {
            element = object!.findAllElements(xmlDeref[i]).first;
          }
        }
        return element!.text;
      }

      if (parseAs[i].startsWith("json:")) {
        final json = parseAs[i].split("json:")[1];
        values.add(fromJSON(response, json));
      } else if (parseAs[i].startsWith("xml:")) {
        final xml = parseAs[i].split("xml:")[1];
        XmlDocument? xmlDocument = XmlDocument.parse(response);
        values.add(fromXML(xmlDocument, xml));
      } else if (parseAs[i].startsWith("regex:")) {
        final regex = parseAs[i].split("regex:")[1];
        final regexesMatch = regex.split("??");
        final regexesRegex = RegExp(regexesMatch[0]);
        final posAt = regexesMatch.length > 1 ? int.parse(regexesMatch[1]) - 1 : 0;
        final matches = regexesRegex.allMatches(response!).map((m) => m.group(0));
        if (matches.isNotEmpty) {
          values.add(matches.elementAt(posAt));
        }
      } else if (parseAs[i] == "response") {
        values.add(response);
      } else {
        values.add(parseAs[i]);
      }
    }
    // if the user did not specify a parse, try to regex the url from the response body
    if (values.isNotEmpty && statusCode == false) {
      return values.join("");
    } else {
      final regexesRegex = RegExp(r"[-a-zA-Z0-9@:%_\+.~#?&//=]{2,256}\.[a-z]{2,4}\b(\/[-a-zA-Z0-9@:%_\+.~#?&//=]*)?");
      final matches = regexesRegex.allMatches(response!.toString()).map((m) => m.group(0));
      if (matches.isNotEmpty) {
        values.add(matches.elementAt(0));
      }
      return values.join("");
    }
  } catch (e) {
    print(e);
    return "";
  }
}