import 'dart:io';

import '../utils/file_utils.dart';
import '../utils/template_loader.dart';

Future<void> cmdInit(List<String> args) async {
  if (!File('pubspec.yaml').existsSync()) {
    throw 'pubspec.yaml not found. Run from the Flutter project root.';
  }
  if (!Directory('lib').existsSync()) {
    throw 'lib/ directory not found.';
  }

  final appName = args.isNotEmpty ? args.first : _detectAppName();
  final tpl = TemplateLoader();
  final vars = {'appName': appName};

  print('Initializing castles for "$appName"\n');

  Directory('lib/modules').createSync(recursive: true);
  print('lib/modules/');

  _write('lib/main.dart',
      tpl.render('template/main.dart.tmpl', vars));
  _write('lib/compose.dart',
      tpl.render('template/routes/compose.dart.tmpl', vars));
  _write('lib/modules.dart',
      tpl.render('template/routes/modules.dart.tmpl', vars));
  _write('lib/routes.dart',
      tpl.render('template/routes/routes.dart.tmpl', vars));

  print('\n Done. Next step: castles add module <name>');
}

String _detectAppName() {
  for (final line in File('pubspec.yaml').readAsLinesSync()) {
    if (line.startsWith('name:')) return line.substring(5).trim();
  }
  return 'app';
}

void _write(String path, String content) {
  final existed = writeFile(path, content);
  print('${existed ? "Overwrote" : "Created"} $path');
}