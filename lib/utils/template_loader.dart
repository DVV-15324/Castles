import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;

class TemplateLoader {
  TemplateLoader._(this._root);

  final String _root;


  factory TemplateLoader() {
    final candidates = <String>[];

    // 1. Resolve package:castles -> .../lib/main.dart
    try {
      final uri = Isolate.resolvePackageUriSync(
        Uri.parse('package:castles/main.dart'),
      );
      if (uri != null) {
        final libDir = p.dirname(uri.toFilePath());
        candidates.add(p.join(libDir, 'templates'));
      }
    } catch (_) {}

    // 2. Walk up từ Platform.script (chạy từ source)
    var dir = p.dirname(Platform.script.toFilePath());
    for (var i = 0; i < 6; i++) {
      candidates.add(p.join(dir, 'templates'));
      candidates.add(p.join(dir, 'lib', 'templates'));
      dir = p.dirname(dir);
    }

    // 3. Fallback: quét pub cache git (phòng trường hợp resolve fail)
    final pubCache = Platform.environment['PUB_CACHE'] ??
        (Platform.isWindows
            ? p.join(
                Platform.environment['LOCALAPPDATA'] ?? '',
                'Pub',
                'Cache',
              )
            : p.join(Platform.environment['HOME'] ?? '', '.pub-cache'));
    final gitDir = Directory(p.join(pubCache, 'git'));
    if (gitDir.existsSync()) {
      for (final e in gitDir.listSync()) {
        if (e is Directory && p.basename(e.path).toLowerCase().contains('castles')) {
          candidates.add(p.join(e.path, 'lib', 'templates'));
        }
      }
    }

    for (final c in candidates) {
      if (Directory(c).existsSync()) {
        return TemplateLoader._(c);
      }
    }

    throw 'Could not find templates/ directory. Tried:\n'
        '${candidates.map((c) => '  $c').join('\n')}\n\n'
        'Castles must be run with:\n'
        '  dart run path/to/castles/lib/main.dart <command>';
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