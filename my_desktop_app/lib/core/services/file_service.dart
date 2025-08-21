import 'dart:io';

class FileService {
  const FileService();

  Future<String> readFileAsString(String path, {int? maxBytes}) async {
    final File file = File(path);
    if (!await file.exists()) {
      throw FileSystemException('File does not exist', path);
    }
    if (maxBytes == null) {
      return file.readAsString();
    }
    final RandomAccessFile raf = await file.open();
    try {
      final int size = await raf.length();
      final int toRead = size < maxBytes ? size : maxBytes;
      await raf.setPosition(0);
      final List<int> bytes = await raf.read(toRead);
      return String.fromCharCodes(bytes);
    } finally {
      await raf.close();
    }
  }
}