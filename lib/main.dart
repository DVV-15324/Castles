import 'dart:io';

import 'cmd/cmd_add.dart';
import 'cmd/cmd_init.dart';
import 'cmd/cmd_link.dart';
import 'cmd/cmd_remove.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    _usage();
    exit(1);
  }

  final command = args.first;
  final rest = args.skip(1).toList();

  try {
    switch (command) {
      case 'init':
        await cmdInit(rest);
      case 'add':
        await cmdAdd(rest);
      case 'link':
        await cmdLink(rest);
      case 'remove':
        await cmdRemove(rest);
      case '-h':
      case '--help':
        _usage();
      default:
        stderr.writeln('Invalid command: $command\n');
        _usage();
        exit(1);
    }
  } on _UsageException catch (e) {
    stderr.writeln('${e.message}\n');
    _usage();
    exit(1);
  }
}

void _usage() {
  print('''
castles — Flutter module scaffolder

Usage:
  castles init [app-name]          Initialize module structure
  castles add module <name>        Create a new module + register it
  witches link <module> <repo-url> Link module from GitHub repo
  castles remove module <name>     Remove a module from the project

Options:
  -h, --help                     Show help

Examples:
  cd my_flutter_app
  dart run path/to/castles/lib/main.dart init my_app
  dart run path/to/castles/lib/main.dart add module auth
''');
}

/// Thrown when the user types incorrect syntax.
class _UsageException implements Exception {
  _UsageException(this.message);
  final String message;
}