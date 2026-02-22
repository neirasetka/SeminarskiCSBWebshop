import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/outfit_ideas_provider.dart';
import '../domain/outfit_idea.dart';

/// Screen for managing outfit inspiration images for a specific bag.
class OutfitIdeaScreen extends ConsumerStatefulWidget {
  const OutfitIdeaScreen({super.key, required this.bagId, this.bagName});

  final int bagId;
  final String? bagName;

  @override
  ConsumerState<OutfitIdeaScreen> createState() => _OutfitIdeaScreenState();
}

class _OutfitIdeaScreenState extends ConsumerState<OutfitIdeaScreen> {
  /// Local list of image paths being edited (before save).
  List<String> _imagePaths = <String>[];
  bool _hasChanges = false;
  bool _isLoading = false;

  /// Tracks whether we've initialized _imagePaths from the provider.
  /// This prevents overwriting user's local edits after initial load.
  bool _isInitializedFromProvider = false;

  /// Syncs _imagePaths from provider data when appropriate.
  /// Only syncs if we haven't initialized yet and user hasn't made local changes.
  /// [providerHasLoaded] indicates whether the async provider has finished loading.
  void _syncFromProvider(OutfitIdea? existingIdea, {required bool providerHasLoaded}) {
    if (_isInitializedFromProvider || _hasChanges) {
      return;
    }

    if (!providerHasLoaded) {
      // Provider is still loading, wait for it
      return;
    }

    // Provider has loaded - mark as initialized regardless of whether there's data
    _isInitializedFromProvider = true;

    if (existingIdea != null && existingIdea.imagePaths.isNotEmpty) {
      // Use addPostFrameCallback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _imagePaths = List<String>.from(existingIdea.imagePaths);
          });
        }
      });
    }
  }

  Future<void> _pickImages() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final List<String> newPaths = result.files
            .where((PlatformFile f) => f.path != null)
            .map((PlatformFile f) => f.path!)
            .toList();

        if (newPaths.isNotEmpty) {
          setState(() {
            _imagePaths.addAll(newPaths);
            _hasChanges = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Greška pri odabiru slika: $e')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imagePaths.removeAt(index);
      _hasChanges = true;
    });
  }

  Future<void> _saveOutfitIdea() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final OutfitIdea idea = OutfitIdea(
        bagId: widget.bagId,
        imagePaths: _imagePaths,
      );
      await ref.read(outfitIdeasProvider.notifier).saveOutfitIdea(idea);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Outfit ideja sačuvana!')),
        );
        setState(() {
          _hasChanges = false;
        });
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Greška pri čuvanju: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Nesačuvane promjene'),
        content: const Text('Imate nesačuvane promjene. Želite li napustiti bez čuvanja?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Ostani'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Napusti'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    // Watch the provider to react to async data loading and external changes
    final AsyncValue<Map<int, OutfitIdea>> ideasAsync = ref.watch(outfitIdeasProvider);
    final OutfitIdea? existingIdea = ref.watch(outfitIdeaForBagProvider(widget.bagId));

    // Check if the provider has finished loading (has data, not loading)
    final bool providerHasLoaded = ideasAsync.hasValue;

    // Sync from provider when data loads (only if not already initialized and no local changes)
    _syncFromProvider(existingIdea, providerHasLoaded: providerHasLoaded);

    // Show loading indicator while provider is loading for the first time
    final bool isProviderLoading = ideasAsync.isLoading && !_isInitializedFromProvider;

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        final bool shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Nazad',
            onPressed: () async {
              if (_hasChanges) {
                final bool shouldPop = await _onWillPop();
                if (shouldPop && context.mounted) {
                  Navigator.of(context).pop();
                }
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
          title: const Text('Outfit ideja'),
          actions: <Widget>[
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              TextButton(
                onPressed: _imagePaths.isEmpty ? null : _saveOutfitIdea,
                child: const Text('Save'),
              ),
          ],
        ),
        body: _buildBody(isProviderLoading: isProviderLoading),
        floatingActionButton: FloatingActionButton(
          onPressed: _pickImages,
          tooltip: 'Dodaj slike',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildBody({required bool isProviderLoading}) {
    // Show loading indicator while waiting for provider to load initial data
    if (isProviderLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_imagePaths.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.image_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Nema slika za inspiraciju',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Dodajte slike pritiskom na + dugme',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: _imagePaths.length,
      itemBuilder: (BuildContext context, int index) {
        return _ImageCard(
          imagePath: _imagePaths[index],
          onRemove: () => _removeImage(index),
          onTap: () => _showImagePreview(index),
        );
      },
    );
  }

  void _showImagePreview(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) => Dialog(
        child: Stack(
          children: <Widget>[
            InteractiveViewer(
              child: Image.file(
                File(_imagePaths[index]),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: Icon(Icons.broken_image, size: 48),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageCard extends StatelessWidget {
  const _ImageCard({
    required this.imagePath,
    required this.onRemove,
    required this.onTap,
  });

  final String imagePath;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          GestureDetector(
            onTap: onTap,
            child: Image.file(
              File(imagePath),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey.shade200,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(Icons.broken_image, size: 32),
                      SizedBox(height: 4),
                      Text(
                        'Slika nije dostupna',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.7),
              ),
              onPressed: onRemove,
              tooltip: 'Ukloni sliku',
            ),
          ),
        ],
      ),
    );
  }
}
