import 'dart:io';
import 'package:path/path.dart' as p;

class GitHubRepoInfo {
  final String repoUrl;
  final String branch;
  final String user;
  final String repo;

  GitHubRepoInfo({
    required this.repoUrl,
    required this.branch,
    required this.user,
    required this.repo,
  });

  GitHubRepoInfo copyWith({String? branch}) => GitHubRepoInfo(
        repoUrl: repoUrl,
        branch: branch ?? this.branch,
        user: user,
        repo: repo,
      );
}

class GitHubModuleInfo {
  final String repoUrl;
  final String branch;
  final String path;
  final String moduleName;

  GitHubModuleInfo({
    required this.repoUrl,
    required this.branch,
    required this.path,
    required this.moduleName,
  });

  @override
  String toString() =>
      'GitHubModuleInfo(repo=$repoUrl, branch=$branch, path=$path)';
}

bool isGitHubUrl(String s) =>
    s.startsWith('http://') ||
    s.startsWith('https://') ||
    s.startsWith('git@github.com');


/// Parses a base repo URL (no module path needed).
/// Auto-detects branch if the URL contains /tree/<branch>/...
GitHubRepoInfo parseRepoUrl(String url) {
  if (url.startsWith('git@github.com:')) {
    url = 'https://github.com/' + url.substring('git@github.com:'.length);
  }

  final uri = Uri.parse(url);
  if (!uri.host.contains('github.com')) {
    throw 'Only github.com is supported (got: ${uri.host})';
  }

  final segs = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  if (segs.length < 2) throw 'Invalid GitHub URL: $url';

  final user = segs[0];
  var repo = segs[1];
  if (repo.endsWith('.git')) repo = repo.substring(0, repo.length - 4);

  // If the URL contains /tree/<branch>/... → use that branch
  var branch = 'main';
  if (segs.length >= 4 && segs[2] == 'tree') {
    branch = segs[3];
  }

  return GitHubRepoInfo(
    repoUrl: 'https://github.com/$user/$repo.git',
    branch: branch,
    user: user,
    repo: repo,
  );
}

/// Parses a URL with a module path (either /tree/ or /blob/ form).
GitHubModuleInfo parseGitHubUrl(String url) {
  final repoInfo = parseRepoUrl(url);
  final uri = Uri.parse(url.replaceFirst('git@github.com:', 'https://github.com/'));
  final segs = uri.pathSegments.where((s) => s.isNotEmpty).toList();

  var path = '';
  if (segs.length >= 4 && (segs[2] == 'tree' || segs[2] == 'blob')) {
    path = segs.skip(4).join('/');
    // If it points to a .dart file → use its containing folder
    if (segs[2] == 'blob' || path.endsWith('.dart')) {
      path = p.url.dirname(path);
    }
  } else if (segs.length > 2) {
    path = segs.skip(2).join('/');
  }

  if (path.isEmpty) {
    throw 'URL must point to a module folder.\n'
        'Example: https://github.com/user/repo/tree/main/lib/modules/foo';
  }

  final name = p.url.basename(path);
  return GitHubModuleInfo(
    repoUrl: repoInfo.repoUrl,
    branch: repoInfo.branch,
    path: path,
    moduleName: name,
  );
}

/// Returns (repoInfo with chosen branch, module path).
/// Throws if not found.
Future<({GitHubRepoInfo repo, String path})> findModulePathInRepo(
  GitHubRepoInfo repo,
  String moduleName,
) async {
  final branches = <String>{repo.branch, 'main', 'master'}.toList();

  for (final branch in branches) {
    try {
      final path = await _findModuleInBranch(repo.copyWith(branch: branch), moduleName);
      if (path != null) {
        return (repo: repo.copyWith(branch: branch), path: path);
      }
    } catch (_) {
      // branch doesn't exist → try the next one
    }
  }

  throw 'Could not find module "$moduleName" in ${repo.user}/${repo.repo} '
      'on any branch (${branches.join(', ')}).';
}

Future<String?> _findModuleInBranch(
  GitHubRepoInfo repo,
  String moduleName,
) async {
  final tmp = Directory.systemTemp.createTempSync('castles_find_');
  try {
    await runGit([
      'clone',
      '--depth=1',
      '--filter=blob:none',
      '--sparse',
      '--branch', repo.branch,
      repo.repoUrl,
      tmp.path,
    ]);

    await runGit([
      '-C', tmp.path,
      'sparse-checkout', 'set', '--no-cone',
      'lib/modules/',
    ]);

    final modulesDir = Directory(p.join(tmp.path, 'lib', 'modules'));
    if (!modulesDir.existsSync()) return null;

    for (final entity in modulesDir.listSync()) {
      if (entity is Directory) {
        final name = p.basename(entity.path);
        if (name == moduleName ||
            name == moduleName.replaceAll('_', '-') ||
            name == moduleName.replaceAll('-', '_')) {
          return p.join('lib', 'modules', name);
        }
      }
    }
    return null;
  } finally {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  }
}

/// Lists the modules available in the repo (for friendlier error messages).
Future<String> listModulesInRepo(GitHubRepoInfo repo) async {
  final branches = <String>{repo.branch, 'main', 'master'}.toList();

  for (final branch in branches) {
    final tmp = Directory.systemTemp.createTempSync('castles_list_');
    try {
      await runGit([
        'clone', '--depth=1', '--filter=blob:none', '--sparse',
        '--branch', branch, repo.repoUrl, tmp.path,
      ]);
      await runGit([
        '-C', tmp.path, 'sparse-checkout', 'set', '--no-cone', 'lib/modules/',
      ]);

      final dir = Directory(p.join(tmp.path, 'lib', 'modules'));
      if (!dir.existsSync()) continue;

      final names = dir
          .listSync()
          .whereType<Directory>()
          .map((d) => '  • ${p.basename(d.path)}')
          .toList();

      if (names.isEmpty) return '  (repo has lib/modules but it is empty)';
      return names.join('\n');
    } catch (_) {
      // try another branch
    } finally {
      if (tmp.existsSync()) tmp.deleteSync(recursive: true);
    }
  }
  return '  (could not read the repo or it has no lib/modules)';
}

Future<void> downloadModuleFromGitHub(
  GitHubModuleInfo info,
  String destDir,
) async {
  final tmp = Directory.systemTemp.createTempSync('castles_mod_');
  try {
    await runGit([
      'clone',
      '--depth=1',
      '--filter=blob:none',
      '--sparse',
      '--branch', info.branch,
      info.repoUrl,
      tmp.path,
    ]);

    await runGit([
      '-C', tmp.path,
      'sparse-checkout', 'set',
      info.path,
    ]);

    final src = Directory(p.join(tmp.path, info.path));
    if (!src.existsSync()) {
      throw 'Could not find "${info.path}" in the repo '
          '(${info.repoUrl}, branch ${info.branch})';
    }

    Directory(destDir).createSync(recursive: true);
    _copyDir(src, Directory(destDir));
  } finally {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  }
}

Future<void> runGit(List<String> args) async {
  final r = await Process.run('git', args);
  if (r.exitCode != 0) {
    throw 'Command "git ${args.join(' ')}" failed:\n${r.stderr}';
  }
}

void _copyDir(Directory src, Directory dest) {
  for (final e in src.listSync(recursive: true)) {
    final rel = p.relative(e.path, from: src.path);
    final target = p.join(dest.path, rel);
    if (e is File) {
      File(target).createSync(recursive: true);
      e.copySync(target);
    } else if (e is Directory) {
      Directory(target).createSync(recursive: true);
    }
  }
}