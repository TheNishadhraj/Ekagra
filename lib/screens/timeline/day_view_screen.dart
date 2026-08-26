import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/energy_provider.dart';
import '../../providers/focus_provider.dart';
import '../../providers/mood_provider.dart';
import '../../providers/task_provider.dart';
import '../../utils/countdown_palette.dart';
import '../../widgets/focus_ring.dart';
import '../../widgets/free_time_gap.dart';
import 'estimate_sheet.dart';

class DayViewScreen extends StatefulWidget {
  const DayViewScreen({super.key});

  @override
  State<DayViewScreen> createState() => _DayViewScreenState();
}

class _DayViewScreenState extends State<DayViewScreen> {
  int _selectedDayOffset = 0; // 0 = Today, 1 = Tomorrow, etc.
  bool _showCompleted = false;

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final energyProvider = context.watch<EnergyProvider>();
    final moodProvider = context.watch<MoodProvider>();
    final focusProvider = context.watch<FocusProvider>();

    final tasks = taskProvider.activeIncomplete;
    final completed = taskProvider.completedToday;

    final targetDate = DateTime.now().add(Duration(days: _selectedDayOffset));
    if (targetDate.day == DateTime.now().day) {
      // Keep the screen stable while the day selector remains interactive.
    }

    return Scaffold(
      backgroundColor: EkagraColors.background,
      appBar: AppBar(
        title: const Text('Your Day 📅'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Rolling 7-Day Selector
            SizedBox(
              height: 70,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: EkagraSpacing.md),
                itemCount: 7,
                itemBuilder: (context, index) {
                  final date = DateTime.now().add(Duration(days: index));
                  final isSelected = index == _selectedDayOffset;
                  final dayName = index == 0
                      ? 'Today'
                      : index == 1
                          ? 'Tomorrow'
                          : _getDayAbbrev(date.weekday);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDayOffset = index;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? EkagraColors.primary : EkagraColors.surface,
                        borderRadius: BorderRadius.circular(EkagraRadius.lg),
                        border: Border.all(
                          color: isSelected
                              ? EkagraColors.primary
                              : EkagraColors.primaryLight.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dayName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : EkagraColors.textSecondary,
                            ),
                          ),
                          Text(
                            '${date.day}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? Colors.white : EkagraColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: EkagraSpacing.sm),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: EkagraSpacing.lg),
                children: [
                  // Energy & Mood Summary Card
                  Container(
                    padding: const EdgeInsets.all(EkagraSpacing.lg),
                    decoration: BoxDecoration(
                      color: EkagraColors.surface,
                      borderRadius: BorderRadius.circular(EkagraRadius.lg),
                      border: Border.all(
                        color: EkagraColors.primaryLight.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text('⚡ Energy', style: EkagraTypography.tiny),
                            const SizedBox(height: 2),
                            Text(
                              energyProvider.currentLevel.name.toUpperCase(),
                              style: EkagraTypography.bodyBold.copyWith(
                                color: EkagraColors.primary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: EkagraColors.primaryLight.withValues(alpha: 0.3),
                        ),
                        Column(
                          children: [
                            Text('💛 Mood', style: EkagraTypography.tiny),
                            const SizedBox(height: 2),
                            Text(
                              moodProvider.currentLevel.name.toUpperCase(),
                              style: EkagraTypography.bodyBold.copyWith(
                                color: EkagraColors.primary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: EkagraSpacing.lg),

                  // Collapse/Expand completed tasks toggle
                  if (completed.isNotEmpty) ...[
                    InkWell(
                      onTap: () {
                        setState(() {
                          _showCompleted = !_showCompleted;
                        });
                      },
                      borderRadius: BorderRadius.circular(EkagraRadius.md),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: EkagraSpacing.md,
                          vertical: EkagraSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: EkagraColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(EkagraRadius.md),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${completed.length} done today ✓',
                              style: EkagraTypography.bodyBold.copyWith(
                                color: EkagraColors.success,
                                fontSize: 14,
                              ),
                            ),
                            Icon(
                              _showCompleted
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color: EkagraColors.success,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_showCompleted) ...[
                      const SizedBox(height: EkagraSpacing.sm),
                      ...completed.map((t) => ListTile(
                            leading: const Icon(Icons.check_circle, color: EkagraColors.success),
                            title: Text(
                              t.title,
                              style: const TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: EkagraColors.textSecondary,
                              ),
                            ),
                          )),
                    ],
                    const SizedBox(height: EkagraSpacing.lg),
                  ],

                  // Timeline section header
                  Text(
                    'TIMELINE & FREE TIME GAPS',
                    style: EkagraTypography.tiny.copyWith(
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: EkagraSpacing.sm),

                  if (tasks.isEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(EkagraSpacing.xl),
                      decoration: BoxDecoration(
                        color: EkagraColors.surface,
                        borderRadius: BorderRadius.circular(EkagraRadius.lg),
                      ),
                      child: Column(
                        children: [
                          const Text('🌈', style: TextStyle(fontSize: 32)),
                          const SizedBox(height: EkagraSpacing.sm),
                          Text('No tasks scheduled for this day', style: EkagraTypography.bodyBold),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Free time gap simulation before first task
                    const FreeTimeGap(
                      minutes: 45,
                      suggestion: 'Time for a break or a quick 15-min focus!',
                    ),
                    const SizedBox(height: EkagraSpacing.sm),

                    ...List.generate(tasks.length, (index) {
                      final task = tasks[index];
                      final isFirst = index == 0;
                      return Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(EkagraSpacing.lg),
                            decoration: BoxDecoration(
                              color: isFirst
                                  ? EkagraColors.primary.withValues(alpha: 0.08)
                                  : EkagraColors.surface,
                              borderRadius: BorderRadius.circular(EkagraRadius.lg),
                              border: Border.all(
                                color: isFirst
                                    ? EkagraColors.primary
                                    : EkagraColors.primaryLight.withValues(alpha: 0.3),
                                width: isFirst ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  task.emoji ?? '📅',
                                  style: const TextStyle(fontSize: 24),
                                ),
                                const SizedBox(width: EkagraSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (isFirst)
                                        Text(
                                          'NOW',
                                          style: EkagraTypography.tiny.copyWith(
                                            color: EkagraColors.primary,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      Text(
                                        task.title,
                                        style: EkagraTypography.bodyBold,
                                      ),
                                      Text(
                                        '~${task.estimatedMinutes ?? 15} min',
                                        style: EkagraTypography.caption,
                                      ),
                                    ],
                                  ),
                                ),
                                // WI-2.2: one active task at a time. The
                                // bolt opens the estimate sheet (1 tap) and
                                // Start confirms (2nd tap). While running,
                                // the chip itself shows a shrinking arc in
                                // countdown-palette colours — wall clock,
                                // zero drift by construction.
                                if (focusProvider.currentTask?.id == task.id)
                                  FocusRing(
                                    progress: focusProvider.isIdle
                                        ? 0
                                        : focusProvider.progress,
                                    remaining: focusProvider.remaining,
                                    size: 34,
                                    showTime: false,
                                    color: focusProvider.isIdle
                                        ? EkagraColors.primaryLight
                                        : CountdownPalette
                                              .colorForRemainingFraction(
                                              focusProvider
                                                  .remaining
                                                  .inSeconds /
                                              ((focusProvider
                                                          .session
                                                          ?.plannedMinutes ??
                                                      25) *
                                                  60),
                                            ),
                                  )
                                else
                                  IconButton(
                                    tooltip: 'Make active',
                                    icon: const Icon(
                                      Icons.bolt_rounded,
                                      color: EkagraColors.primary,
                                    ),
                                    onPressed: () =>
                                        EstimateSheet.show(context, task),
                                  ),
                              ],
                            ),
                          ),
                          if (index < tasks.length - 1 && index % 2 == 0) ...[
                            const SizedBox(height: EkagraSpacing.sm),
                            const FreeTimeGap(
                              minutes: 30,
                              suggestion: '30 min buffer gap available',
                            ),
                          ],
                          const SizedBox(height: EkagraSpacing.sm),
                        ],
                      );
                    }),
                  ],
                  const SizedBox(height: EkagraSpacing.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDayAbbrev(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[(weekday - 1) % 7];
  }
}
