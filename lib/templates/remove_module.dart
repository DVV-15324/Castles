/// Templates for the `castles remove module` command.
///
/// Remove only deletes files + cleans up the two registration files,
/// so there are no template strings here.
library;

/// Main widget file name of the module — used to build paths.
String moduleWidgetFileName(String snake) => '${snake}_module.dart';

/// Names of subdirectories inside the module folder.
const moduleSubdirs = <String>['api', 'components', 'layouts'];