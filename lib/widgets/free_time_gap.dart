import 'package:flutter/material.dart';

import '../config/routes.dart';
import '../config/theme.dart';

class FreeTimeGap extends StatelessWidget {
  final int minutes;
  final String suggestion;

  const FreeTimeGap({
    super.key,
    required this.minutes,
    required this.suggestion,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(EkagraSpacing.md),
      decoration: BoxDecoration(
        color: EkagraColors.primaryLight.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(EkagraRadius.lg),
        border: Border.all(
          color: EkagraColors.primary.withValues(alpha: 0.2),
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        children: [
          const Text('💤', style: TextStyle(fontSize: 24)),
          const SizedBox(width: EkagraSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Free Time Gap · $minutes min',
                  style: EkagraTypography.bodyBold.copyWith(
                    fontSize: 14,
                    color: EkagraColors.primary,
                  ),
                ),
                Text(
                  suggestion,
                  style: EkagraTypography.caption.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.brainDump);
            },
            child: const Text('Add task'),
          ),
        ],
      ),
    );
  }
}
