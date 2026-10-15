library;

const moduleApiTemplate = r'''
/// API layer for the {{moduleName}} module.
library;

// Define API call functions here.
''';

const moduleComponentsTemplate = r'''
/// Widgets used only within the {{moduleName}} module.
library;

import 'package:flutter/material.dart';

// Define widgets here.
''';

const moduleLayoutsTemplate = r'''
/// Layouts used only within the {{moduleName}} module.
library;

import 'package:flutter/material.dart';

// Define layouts here.
''';