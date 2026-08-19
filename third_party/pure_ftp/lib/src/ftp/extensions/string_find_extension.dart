extension StringFindExtension on String {
  String find(String start, String end) {
    final startIndex = indexOf(start);
    final endIndex = lastIndexOf(end);
    if (startIndex == endIndex) {
      return this;
    }
    try {
      return substring(startIndex + start.length, endIndex);
    } on Exception {
      return this;
    }
  }
}
