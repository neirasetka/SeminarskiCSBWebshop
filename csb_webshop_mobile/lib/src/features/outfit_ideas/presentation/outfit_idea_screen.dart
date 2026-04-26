import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/admin_role_provider.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_session.dart';
import '../../bags/application/bags_provider.dart';
import '../../bags/domain/bag.dart';
import '../../profile/application/user_profile_provider.dart';
import '../application/outfit_ideas_provider.dart';
import '../domain/outfit_idea.dart';

class OutfitIdeaScreen extends ConsumerStatefulWidget {
  const OutfitIdeaScreen({super.key, required this.bagId, this.bagName});

  final int bagId;
  final String? bagName;

  @override
  ConsumerState<OutfitIdeaScreen> createState() => _OutfitIdeaScreenState();
}

class _OutfitIdeaScreenState extends ConsumerState<OutfitIdeaScreen> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadData);
  }

  Future<void> _loadData() async {
    await ref.read(bagDetailProvider.notifier).fetch(widget.bagId);
    ref.read(outfitIdeaProvider.notifier).clear();
    final AuthSession? session = ref.read(authControllerProvider).value;
    int? userId = session?.userId;
    if (userId == null && session != null) {
      await ref.read(userProfileProvider.notifier).refreshProfile();
      userId = ref.read(userProfileProvider).value?.id;
    }

    await ref.read(outfitIdeaProvider.notifier).loadForBag(widget.bagId, userId);
    if (!mounted) return;
    setState(() => _isInitialized = true);
  }

  Future<void> _pickAndAddImages() async {
    final AuthSession? session = ref.read(authControllerProvider).value;
    if (session == null) {
      _showError('Morate biti prijavljeni');
      return;
    }

    int? userId = session.userId ?? ref.read(userProfileProvider).value?.id;
    if (userId == null) {
      await ref.read(userProfileProvider.notifier).refreshProfile();
      userId = ref.read(userProfileProvider).value?.id;
    }
    userId ??= ref.read(outfitIdeaProvider).outfitIdea?.userId;
    if (userId == null || userId < 1) {
      _showError('Korisnički ID nije dostupan. Pokušajte ponovo.');
      return;
    }
    if (widget.bagId < 1) {
      _showError('Neispravna torbica.');
      return;
    }

    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      OutfitIdeaState state = ref.read(outfitIdeaProvider);
      if (state.outfitIdea == null) {
        final OutfitIdea? created = await ref
            .read(outfitIdeaProvider.notifier)
            .createOutfitIdea(
              bagId: widget.bagId,
              userId: userId,
              title: 'Outfit inspiracija',
            );
        if (created == null) {
          _showError(ref.read(outfitIdeaProvider).error ?? 'Greška pri kreiranju');
          return;
        }
      }

      for (final PlatformFile file in result.files) {
        final Uint8List? bytes = file.bytes;
        if (bytes == null || bytes.isEmpty) {
          _showError('Ne mogu učitati sliku: ${file.name}');
          continue;
        }
        final bool success =
            await ref.read(outfitIdeaProvider.notifier).addImage(bytes, caption: file.name);
        if (!success && mounted) {
          _showError('Greška pri dodavanju slike: ${file.name}');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Slike uspješno dodane!')),
        );
      }
    } catch (e) {
      _showError('Greška pri odabiru slika: $e');
    }
  }

  Future<void> _removeImage(int imageId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Ukloni sliku'),
        content: const Text('Jeste li sigurni da želite ukloniti ovu sliku?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Odustani'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ukloni'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final bool success = await ref.read(outfitIdeaProvider.notifier).removeImage(imageId);
    if (!success && mounted) {
      _showError('Greška pri uklanjanju slike');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  static Uint8List _base64ToBytes(String dataUrl) {
    const String base64Marker = 'base64,';
    final int i = dataUrl.indexOf(base64Marker);
    final String base64 =
        i >= 0 ? dataUrl.substring(i + base64Marker.length) : dataUrl;
    return Uint8List.fromList(base64Decode(base64));
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Bag> bagAsync = ref.watch(bagDetailProvider);
    final OutfitIdeaState outfitState = ref.watch(outfitIdeaProvider);
    final bool isAdmin = ref.watch(adminRoleProvider).valueOrNull ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Outfit ideja'),
        actions: <Widget>[
          if (outfitState.isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(bagAsync, outfitState, isAdmin),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: _pickAndAddImages,
              tooltip: 'Dodaj slike',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildBody(
    AsyncValue<Bag> bagAsync,
    OutfitIdeaState outfitState,
    bool isAdmin,
  ) {
    if (outfitState.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 8),
              Text(outfitState.error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: outfitState.isLoading ? null : _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Pokušaj ponovo'),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Widget bagInfo = _buildBagInfo(bagAsync, isAdmin);
        final Widget images = _buildImagesGrid(outfitState, isAdmin);

        if (constraints.maxWidth < 900) {
          return Column(
            children: <Widget>[
              Expanded(flex: 2, child: bagInfo),
              const Divider(height: 1),
              Expanded(flex: 3, child: images),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(width: 320, child: bagInfo),
            const VerticalDivider(width: 1),
            Expanded(child: images),
          ],
        );
      },
    );
  }

  Widget _buildBagInfo(AsyncValue<Bag> bagAsync, bool isAdmin) {
    return bagAsync.when(
      data: (Bag bag) {
        final String? imageUrl = bag.displayImageUrl;
        final Widget imageWidget = imageUrl != null && imageUrl.isNotEmpty
            ? (imageUrl.startsWith('data:')
                ? Image.memory(
                    _base64ToBytes(imageUrl),
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                  )
                : Image.network(
                    imageUrl,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                  ))
            : Container(
                height: 180,
                color: Colors.grey.shade200,
                child: const Center(child: Icon(Icons.image, size: 48)),
              );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageWidget,
              ),
              const SizedBox(height: 12),
              Text(
                bag.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 6),
              Text('${bag.price.toStringAsFixed(2)} KM'),
              const SizedBox(height: 12),
              Text(
                isAdmin
                    ? 'Kao admin možete dodati slike putem + dugmeta.'
                    : 'Prikaz outfit inspiracije za ovu torbicu.',
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, _) => Center(child: Text('Greška: $error')),
    );
  }

  Widget _buildImagesGrid(OutfitIdeaState outfitState, bool isAdmin) {
    final List<OutfitIdeaImage> images = outfitState.outfitIdea?.images ?? <OutfitIdeaImage>[];
    if (images.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.image_outlined, size: 64),
            const SizedBox(height: 12),
            const Text('Nema slika za inspiraciju'),
            if (isAdmin) ...<Widget>[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _pickAndAddImages,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Dodaj slike'),
              ),
            ],
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: images.length,
      itemBuilder: (BuildContext context, int index) {
        final OutfitIdeaImage image = images[index];
        return _ImageCard(
          image: image,
          onTap: () => _showImagePreview(image),
          onRemove: isAdmin ? () => _removeImage(image.outfitIdeaImageId) : null,
        );
      },
    );
  }

  void _showImagePreview(OutfitIdeaImage image) {
    if (image.imageBytes == null || image.imageBytes!.isEmpty) return;
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        child: Stack(
          children: <Widget>[
            InteractiveViewer(
              child: Image.memory(Uint8List.fromList(image.imageBytes!)),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
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
    required this.image,
    required this.onTap,
    this.onRemove,
  });

  final OutfitIdeaImage image;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final bool hasImage = image.imageBytes != null && image.imageBytes!.isNotEmpty;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          InkWell(
            onTap: onTap,
            child: hasImage
                ? Image.memory(Uint8List.fromList(image.imageBytes!), fit: BoxFit.cover)
                : Container(
                    color: Colors.grey.shade200,
                    child: const Center(child: Icon(Icons.broken_image)),
                  ),
          ),
          if (onRemove != null)
            Positioned(
              top: 6,
              right: 6,
              child: IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red.withValues(alpha: 0.85),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
