import 'dart:io';

import 'package:path/path.dart' as p;

import '../utils/file_utils.dart';
import '../utils/name_utils.dart';

Future<void> cmdRemove(List<String> args) async {
  if (args.isEmpty || args.first != 'module') {
    throw 'Syntax: castles remove module <name>';
  }
  if (args.length < 2) throw 'Missing module name.';

  final snake = toSnakeCase(args[1]);
  final moduleDir = p.join('lib', 'modules', snake);

  if (!Directory(moduleDir).existsSync()) {
    throw 'Module "$snake" not found at $moduleDir';
  }

  // Confirmation prompt
  stdout.write('Are you sure you want to remove module "$snake"? (yes/no): ');
  final answer = stdin.readLineSync()?.trim().toLowerCase();

  if (answer != 'yes' && answer != 'y') {
    print('\nCancelled. Module "$snake" was not removed.');
    return;
  }

  print('\nRemoving module "$snake"\n');

  deleteDirectory(moduleDir);
  print('Deleted $moduleDir/');

  const modulesPath = 'lib/modules.dart';
  if (removeLinesContaining(modulesPath, "'$snake'")) {
    print('Updated $modulesPath');
  }

  const routesPath = 'lib/routes.dart';
  var changed = false;
  if (removeLinesContaining(routesPath, '/$snake')) changed = true;
  if (removeLinesContaining(routesPath, '${snake}_module.dart')) {
    changed = true;
  }
  if (changed) print('Updated $routesPath');

  print('\nDone.');
}