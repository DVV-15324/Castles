import 'dart:io';

import 'package:path/path.dart' as p;

class TemplateLoader {
  TemplateLoader._(this._root);

  final String _root;

  /// Auto-detects the templates/ directory based on the location of the running main.dart.
  factory TemplateLoader() {
    final scriptPath = Platform.script.toFilePath();
    final libDir = p.dirname(scriptPath);
    final templatesDir = p.join(libDir, 'templates');

    if (!Directory(templatesDir).existsSync()) {
      throw 'Could not find templates/ directory at:\n  $templatesDir\n\n'
          'Castles must be run with:\n'
          '  dart run path/to/castles/lib/main.dart <command>';
    }
    return TemplateLoader._(templatesDir);
  }

  /// Loads a template by its relative path.
  String load(String relativePath) {
    final path = p.join(_root, relativePath);
    final file = File(path);
    if (!file.existsSync()) {
      throw 'Template not found: $path';
    }
    return file.readAsStringSync();
  }

  /// Loads + replaces `{{key}}` placeholders with the corresponding values.
  String render(String relativePath, Map<String, String> vars) {
    var body = load(relativePath);
    vars.forEach((k, v) {
      body = body.replaceAll('{{$k}}', v);
    });
    return body;
  }
}