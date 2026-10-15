import 'dart:io';

/// Writes a file, creating parent directories if needed. Returns `true` if the file already existed.
bool writeFile(String path, String content) {
  final file = File(path);
  final existed = file.existsSync();
  file
    ..createSync(recursive: true)
    ..writeAsStringSync(content);
  return existed;
}

String readFile(String path) {
  final file = File(path);
  return file.existsSync() ? file.readAsStringSync() : '';
}

/// Inserts [line] right after the first line containing [marker].
/// Skips if [line] (trimmed) is already present in the file.
bool insertAfterMarker(String path, String marker, String line) {
  final content = readFile(path);
  if (content.isEmpty) return false;
  if (content.contains(line.trim())) return false;

  final lines = content.split('\n');
  final index = lines.indexWhere((l) => l.contains(marker));
  if (index < 0) return false;

  lines.insert(index + 1, line);
  File(path).writeAsStringSync(lines.join('\n'));
  return true;
}

bool removeLinesContaining(String path, String needle) {
  final content = readFile(path);
  if (content.isEmpty) return false;

  final lines = content.split('\n');
  final filtered = lines.where((l) => !l.contains(needle)).toList();
  if (filtered.length == lines.length) return false;

  File(path).writeAsStringSync(filtered.join('\n'));
  return true;
}

void deleteDirectory(String path) {
  final dir = Directory(path);
  if (dir.existsSync()) dir.deleteSync(recursive: true);
}