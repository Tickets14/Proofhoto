import 'package:flutter/material.dart';
import '../../data/models/proof_entry.dart';
import 'proof_thumbnail.dart';
import '../../../../core/router/app_router.dart';

/// Scrollable photo grid for a single habit's proof entries.
class ProofTimeline extends StatelessWidget {
  const ProofTimeline({
    super.key,
    required this.entries,
    this.maxItems,
    this.crossAxisCount = 3,
    this.spacing = 4,
  });

  final List<ProofEntry> entries;
  final int? maxItems;
  final int crossAxisCount;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final displayEntries =
        maxItems == null ? entries : entries.take(maxItems!).toList();

    if (displayEntries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text('No photos yet'),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: displayEntries.length,
      itemBuilder: (context, i) {
        final entry = displayEntries[i];
        return ProofThumbnail(
          entry: entry,
          size: double.infinity,
          onTap: () => Navigator.of(context)
              .pushNamed(AppRoutes.proofDetail, arguments: entry.id),
        );
      },
    );
  }
}
