library;

const composeTemplate = r'''
import 'package:flutter/material.dart';

import 'routes.dart';

/// Main entry point of the app.
///
/// This widget uses [appRoutes] to navigate between modules.
class Compose extends StatelessWidget {
  const Compose({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '{{appName}}',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const _Home(),
        ...appRoutes,
      },
    );
  }
}

class _Home extends StatelessWidget {
  const _Home();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('{{appName}}')),
      body: const Center(
        child: Text(
          'No modules yet.\n'
          'Run `castles add module <name>` to get started.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
''';

const modulesTemplate = r'''
/// List of registered modules.
///
/// This file is updated automatically by `castles`. Do not edit manually.
library;

const List<String> registeredModules = <String>[
];
''';

const routesTemplate = r'''
import 'package:flutter/material.dart';

/// Map of route name → builder for all modules.
///
/// This file is updated automatically by `castles`. Do not edit manually.
library;

final Map<String, WidgetBuilder> appRoutes = <String, WidgetBuilder>{
};
''';

const mainTemplate = r'''
import 'package:flutter/material.dart';

import 'compose.dart';

void main() {
  runApp(const Compose());
}
''';