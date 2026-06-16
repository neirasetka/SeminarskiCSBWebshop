import 'package:csb_webshop_shared/form_validators.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../auth/application/auth_controller.dart';
import '../data/rates_api.dart';
import '../data/reviews_api.dart';
import '../domain/product_feedback.dart';

final Provider<RatesApi> ratesApiProvider = Provider<RatesApi>((Ref ref) => RatesApi());
final Provider<ReviewsApi> reviewsApiProvider =
    Provider<ReviewsApi>((Ref ref) => ReviewsApi());

/// Ocjenjivanje i recenzije proizvoda (torba ili kaiš).
class ProductFeedbackSection extends ConsumerStatefulWidget {
  const ProductFeedbackSection({
    super.key,
    this.bagId,
    this.beltId,
    this.onSubmitted,
  }) : assert(bagId != null || beltId != null, 'bagId or beltId required');

  final int? bagId;
  final int? beltId;
  final VoidCallback? onSubmitted;

  @override
  ConsumerState<ProductFeedbackSection> createState() =>
      _ProductFeedbackSectionState();
}

class _ProductFeedbackSectionState extends ConsumerState<ProductFeedbackSection> {
  final GlobalKey<FormState> _reviewFormKey = GlobalKey<FormState>();
  final TextEditingController _commentController = TextEditingController();

  List<ProductRate> _rates = <ProductRate>[];
  List<ProductReview> _reviews = <ProductReview>[];
  bool _loading = true;
  String? _error;
  int _selectedRating = 0;
  ProductRate? _userRate;
  bool _submittingRate = false;
  bool _submittingReview = false;

  @override
  void initState() {
    super.initState();
    _loadFeedback();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadFeedback() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final RatesApi ratesApi = ref.read(ratesApiProvider);
      final ReviewsApi reviewsApi = ref.read(reviewsApiProvider);
      final List<ProductRate> rates = await ratesApi.getRatesForProduct(
        bagId: widget.bagId,
        beltId: widget.beltId,
      );
      final List<ProductReview> reviews = await reviewsApi.getReviewsForProduct(
        bagId: widget.bagId,
        beltId: widget.beltId,
      );
      if (!mounted) return;

      final int? userId = ref.read(authControllerProvider).valueOrNull?.userId;
      ProductRate? userRate;
      if (userId != null) {
        for (final ProductRate rate in rates) {
          if (rate.userId == userId) {
            userRate = rate;
            break;
          }
        }
      }

      setState(() {
        _rates = rates;
        _reviews = reviews;
        _userRate = userRate;
        _selectedRating = userRate?.rating ?? 0;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _submitRating() async {
    if (_selectedRating < 1 || _selectedRating > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Odaberite ocjenu od 1 do 5 zvjezdica.')),
      );
      return;
    }

    setState(() => _submittingRate = true);
    try {
      final RatesApi api = ref.read(ratesApiProvider);
      if (_userRate != null) {
        await api.updateRate(
          rateId: _userRate!.id,
          rating: _selectedRating,
          bagId: widget.bagId,
          beltId: widget.beltId,
        );
      } else {
        await api.submitRate(
          rating: _selectedRating,
          bagId: widget.bagId,
          beltId: widget.beltId,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ocjena je sačuvana.')),
      );
      widget.onSubmitted?.call();
      await _loadFeedback();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Greška: $e')),
      );
    } finally {
      if (mounted) setState(() => _submittingRate = false);
    }
  }

  Future<void> _submitReview() async {
    if (!(_reviewFormKey.currentState?.validate() ?? false)) return;

    setState(() => _submittingReview = true);
    try {
      final ReviewsApi api = ref.read(reviewsApiProvider);
      await api.submitReview(
        comment: _commentController.text.trim(),
        bagId: widget.bagId,
        beltId: widget.beltId,
      );
      if (!mounted) return;
      _commentController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Recenzija je poslana na odobrenje. Prikazat će se nakon provjere.',
          ),
        ),
      );
      widget.onSubmitted?.call();
      await _loadFeedback();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Greška: $e')),
      );
    } finally {
      if (mounted) setState(() => _submittingReview = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool isLoggedIn = ref.watch(authControllerProvider).valueOrNull?.userId != null;
    final DateFormat dateFormat = DateFormat('dd.MM.yyyy.');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Divider(color: colorScheme.outlineVariant),
        const SizedBox(height: 24),
        Text(
          'Ocjenjivanje i recenzije',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(minHeight: 2),
          )
        else if (_error != null)
          Text(_error!, style: TextStyle(color: colorScheme.error))
        else ...<Widget>[
          if (_rates.isNotEmpty)
            Text(
              '${_rates.length} ocjena',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          if (isLoggedIn) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              _userRate != null ? 'Vaša ocjena' : 'Ocijenite proizvod',
              style: textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                ...List<Widget>.generate(5, (int index) {
                  final int starValue = index + 1;
                  return IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    onPressed: _submittingRate
                        ? null
                        : () => setState(() => _selectedRating = starValue),
                    icon: Icon(
                      starValue <= _selectedRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                  );
                }),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _submittingRate || _selectedRating == 0
                      ? null
                      : _submitRating,
                  child: _submittingRate
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_userRate != null ? 'Ažuriraj' : 'Pošalji'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Napišite recenziju', style: textTheme.titleSmall),
            const SizedBox(height: 8),
            Form(
              key: _reviewFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  TextFormField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      labelText: 'Komentar',
                      hintText: 'Podijelite svoje iskustvo...',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 4,
                    minLines: 3,
                    inputFormatters: FormValidators.reviewCommentInputFormatters,
                    validator: FormValidators.reviewComment,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: _submittingReview ? null : _submitReview,
                      child: _submittingReview
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Pošalji recenziju'),
                    ),
                  ),
                ],
              ),
            ),
          ] else
            Text(
              'Prijavite se da biste ocijenili proizvod i napisali recenziju.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          const SizedBox(height: 24),
          Text(
            'Recenzije kupaca',
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (_reviews.isEmpty)
            Text(
              'Još nema odobrenih recenzija.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            )
          else
            ..._reviews.map((ProductReview review) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              review.userDisplayName ?? 'Kupac',
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            dateFormat.format(review.date.toLocal()),
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(review.comment),
                    ],
                  ),
                ),
              );
            }),
        ],
      ],
    );
  }
}
