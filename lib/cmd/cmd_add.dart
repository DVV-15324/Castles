import 'dart:io';

import 'package:path/path.dart' as p;

import '../utils/file_utils.dart';
import '../utils/name_utils.dart';
import '../utils/template_loader.dart';

Future<void> cmdAdd(List<String> args) async {
  if (args.isEmpty || args.first != 'module') {
    throw 'Syntax: castles add module <name>';
  }
  if (args.length < 2) throw 'Missing module name.';

  // Ensure `castles init` has been run first
  if (!File('lib/modules.dart').existsSync() ||
      !File('lib/routes.dart').existsSync()) {
    throw 'Project not initialized. Run `castles init` first.';
  }

  final raw = args[1];
  if (!isValidModuleName(raw)) {
    throw 'Invalid module name: "$raw".';
  }

  final snake = toSnakeCase(raw);
  final className = '${toPascalCase(raw)}Module';
  final moduleDir = p.join('lib', 'modules', snake);

  if (Directory(moduleDir).existsSync()) {
    throw 'Module "$snake" already exists at $moduleDir';
  }

  final tpl = TemplateLoader();
  final vars = {
    'moduleName': snake,
    'snakeName': snake,
    'className': className,
  };

  print('Creating module "$snake"\n');

  for (final sub in ['api', 'components', 'layouts']) {
    Directory(p.join(moduleDir, sub)).createSync(recursive: true);
    print('$moduleDir/$sub/');
  }

  _write(
    p.join(moduleDir, '${snake}_module.dart'),
    tpl.render('module/module.dart.tmpl', vars),
  );
  _write(
    p.join(moduleDir, 'api', 'api.dart'),
    tpl.render('module/api/api.dart.tmpl', vars),
  );
  _write(
    p.join(moduleDir, 'components', 'components.dart'),
    tpl.render('module/components/components.dart.tmpl', vars),
  );
  _write(
    p.join(moduleDir, 'layouts', 'layouts.dart'),
    tpl.render('module/layouts/layouts.dart.tmpl', vars),
  );

  _registerInModules(snake);
  _registerInRoutes(snake, className, moduleDir);

  print('\nDone. Run `flutter run` to view.');
}

void _write(String path, String content) {
  final existed = writeFile(path, content);
  print('${existed ? "Overwrote" : "Created"} $path');
}

void _registerInModules(String snake) {
  const path = 'lib/modules.dart';
  if (insertAfterMarker(
      path, 'const List<String> registeredModules', "  '$snake',")) {
    print('Updated $path');
  } else {
    print('Could not register "$snake" in $path (marker not found).');
  }
}

void _registerInRoutes(String snake, String className, String moduleDir) {
  const path = 'lib/routes.dart';

  final importPath = p.posix.join('modules', snake);
  final importLine = "import '$importPath/${snake}_module.dart';";
  final routeLine = "  '/$snake': (context) => const $className(),";

  var changed = false;
  if (insertAfterMarker(
      path, "import 'package:flutter/material.dart';", importLine)) {
    changed = true;
  }
  if (insertAfterMarker(
      path, 'final Map<String, WidgetBuilder> appRoutes', routeLine)) {
    changed = true;
  }

  if (changed) {
    print('Updated $path');
  } else {
    print('Could not register "$snake" in $path (marker not found).');
  }
}