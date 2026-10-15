/// Naming convention conversion.
library;

String toSnakeCase(String input) {
  final withUnderscore = input
      .replaceAll('-', '_')
      .replaceAll(' ', '_')
      .replaceAllMapped(
        RegExp(r'([A-Z])'),
        (m) => '_${m[1]!.toLowerCase()}',
      );
  return withUnderscore.startsWith('_')
      ? withUnderscore.substring(1)
      : withUnderscore;
}

String toPascalCase(String input) => toSnakeCase(input)
    .split('_')
    .where((w) => w.isNotEmpty)
    .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
    .join();

String toCamelCase(String input) {
  final pascal = toPascalCase(input);
  return pascal.isEmpty
      ? ''
      : '${pascal[0].toLowerCase()}${pascal.substring(1)}';
}

bool isValidModuleName(String name) =>
    RegExp(r'^[a-zA-Z][a-zA-Z0-9_-]*$').hasMatch(name);