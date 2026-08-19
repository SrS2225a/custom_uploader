import 'dart:io';

void main() {
  final modulesDir = Directory(
          '${Directory.current.path}${Platform.pathSeparator}lib${Platform.pathSeparator}src')
      .listSync()
      .whereType<Directory>();
  final exportFiles = modulesDir.map(createExportForModule).whereType<File>();
  final moduleName = Directory.current.path.split(Platform.pathSeparator).last;
  File(''
          '${Directory.current.path}${Platform.pathSeparator}lib${Platform.pathSeparator}'
          '$moduleName.dart')
      .writeAsStringSync(
    'library $moduleName;\n\n'
    '${exportFiles.map((e) => "export "
        "'${getSubPath(Directory('${Directory.current.path}${Platform.pathSeparator}lib'), e.path)}'"
        ";\n").join()}',
  );
}

bool isDirIgnoredForExport(Directory dir) =>
    File('${dir.path}${Platform.pathSeparator}_ignore_export').existsSync();

bool isFileIgnoredForExport(File file) =>
    !file.path.endsWith('.dart') ||
    file.path.contains('.g.') ||
    file.path.contains('.freezed.') ||
    file.readAsStringSync().contains('//_ignore_export');

String getSubPath(FileSystemEntity parent, String path) {
  final parentPath = parent.path;
  if (path.startsWith(parentPath)) {
    return path.substring(parentPath.length + 1).replaceAll(r'\', '/');
  }
  return path.replaceAll(r'\', '/');
}

File? createExportForModule(Directory rootDir) {
  if (isDirIgnoredForExport(rootDir)) {
    return null;
  }
  final exportFile =
      File('${rootDir.path}${Platform.pathSeparator}export.dart');
  if (exportFile.existsSync()) {
    exportFile.deleteSync();
  }

  final files = searchFilesToExport(rootDir)
      .map(
          (e) => isFileIgnoredForExport(e) ? null : getSubPath(rootDir, e.path))
      .whereType<String>();
  exportFile
    ..createSync()
    ..writeAsStringSync(files.map((e) => "export '$e';").join('\n'));
  return exportFile;
}

List<File> searchFilesToExport(Directory rootDir) {
  if (isDirIgnoredForExport(rootDir)) {
    return [];
  }
  final files = [...rootDir.listSync().whereType<File>()];
  rootDir.listSync().whereType<Directory>().forEach((element) {
    files.addAll(searchFilesToExport(element));
  });
  return files;
}
