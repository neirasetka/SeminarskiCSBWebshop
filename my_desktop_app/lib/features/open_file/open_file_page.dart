import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'recent_files.dart';

class OpenFilePage extends ConsumerStatefulWidget {
  const OpenFilePage({super.key});

  @override
  ConsumerState<OpenFilePage> createState() => _OpenFilePageState();
}

class _OpenFilePageState extends ConsumerState<OpenFilePage> {
  bool _dragging = false;

  Future<void> _openPath(String path) async {
    await ref.read(recentFilesProvider.notifier).add(path);
    if (!mounted) return;
    if (context.mounted) {
      context.go('/viewer', extra: path);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Opened: ${path.split('/').last}')),
      );
    }
  }

  Future<void> _chooseFile() async {
    final XTypeGroup typeGroup = XTypeGroup(
      label: 'All files',
      extensions: <String>['*'],
    );
    final XFile? file = await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
    if (file != null && mounted) {
      await _openPath(file.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> recents = ref.watch(recentFilesProvider);

    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.keyO, control: true): ActivateIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (intent) {
            _chooseFile();
            return null;
          }),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Open File'),
              actions: [
                IconButton(
                  tooltip: 'Clear recent',
                  icon: const Icon(Icons.clear),
                  onPressed: recents.isEmpty
                      ? null
                      : () {
                          ref.read(recentFilesProvider.notifier).clear();
                        },
                ),
              ],
            ),
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: DropTarget(
                    onDragEntered: (_) => setState(() => _dragging = true),
                    onDragExited: (_) => setState(() => _dragging = false),
                    onDragDone: (details) async {
                      if (details.files.isNotEmpty) {
                        await _openPath(details.files.first.path);
                      }
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton.icon(
                          icon: const Icon(Icons.folder_open),
                          label: const Text('Choose a file (Ctrl+O)'),
                          onPressed: _chooseFile,
                        ),
                        const SizedBox(height: 24),
                        if (recents.isNotEmpty) ...[
                          Text('Recent files', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          ...recents.map((String path) => ListTile(
                                leading: const Icon(Icons.description_outlined),
                                title: Text(path.split('/').last),
                                subtitle: Text(path, maxLines: 1, overflow: TextOverflow.ellipsis),
                                onTap: () => _openPath(path),
                              )),
                        ],
                        if (_dragging) ...[
                          const SizedBox(height: 24),
                          Container(
                            height: 120,
                            decoration: BoxDecoration(
                              border: Border.all(color: Theme.of(context).colorScheme.primary),
                              borderRadius: BorderRadius.circular(12),
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                            ),
                            alignment: Alignment.center,
                            child: const Text('Drop file here'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

