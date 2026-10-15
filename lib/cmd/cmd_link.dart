import 'dart:io';

import 'package:path/path.dart' as p;

import '../utils/file_utils.dart';
import '../utils/name_utils.dart';
import '../utils/github_utils.dart';

Future<void> cmdLink(List<String> args) async {
  if (args.isEmpty || args.first != 'module') {
    throw 'Syntax:\n'
        '  castles link module <name>\n'
        '  castles link module <name> <github-repo-url>';
  }
  if (args.length < 2) throw 'Missing module name.';

  // Ensure `castles init` has been run first
  if (!File('lib/modules.dart').existsSync() ||
      !File('lib/routes.dart').existsSync()) {
    throw 'Project not initialized. Run `castles init` first.';
  }

  final moduleInput = args[1];
  String? repoUrl;

  // Optional: castles link module <name> <github-repo-url>
  if (args.length >= 3) {
    if (!isGitHubUrl(args[2])) {
      throw 'Invalid repo URL: "${args[2]}".';
    }
    repoUrl = args[2];
  }

  final snake = toSnakeCase(moduleInput);
  final moduleDir = p.join('lib', 'modules', snake);

  // Need to download from GitHub?
  if (repoUrl != null && !Directory(moduleDir).existsSync()) {
    final repoInfo = parseRepoUrl(repoUrl);

    print('Searching for module "$snake" in ${repoInfo.user}/${repoInfo.repo}...\n');

    late String path;
    late GitHubRepoInfo chosenRepo;
    try {
      final found = await findModulePathInRepo(repoInfo, snake);
      chosenRepo = found.repo;
      path = found.path;
    } catch (e) {
      print('$e\n');
      print('Modules available in the repo:');
      print(await listModulesInRepo(repoInfo));
      rethrow;
    }

    print('Found: $path (branch ${chosenRepo.branch})');
    await downloadModuleFromGitHub(
      GitHubModuleInfo(
        repoUrl: chosenRepo.repoUrl,
        branch: chosenRepo.branch,
        path: path,
        moduleName: snake,
      ),
      moduleDir,
    );
    print('Downloaded to $moduleDir\n');
  }

  // Local linking part
  await _linkLocal(snake);
}

Future<void> _linkLocal(String snake) async {
  final className = '${toPascalCase(snake)}Module';
  final moduleDir = p.join('lib', 'modules', snake);
  final widgetFile = p.join(moduleDir, '${snake}_module.dart');

  if (!File(widgetFile).existsSync()) {
    throw 'Could not find $widgetFile.\n'
        'Create the module first: castles add module $snake';
  }

  print('Linking module "$snake"\n');

  // modules.dart
  const modulesPath = 'lib/modules.dart';
  if (insertAfterMarker(
      modulesPath, 'const List<String> registeredModules', "  '$snake',")) {
    print('Updated $modulesPath');
  } else {
    print('  · $modulesPath already contains "$snake"');
  }

  // routes.dart
  const routesPath = 'lib/routes.dart';
  final importPath = p.posix.join('modules', snake);
  final importLine = "import '$importPath/${snake}_module.dart';";
  final routeLine = "  '/$snake': (context) => const $className(),";

  var changed = false;
  if (insertAfterMarker(
      routesPath, "import 'package:flutter/material.dart';", importLine)) {
    changed = true;
  }
  if (insertAfterMarker(
      routesPath, 'final Map<String, WidgetBuilder> appRoutes', routeLine)) {
    changed = true;
  }
  print(changed
      ? 'Updated $routesPath'
      : '  · $routesPath already contains "$snake"');

  print('\nDone.');
}