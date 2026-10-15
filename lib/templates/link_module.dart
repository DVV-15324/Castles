/// Templates for the `castles link module` command.
///
/// Linking only modifies two existing files (modules.dart, routes.dart),
/// it doesn't generate new files — so there are no template strings here.
///
/// This file is a placeholder to keep the directory structure consistent.
library;

/// Marker for inserting imports into routes.dart.
const routesImportMarker = "import 'package:flutter/material.dart';";

/// Marker for inserting routes into the map.
const routesMapMarker = 'final Map<String, WidgetBuilder> appRoutes';

/// Marker for inserting modules into the list.
const modulesListMarker = 'const List<String> registeredModules';