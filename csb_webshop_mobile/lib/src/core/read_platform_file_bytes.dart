import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Loads picked file bytes via stream or path so the plugin need not fill
/// [PlatformFile.bytes] in memory ([withReadStream] / path fallback).
Future<Uint8List?> readPlatformFileBytes(PlatformFile file) async {
  if (file.bytes != null && file.bytes!.isNotEmpty) {
    return file.bytes;
  }
  final Stream<List<int>>? stream = file.readStream;
  if (stream != null) {
    final BytesBuilder builder = BytesBuilder(copy: false);
    await for (final List<int> chunk in stream) {
      builder.add(chunk);
    }
    final Uint8List out = builder.takeBytes();
    if (out.isNotEmpty) {
      return out;
    }
  }
  final String? path = file.path;
  if (path != null && path.isNotEmpty) {
    try {
      return await File(path).readAsBytes();
    } on Object {
      return null;
    }
  }
  return null;
}
