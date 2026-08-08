import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/mood_log_model.dart';
import '../utils/haptic_feedback.dart';

class MoodSelector extends StatelessWidget {
  final MoodLevel? selected;
  final ValueChanged<MoodLevel> onSelected;

  const MoodSelector({
    super.key,
    this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('How are you feeling?', style: EkagraTypography.caption),
        const SizedBox(height: EkagraSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: MoodLevel.values.map((level) {
            final isSelected = selected == level;
            return GestureDetector(
              onTap: () {
                EkagraHaptics.selection();
                onSelected(level);
              },
              child: AnimatedScale(
                scale: isSelected ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: AnimatedOpacity(
                  opacity: selected == null || isSelected ? 1.0 : 0.45,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? EkagraColors.primary.withValues(alpha: 0.12)
                          : EkagraColors.surfaceElevated,
                    ),
                    child: Text(level.emoji, style: const TextStyle(fontSize: 24)),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
