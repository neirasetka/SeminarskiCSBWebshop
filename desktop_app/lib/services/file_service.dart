import 'dart:io';
import 'package:file_selector/file_selector.dart';

class FileService {
  Future<String?> pickTextFileAndRead() async {
    const XTypeGroup typeGroup = XTypeGroup(
      label: 'Text',
      extensions: <String>['txt', 'md', 'json'],
    );
    final XFile? file = await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
    if (file == null) return null;
    return file.readAsString();
  }

  Future<File?> saveTextFile(String suggestedName, String contents) async {
    final String? path = await getSavePath(suggestedName: suggestedName);
    if (path == null) return null;
    final File file = File(path);
    await file.writeAsString(contents);
    return file;
  }
}