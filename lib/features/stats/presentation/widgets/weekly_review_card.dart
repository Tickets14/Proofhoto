import 'package:flutter/material.dart';
import '../../../proof/data/models/proof_entry.dart';
import '../../../proof/presentation/widgets/proof_thumbnail.dart';
import '../../../../core/theme/app_colors.dart';

class WeeklyReviewCard extends StatelessWidget {
  const WeeklyReviewCard({
    super.key,
    required this.completedCount,
    required this.totalScheduled,
    required this.recentEntries,
  });

  final int completedCount;
  final int totalScheduled;
  final List<ProofEntry> recentEntries;

  double get _rate =>
      totalScheduled == 0 ? 0 : completedCount / totalScheduled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📅', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                'This Week',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _rateColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$completedCount / $totalScheduled',
                  style: TextStyle(
                    color: _rateColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          if (recentEntries.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: recentEntries.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, i) => ProofThumbnail(
                  entry: recentEntries[i],
                  size: 72,
                  showDateOverlay: false,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color get _rateColor {
    if (_rate >= 0.8) return AppColors.success;
    if (_rate >= 0.5) return AppColors.warning;
    return AppColors.error;
  }
}
