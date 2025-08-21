import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/file_service.dart';

final fileServiceProvider = Provider<FileService>((ref) => const FileService());

class ViewerPage extends ConsumerStatefulWidget {
  const ViewerPage({super.key, required this.path});

  final String path;

  @override
  ConsumerState<ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends ConsumerState<ViewerPage> {
  late Future<String> _futureContent;

  @override
  void initState() {
    super.initState();
    _futureContent = ref.read(fileServiceProvider).readFileAsString(widget.path, maxBytes: 512 * 1024);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.path.split('/').last)),
      body: FutureBuilder<String>(
        future: _futureContent,
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final String content = snapshot.data ?? '';
          return Scrollbar(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                content.isEmpty ? '[Empty file]' : content,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
            ),
          );
        },
      ),
    );
  }
}