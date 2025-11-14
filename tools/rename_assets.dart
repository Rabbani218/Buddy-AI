import 'dart:io';

Future<void> main() async {
  await _cleanIconAssets();
  await _renameImageAssets();
}

Future<void> _cleanIconAssets() async {
  final iconsDir = Directory('assets/icons');
  if (!iconsDir.existsSync()) {
    print('SKIP: icons directory not found.');
    return;
  }

  final processedNames = <String>{};
  final iconFiles = iconsDir
      .listSync()
      .whereType<File>()
      .where((file) => file.path.toLowerCase().endsWith('.svg'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in iconFiles) {
    final originalPath = file.path;
    final fileName = _fileNameFromPath(originalPath);
    final cleanName = _deriveCleanName(fileName);
    if (cleanName == null || cleanName.isEmpty) {
      print('SKIPPED: $originalPath (unable to derive clean name)');
      continue;
    }

    final targetPath = _joinPath(iconsDir.path, '$cleanName.svg');

    if (processedNames.contains(cleanName) || (File(targetPath).existsSync() && originalPath != targetPath)) {
      file.deleteSync();
      print('REMOVED DUPLICATE: $originalPath');
      continue;
    }

    processedNames.add(cleanName);

    if (originalPath == targetPath) {
      print('UNCHANGED: $originalPath');
      continue;
    }

    file.renameSync(targetPath);
    print('RENAMED: $originalPath -> $targetPath');
  }
}

Future<void> _renameImageAssets() async {
  final imagesDir = Directory('assets/images');
  if (!imagesDir.existsSync()) {
    print('SKIP: images directory not found.');
    return;
  }

  _renameImageFile(imagesDir, 'Backgrounds.jpg', 'background.jpg');
  _renameImageFile(imagesDir, 'chat bot-cuate.svg', 'empty_state.svg');
}

void _renameImageFile(Directory directory, String from, String to) {
  final sourcePath = _joinPath(directory.path, from);
  final targetPath = _joinPath(directory.path, to);
  final sourceFile = File(sourcePath);
  if (!sourceFile.existsSync()) {
    return;
  }

  final targetFile = File(targetPath);
  if (targetFile.existsSync() && sourceFile.path != targetFile.path) {
    sourceFile.deleteSync();
    print('REMOVED DUPLICATE IMAGE: $sourcePath');
    return;
  }

  sourceFile.renameSync(targetPath);
  print('RENAMED: $sourcePath -> $targetPath');
}

String _fileNameFromPath(String path) {
  final segments = path.split(Platform.pathSeparator);
  return segments.isNotEmpty ? segments.last : path;
}

String? _deriveCleanName(String fileName) {
  if (!fileName.toLowerCase().endsWith('.svg')) {
    return null;
  }

  var baseName = fileName.substring(0, fileName.length - 4);
  baseName = baseName.trim();
  baseName = baseName.replaceAll(RegExp(r'\s*\(\d+\)$'), '');

  var candidate = baseName;
  final idx24dp = candidate.indexOf('_24dp');
  if (idx24dp != -1) {
    candidate = candidate.substring(0, idx24dp);
  } else {
    final match = RegExp(r'_[0-9]').firstMatch(candidate);
    if (match != null) {
      candidate = candidate.substring(0, match.start);
    }
  }

  candidate = _sanitizeName(candidate);
  if (candidate.isEmpty) {
    candidate = _sanitizeName(baseName);
  }

  return candidate;
}
String _sanitizeName(String value) {
  var sanitized = value.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
  sanitized = sanitized.replaceAll(RegExp(r'_+'), '_');
  sanitized = sanitized.replaceAll(RegExp(r'^_+|_+$'), '');
  return sanitized.toLowerCase();
}

String _joinPath(String root, String child) {
  final separator = Platform.pathSeparator;
  if (root.endsWith(separator)) {
    return '$root$child';
  }
  return '$root$separator$child';
}
