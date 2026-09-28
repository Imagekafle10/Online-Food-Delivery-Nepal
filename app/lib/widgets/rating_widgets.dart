import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/review_service.dart';
import '../theme/app_theme.dart';

const _ratingLabels = [
  '',
  'Poor',
  'Could be better',
  'Good',
  'Great',
  'Excellent!'
];
const _quickTags = [
  'Tasty food',
  'Fast delivery',
  'Good packaging',
  'Value for money',
  'Hot & fresh'
];

/// Footer of a delivered-order card. Shows five tappable stars (tap one to
/// open the rating sheet pre-filled), or the customer's existing rating.
class RateOrderButton extends StatefulWidget {
  final int orderId;
  const RateOrderButton({super.key, required this.orderId});
  @override
  State<RateOrderButton> createState() => _RateOrderButtonState();
}

class _RateOrderButtonState extends State<RateOrderButton> {
  final _svc = ReviewService();
  Review? _existing;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _svc.forOrder(widget.orderId).then((r) {
      if (mounted)
        setState(() {
          _existing = r;
          _loading = false;
        });
    }).catchError((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  Future<void> _rate(int initial) async {
    final done = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) =>
          _RateSheet(orderId: widget.orderId, initialRating: initial),
    );
    if (done == true) {
      final r = await _svc.forOrder(widget.orderId).catchError((_) => null);
      if (mounted) setState(() => _existing = r);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox(height: 8);

    final rated = _existing != null;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: rated
                ? const Color(0xFF2A2A2E)
                : AppColors.gold.withOpacity(0.45)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rated ? 'Thanks for your rating' : 'How was your order?',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
                const SizedBox(height: 2),
                Text(
                  rated
                      ? ((_existing!.comment?.isNotEmpty ?? false)
                          ? _existing!.comment!
                          : _ratingLabels[_existing!.rating])
                      : 'Tap a star to rate',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 1; i <= 5; i++)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: rated ? null : () => _rate(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Icon(
                      rated
                          ? (i <= _existing!.rating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded)
                          : Icons.star_outline_rounded,
                      size: 24,
                      color: AppColors.gold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RateSheet extends StatefulWidget {
  final int orderId;
  final int initialRating;
  const _RateSheet({required this.orderId, this.initialRating = 0});
  @override
  State<_RateSheet> createState() => _RateSheetState();
}

class _RateSheetState extends State<_RateSheet> {
  late int _rating = widget.initialRating;
  final _comment = TextEditingController();
  final Set<String> _tags = {};
  bool _busy = false;

  Future<void> _submit() async {
    if (_rating == 0) return;
    setState(() => _busy = true);
    final text = [
      if (_tags.isNotEmpty) _tags.join(' • '),
      if (_comment.text.trim().isNotEmpty) _comment.text.trim(),
    ].join('\n');
    try {
      await ReviewService()
          .submit(orderId: widget.orderId, rating: _rating, comment: text);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      _fail(e.message);
    } catch (_) {
      _fail('Could not submit rating');
    }
  }

  void _fail(String msg) {
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          20, 10, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.textMuted.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 18),
          const Text('Rate your order',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('Your feedback helps others pick great food',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                GestureDetector(
                  onTap: () => setState(() => _rating = i),
                  child: AnimatedScale(
                    scale: i <= _rating ? 1.12 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        i <= _rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 44,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(
            height: 28,
            child: Center(
              child: Text(
                _ratingLabels[_rating],
                style: const TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w700,
                    fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final t in _quickTags)
                FilterChip(
                  label: Text(t, style: const TextStyle(fontSize: 12.5)),
                  selected: _tags.contains(t),
                  showCheckmark: false,
                  onSelected: (v) =>
                      setState(() => v ? _tags.add(t) : _tags.remove(t)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _comment,
            maxLines: 3,
            maxLength: 400,
            decoration:
                const InputDecoration(hintText: 'Tell us more (optional)'),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: (_rating == 0 || _busy) ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Submit rating',
                      style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet listing a restaurant's reviews.
Future<void> showReviewsSheet(
    BuildContext context, int businessId, String name) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (ctx, scroll) => FutureBuilder<List<Review>>(
        future: ReviewService().forBusiness(businessId),
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.gold));
          }
          final list = snap.data ?? [];
          return ListView(
              controller: scroll,
              padding: const EdgeInsets.all(20),
              children: [
                Text('Reviews • $name',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                if (list.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: Center(
                        child: Text('No reviews yet.',
                            style: TextStyle(color: AppColors.textMuted))),
                  ),
                for (final r in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text(r.userName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            const Spacer(),
                            for (var i = 1; i <= 5; i++)
                              Icon(
                                  i <= r.rating
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  size: 16,
                                  color: AppColors.gold),
                          ]),
                          if (r.comment != null && r.comment!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(r.comment!,
                                  style: const TextStyle(
                                      color: AppColors.textMuted)),
                            ),
                        ]),
                  ),
              ]);
        },
      ),
    ),
  );
}
