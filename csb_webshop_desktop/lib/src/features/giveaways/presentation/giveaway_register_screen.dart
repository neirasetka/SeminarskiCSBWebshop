import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/back_confirmation_dialog.dart';
import '../application/giveaways_provider.dart';
import '../data/giveaways_api.dart';
import '../domain/giveaway.dart';

class GiveawayRegisterScreen extends ConsumerStatefulWidget {
  const GiveawayRegisterScreen({super.key, required this.giveawayId});

  final int giveawayId;

  @override
  ConsumerState<GiveawayRegisterScreen> createState() => _GiveawayRegisterScreenState();
}

class _GiveawayRegisterScreenState extends ConsumerState<GiveawayRegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _imeController = TextEditingController();
  final TextEditingController _prezimeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isSubmitting = false;
  bool _isRegistered = false;


  @override
  void dispose() {
    _imeController.dispose();
    _prezimeController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitRegistration() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    try {
      final GiveawaysApi api = ref.read(giveawaysApiProvider);
      final String fullName = '${_imeController.text.trim()} ${_prezimeController.text.trim()}'.trim();
      
      await api.registerParticipant(
        giveawayId: widget.giveawayId,
        name: fullName.isNotEmpty ? fullName : null,
        email: _emailController.text.trim(),
      );

      setState(() {
        _isSubmitting = false;
        _isRegistered = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Uspješno ste se prijavili na giveaway!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška pri prijavi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Giveaway> giveawayAsync = ref.watch(giveawayDetailProvider(widget.giveawayId));
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Size screenSize = MediaQuery.of(context).size;
    final bool isWideScreen = screenSize.width > 900;

    return BackConfirmationWrapper(
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: giveawayAsync.when(
          data: (Giveaway giveaway) {
            final bool isActive = giveaway.isActiveNow && !giveaway.isClosed;
            
            if (_isRegistered) {
              return _buildSuccessView(context, giveaway);
            }
            
            return SafeArea(
              child: isWideScreen
                  ? _buildWideLayout(context, giveaway, isActive)
                  : _buildNarrowLayout(context, giveaway, isActive),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object e, StackTrace st) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                const SizedBox(height: 16),
                Text('Greška pri učitavanju: $e'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Natrag'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context, Giveaway giveaway) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                size: 80,
                color: Colors.green.shade600,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Prijava uspješna!',
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Uspješno ste se prijavili na giveaway "${giveaway.title}"',
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Sretno!',
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 48),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Natrag na giveawaye'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context, Giveaway giveaway, bool isActive) {
    return Row(
      children: <Widget>[
        // Left side - Form
        Expanded(
          flex: 5,
          child: _buildFormSection(context, giveaway, isActive),
        ),
        // Right side - Bag Image
        Expanded(
          flex: 4,
          child: _buildBagImageSection(context),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(BuildContext context, Giveaway giveaway, bool isActive) {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          _buildBagImageSection(context, height: 300),
          _buildFormSection(context, giveaway, isActive),
        ],
      ),
    );
  }

  Widget _buildFormSection(BuildContext context, Giveaway giveaway, bool isActive) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Back button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_back, color: colorScheme.onSurface),
            ),
          ),
          const SizedBox(height: 32),
          
          // Gift icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.card_giftcard,
              size: 40,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 24),
          
          // Main heading
          Text(
            'Do you want to be a winner?',
            style: textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Register here!',
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          
          // Giveaway title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              giveaway.title,
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Završava: ${_formatDate(giveaway.endDate)}',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 40),
          
          // Form
          if (!isActive)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: <Widget>[
                  Icon(Icons.info_outline, color: Colors.orange.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      giveaway.isClosed 
                          ? 'Ovaj giveaway je završen.' 
                          : 'Ovaj giveaway još nije aktivan.',
                      style: TextStyle(color: Colors.orange.shade800),
                    ),
                  ),
                ],
              ),
            )
          else
            _buildRegistrationForm(context),
        ],
      ),
    );
  }

  Widget _buildRegistrationForm(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // First Name field
          Text(
            'Ime',
            style: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _imeController,
            decoration: InputDecoration(
              hintText: 'Unesite vaše ime',
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
              prefixIcon: const Icon(Icons.person_outline),
            ),
            validator: (String? value) {
              if (value == null || value.trim().isEmpty) {
                return 'Ime je obavezno';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          
          // Last Name field
          Text(
            'Prezime',
            style: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _prezimeController,
            decoration: InputDecoration(
              hintText: 'Unesite vaše prezime',
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
              prefixIcon: const Icon(Icons.person_outline),
            ),
            validator: (String? value) {
              if (value == null || value.trim().isEmpty) {
                return 'Prezime je obavezno';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          
          // Email field
          Text(
            'Email',
            style: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'Unesite vaš email',
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
              prefixIcon: const Icon(Icons.email_outlined),
            ),
            validator: (String? value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email je obavezan';
              }
              final String val = value.trim();
              final RegExp re = RegExp(r"^[\w\.-]+@[\w\.-]+\.[a-zA-Z]{2,}$");
              if (!re.hasMatch(val)) {
                return 'Unesite ispravan email';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),
          
          // Submit button
          SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: _isSubmitting ? null : _submitRegistration,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(Icons.send, size: 20),
                        SizedBox(width: 12),
                        Text(
                          'Submit',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Terms hint
          Text(
            'Prijavom prihvatate pravila nagradne igre.',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBagImageSection(BuildContext context, {double? height}) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            colorScheme.primaryContainer.withValues(alpha: 0.5),
            colorScheme.secondaryContainer.withValues(alpha: 0.3),
          ],
        ),
      ),
      child: Stack(
        children: <Widget>[
          // Decorative circles
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.secondary.withValues(alpha: 0.1),
              ),
            ),
          ),
          // Main content - Bag illustration
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.shopping_bag,
                    size: 120,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.star,
                        color: Colors.amber.shade600,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'CSB Premium',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}.';
  }
}
