import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/admin_role_provider.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_session.dart';
import '../../belts/application/belts_provider.dart';
import '../../belts/domain/belt.dart';
import '../../profile/application/user_profile_provider.dart';
import '../application/outfit_ideas_provider.dart';
import '../domain/outfit_idea.dart';

/// Screen for managing outfit inspiration images for a specific belt.
class OutfitIdeaBeltScreen extends ConsumerStatefulWidget {
  const OutfitIdeaBeltScreen({super.key, required this.beltId, this.initialBelt});

  final int beltId;
  /// Belt passed from detail screen so the image is shown immediately.
  final Belt? initialBelt;

  @override
  ConsumerState<OutfitIdeaBeltScreen> createState() => _OutfitIdeaBeltScreenState();
}

class _OutfitIdeaBeltScreenState extends ConsumerState<OutfitIdeaBeltScreen> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadData);
  }

  Future<void> _loadData() async {
    ref.read(outfitIdeaProvider.notifier).clear();
    await ref.read(beltDetailProvider.notifier).fetch(widget.beltId);

    final AuthSession? session = ref.read(authControllerProvider).value;
    int? userId = session?.userId;
    if (userId == null && session != null) {
      await ref.read(userProfileProvider.notifier).refreshProfile();
      userId = ref.read(userProfileProvider).value?.id;
    }
    // Load outfit ideas: user's own when logged in, or first available when anonymous
    await ref.read(outfitIdeaProvider.notifier).loadForBelt(widget.beltId, userId);

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
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
    if (userId == null) {
      userId = ref.read(outfitIdeaProvider).outfitIdea?.userId;
    }
    if (userId == null || userId < 1) {
      _showError(
        'Korisnički ID nije dostupan. Pokušajte osvježiti stranicu ili se odjaviti i ponovo prijaviti.',
      );
      return;
    }
    if (widget.beltId < 1) {
      _showError('Neispravan kaiš.');
      return;
    }

    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      OutfitIdeaState currentState = ref.read(outfitIdeaProvider);

      if (currentState.outfitIdea == null) {
        final OutfitIdea? created = await ref
            .read(outfitIdeaProvider.notifier)
            .createOutfitIdeaForBelt(
              beltId: widget.beltId,
              userId: userId,
              title: 'Outfit inspiracija',
            );
        if (created == null) {
          _showError('Greška pri kreiranju outfit ideje');
          return;
        }
      }

      for (final PlatformFile file in result.files) {
        final Uint8List? bytes = file.bytes;
        if (bytes == null || bytes.isEmpty) {
          if (mounted) {
            _showError('Ne mogu učitati sliku: ${file.name}');
          }
          continue;
        }

        final bool success = await ref
            .read(outfitIdeaProvider.notifier)
            .addImage(bytes, caption: file.name);

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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ukloni'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final bool success =
          await ref.read(outfitIdeaProvider.notifier).removeImage(imageId);
      if (!success && mounted) {
        _showError('Greška pri uklanjanju slike');
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  static Uint8List _base64ToBytes(String dataUrl) {
    const String base64Marker = 'base64,';
    final int i = dataUrl.indexOf(base64Marker);
    final String base64 =
        i >= 0 ? dataUrl.substring(i + base64Marker.length) : dataUrl;
    return Uint8List.fromList(base64Decode(base64));
  }

  Widget _buildBeltImagePlaceholder() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(child: Icon(Icons.straighten, size: 48)),
    );
  }

  void _showImagePreview(OutfitIdeaImage image) {
    if (image.imageBytes == null || image.imageBytes!.isEmpty) return;

    showDialog(
      context: context,
      builder: (BuildContext context) => Dialog(
        child: Stack(
          children: <Widget>[
            InteractiveViewer(
              child: Image.memory(
                Uint8List.fromList(image.imageBytes!),
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

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Belt> beltAsync = ref.watch(beltDetailProvider);
    final OutfitIdeaState outfitState = ref.watch(outfitIdeaProvider);
    final bool isAdmin = ref.watch(adminRoleProvider).valueOrNull ?? false;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Nazad',
          onPressed: () => Navigator.of(context).pop(),
        ),
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
          : _buildBody(beltAsync, outfitState, isAdmin),
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
      AsyncValue<Belt> beltAsync, OutfitIdeaState outfitState, bool isAdmin) {
    if (outfitState.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Greška',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(outfitState.error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Pokušaj ponovo'),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 300,
          child: _buildBeltInfo(beltAsync, isAdmin),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: _buildImagesGrid(outfitState, isAdmin),
        ),
      ],
    );
  }

  Widget _buildBeltInfo(AsyncValue<Belt> beltAsync, bool isAdmin) {
    return beltAsync.when(
      data: (Belt belt) {
        final String? imageUrl =
            belt.displayImageUrl ?? widget.initialBelt?.displayImageUrl;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (imageUrl != null && imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: imageUrl.startsWith('data:')
                      ? Image.memory(
                          _base64ToBytes(imageUrl),
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildBeltImagePlaceholder(),
                        )
                      : Image.network(
                          imageUrl,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildBeltImagePlaceholder(),
                        ),
                )
              else
                _buildBeltImagePlaceholder(),
              const SizedBox(height: 16),
              Text(
                belt.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '${belt.price.toStringAsFixed(2)} KM',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (belt.description.isNotEmpty) ...<Widget>[
                const SizedBox(height: 16),
                Text(
                  'Opis',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  belt.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Outfit inspiracija',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                isAdmin
                    ? 'Dodajte slike koje inspirišu za kombiniranje ovog kaiša. '
                        'Kliknite na + dugme da dodate nove slike.'
                    : 'Slike inspiracije za kombiniranje ovog kaiša.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Greška: $error'),
        ),
      ),
    );
  }

  Widget _buildImagesGrid(OutfitIdeaState outfitState, bool isAdmin) {
    final List<OutfitIdeaImage> images =
        outfitState.outfitIdea?.images ?? <OutfitIdeaImage>[];

    if (images.isEmpty) {
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
            if (isAdmin) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                'Dodajte slike pritiskom na + dugme',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 24),
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
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: images.length,
      itemBuilder: (BuildContext context, int index) {
        final OutfitIdeaImage image = images[index];
        return _ImageCard(
          image: image,
          onRemove: isAdmin ? () => _removeImage(image.outfitIdeaImageId) : null,
          onTap: () => _showImagePreview(image),
        );
      },
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
  final VoidCallback? onRemove;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool hasImage =
        image.imageBytes != null && image.imageBytes!.isNotEmpty;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          InkWell(
            onTap: onTap,
            child: hasImage
                ? Image.memory(
                    Uint8List.fromList(image.imageBytes!),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholder(),
                  )
                : _buildPlaceholder(),
          ),
          if (onRemove != null)
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.delete, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.8),
                ),
                onPressed: onRemove,
                tooltip: 'Ukloni sliku',
              ),
            ),
          if (image.caption != null && image.caption!.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.black54,
                child: Text(
                  image.caption!,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.image, size: 32, color: Colors.grey),
            SizedBox(height: 4),
            Text(
              'Slika nije dostupna',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
