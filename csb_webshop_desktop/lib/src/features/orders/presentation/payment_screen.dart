import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../profile/application/user_profile_provider.dart';
import '../application/cart_provider.dart';
import '../domain/order_models.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  
  // Card payment controllers
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();

  bool _isProcessing = false;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await ref.read(userProfileProvider.future);
      if (profile != null && mounted) {
        setState(() {
          _nameController.text = '${profile.firstName} ${profile.lastName}'.trim();
          _emailController.text = profile.email;
        });
      }
    } catch (_) {
      // Ignore errors loading profile
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Molimo popunite sve obavezne podatke'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Start checkout using the cart provider
      await ref.read(cartProvider.notifier).startCheckout(
            currency: 'eur',
            email: _emailController.text.trim(),
          );

      if (mounted) {
        context.go('/checkout/success');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška pri plaćanju: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<OrderModel?> cartAsync = ref.watch(cartProvider);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Nazad',
            onPressed: () => context.pop(),
          ),
          title: const Text('Plaćanje narudžbe'),
          centerTitle: true,
          elevation: 0,
        ),
        body: cartAsync.when(
          data: (OrderModel? order) {
            if (order == null || order.items.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 80,
                      color: colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Vaša korpa je prazna',
                      style: textTheme.titleLarge?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => context.go('/torbice'),
                      icon: const Icon(Icons.shopping_bag),
                      label: const Text('Pregledaj torbice'),
                    ),
                  ],
                ),
              );
            }

            return Row(
              children: <Widget>[
                // Left side - Form
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          // Progress Stepper
                          _buildProgressStepper(colorScheme, textTheme),
                          const SizedBox(height: 32),

                          // Step content
                          if (_currentStep == 0) ...[
                            _buildShippingForm(colorScheme, textTheme),
                          ] else if (_currentStep == 1) ...[
                            _buildPaymentMethodSection(colorScheme, textTheme, order),
                          ] else ...[
                            _buildConfirmationSection(colorScheme, textTheme, order),
                          ],

                          const SizedBox(height: 32),

                          // Navigation buttons
                          _buildNavigationButtons(colorScheme, order),
                        ],
                      ),
                    ),
                  ),
                ),

                // Right side - Order Summary
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      border: Border(
                        left: BorderSide(
                          color: colorScheme.outlineVariant,
                          width: 1,
                        ),
                      ),
                    ),
                    child: _buildOrderSummary(colorScheme, textTheme, order),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object e, StackTrace st) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                const SizedBox(height: 16),
                const Text('Greška pri učitavanju korpe'),
                Text(e.toString(), style: TextStyle(color: colorScheme.error)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.read(cartProvider.notifier).refresh(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Pokušaj ponovno'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressStepper(ColorScheme colorScheme, TextTheme textTheme) {
    final List<Map<String, dynamic>> steps = <Map<String, dynamic>>[
      {'icon': Icons.local_shipping, 'label': 'Dostava'},
      {'icon': Icons.payment, 'label': 'Plaćanje'},
      {'icon': Icons.check_circle, 'label': 'Potvrda'},
    ];

    return Row(
      children: <Widget>[
        for (int i = 0; i < steps.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                color: i <= _currentStep
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
              ),
            ),
          _buildStepIndicator(
            index: i,
            icon: steps[i]['icon'] as IconData,
            label: steps[i]['label'] as String,
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
        ],
      ],
    );
  }

  Widget _buildStepIndicator({
    required int index,
    required IconData icon,
    required String label,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    final bool isActive = index == _currentStep;
    final bool isCompleted = index < _currentStep;

    return GestureDetector(
      onTap: index < _currentStep ? () => setState(() => _currentStep = index) : null,
      child: Column(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive || isCompleted
                  ? colorScheme.primary
                  : colorScheme.surfaceContainerHighest,
              border: Border.all(
                color: isActive || isCompleted
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
                width: 2,
              ),
            ),
            child: Icon(
              isCompleted ? Icons.check : icon,
              color: isActive || isCompleted
                  ? colorScheme.onPrimary
                  : colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: isActive ? colorScheme.primary : colorScheme.outline,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingForm(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Podaci za dostavu',
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Unesite podatke za dostavu vaše narudžbe',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.outline,
          ),
        ),
        const SizedBox(height: 24),

        // Name field
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Ime i prezime *',
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          ),
          validator: (String? value) {
            if (value == null || value.trim().isEmpty) {
              return 'Molimo unesite ime i prezime';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Email field
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'E-mail adresa *',
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          ),
          validator: (String? value) {
            if (value == null || value.trim().isEmpty) {
              return 'Molimo unesite e-mail adresu';
            }
            if (!value.contains('@')) {
              return 'Molimo unesite ispravnu e-mail adresu';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Phone field
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Broj telefona *',
            prefixIcon: const Icon(Icons.phone_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          ),
          validator: (String? value) {
            if (value == null || value.trim().isEmpty) {
              return 'Molimo unesite broj telefona';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Address field
        TextFormField(
          controller: _addressController,
          decoration: InputDecoration(
            labelText: 'Adresa dostave *',
            prefixIcon: const Icon(Icons.home_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          ),
          validator: (String? value) {
            if (value == null || value.trim().isEmpty) {
              return 'Molimo unesite adresu dostave';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // City and Postal Code row
        Row(
          children: <Widget>[
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _cityController,
                decoration: InputDecoration(
                  labelText: 'Grad *',
                  prefixIcon: const Icon(Icons.location_city_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                ),
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Unesite grad';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _postalCodeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Poštanski broj *',
                  prefixIcon: const Icon(Icons.markunread_mailbox_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                ),
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Unesite poštanski broj';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSection(ColorScheme colorScheme, TextTheme textTheme, OrderModel order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Podaci o kartici',
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Unesite podatke vaše kartice za plaćanje',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.outline,
          ),
        ),
        const SizedBox(height: 24),

        // Card Number field
        TextFormField(
          controller: _cardNumberController,
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(16),
            _CardNumberInputFormatter(),
          ],
          decoration: InputDecoration(
            labelText: 'Broj kartice *',
            hintText: '0000 0000 0000 0000',
            prefixIcon: const Icon(Icons.credit_card),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          ),
          validator: (String? value) {
            if (value == null || value.replaceAll(' ', '').length < 16) {
              return 'Molimo unesite ispravan broj kartice (16 cifara)';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Expiry Date and CVV row
        Row(
          children: <Widget>[
            // Expiry Date field
            Expanded(
              child: TextFormField(
                controller: _expiryDateController,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                  _ExpiryDateInputFormatter(),
                ],
                decoration: InputDecoration(
                  labelText: 'Datum isteka *',
                  hintText: 'MM/YY',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                ),
                validator: (String? value) {
                  if (value == null || value.length < 5) {
                    return 'Unesite datum (MM/YY)';
                  }
                  final List<String> parts = value.split('/');
                  if (parts.length != 2) {
                    return 'Neispravan format';
                  }
                  final int? month = int.tryParse(parts[0]);
                  final int? year = int.tryParse(parts[1]);
                  if (month == null || month < 1 || month > 12) {
                    return 'Neispravan mjesec';
                  }
                  if (year == null) {
                    return 'Neispravna godina';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            // CVV field
            Expanded(
              child: TextFormField(
                controller: _cvvController,
                keyboardType: TextInputType.number,
                obscureText: true,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                decoration: InputDecoration(
                  labelText: 'CVV kod *',
                  hintText: '000',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                ),
                validator: (String? value) {
                  if (value == null || value.length < 3) {
                    return 'Unesite CVV (3-4 cifre)';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Price display card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[
                colorScheme.primaryContainer,
                colorScheme.primaryContainer.withValues(alpha: 0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Ukupno za plaćanje',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${order.items.length} ${order.items.length == 1 ? 'proizvod' : 'proizvoda'}',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              Text(
                '${order.amount.toStringAsFixed(2)} KM',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Security info card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.lock_outline,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Sigurno plaćanje',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Vaši podaci su zaštićeni SSL enkripcijom.',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: <Widget>[
                  Image.network(
                    'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5e/Visa_Inc._logo.svg/100px-Visa_Inc._logo.svg.png',
                    height: 20,
                    errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                      return const Icon(Icons.credit_card, size: 20);
                    },
                  ),
                  const SizedBox(width: 8),
                  Image.network(
                    'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2a/Mastercard-logo.svg/100px-Mastercard-logo.svg.png',
                    height: 20,
                    errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                      return const Icon(Icons.credit_card, size: 20);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationSection(
    ColorScheme colorScheme,
    TextTheme textTheme,
    OrderModel order,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Pregled narudžbe',
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Provjerite podatke prije završetka narudžbe',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.outline,
          ),
        ),
        const SizedBox(height: 24),

        // Shipping info card
        _buildInfoCard(
          icon: Icons.local_shipping,
          title: 'Dostava',
          content: <String>[
            _nameController.text,
            _addressController.text,
            '${_postalCodeController.text} ${_cityController.text}',
            _phoneController.text,
            _emailController.text,
          ],
          colorScheme: colorScheme,
          textTheme: textTheme,
        ),
        const SizedBox(height: 16),

        // Payment info card
        _buildInfoCard(
          icon: Icons.payment,
          title: 'Plaćanje',
          content: <String>[
            'Kartica: **** **** **** ${_cardNumberController.text.replaceAll(' ', '').length >= 4 ? _cardNumberController.text.replaceAll(' ', '').substring(_cardNumberController.text.replaceAll(' ', '').length - 4) : '****'}',
            'Datum isteka: ${_expiryDateController.text}',
            'Ukupno: ${order.amount.toStringAsFixed(2)} KM',
          ],
          colorScheme: colorScheme,
          textTheme: textTheme,
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required List<String> content,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...content.where((String s) => s.isNotEmpty).map(
                (String line) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    line,
                    style: textTheme.bodyMedium,
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(ColorScheme colorScheme, OrderModel order) {
    return Row(
      children: <Widget>[
        if (_currentStep > 0)
          OutlinedButton.icon(
            onPressed: _isProcessing
                ? null
                : () => setState(() => _currentStep--),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Nazad'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        const Spacer(),
        if (_currentStep < 2)
          FilledButton.icon(
            onPressed: () {
              if (!_formKey.currentState!.validate()) {
                return;
              }
              setState(() => _currentStep++);
            },
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Nastavi'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          )
        else
          FilledButton.icon(
            onPressed: _isProcessing ? null : _processPayment,
            icon: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.payment),
            label: Text(_isProcessing ? 'Obrada...' : 'Plati ${order.amount.toStringAsFixed(2)} KM'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              backgroundColor: Colors.green,
            ),
          ),
      ],
    );
  }

  Widget _buildOrderSummary(
    ColorScheme colorScheme,
    TextTheme textTheme,
    OrderModel order,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Header
          Row(
            children: <Widget>[
              Icon(Icons.shopping_bag, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Vaša narudžba',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${order.items.length} ${order.items.length == 1 ? 'stavka' : 'stavke'}',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.outline,
            ),
          ),
          const Divider(height: 32),

          // Items list
          ...order.items.map((OrderItemModel item) => _buildOrderItem(
                item: item,
                colorScheme: colorScheme,
                textTheme: textTheme,
              )),

          const Divider(height: 32),

          // Subtotal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('Međuzbir:', style: textTheme.bodyLarge),
              Text(
                '${order.amount.toStringAsFixed(2)} KM',
                style: textTheme.bodyLarge,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Shipping
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('Dostava:', style: textTheme.bodyLarge),
              Text(
                'Besplatno',
                style: textTheme.bodyLarge?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const Divider(height: 32),

          // Total
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'Ukupno:',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${order.amount.toStringAsFixed(2)} KM',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Security badges
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.lock, size: 16, color: colorScheme.outline),
              const SizedBox(width: 4),
              Text(
                'SSL zaštita',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.outline,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.verified_user, size: 16, color: colorScheme.outline),
              const SizedBox(width: 4),
              Text(
                'Stripe plaćanje',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.outline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem({
    required OrderItemModel item,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    final double lineTotal = (item.price * item.quantity) - (item.discount ?? 0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Item image placeholder
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              item.bagId != null ? Icons.shopping_bag : Icons.interests,
              color: colorScheme.outline,
            ),
          ),
          const SizedBox(width: 12),
          // Item details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.name ?? 'Stavka #${item.id}',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Količina: ${item.quantity}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
                if (item.discount != null && item.discount! > 0)
                  Text(
                    'Popust: -${item.discount!.toStringAsFixed(2)} KM',
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.green,
                    ),
                  ),
              ],
            ),
          ),
          // Price
          Text(
            '${lineTotal.toStringAsFixed(2)} KM',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Input formatter for card number field (adds spaces every 4 digits)
class _CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String text = newValue.text.replaceAll(' ', '');
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i + 1) % 4 == 0 && i + 1 != text.length) {
        buffer.write(' ');
      }
    }
    final String formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Input formatter for expiry date field (adds / after month)
class _ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String text = newValue.text.replaceAll('/', '');
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (i == 1 && text.length > 2) {
        buffer.write('/');
      }
    }
    final String formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
