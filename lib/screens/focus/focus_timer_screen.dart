import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/task_model.dart';
import '../../providers/focus_provider.dart';
import '../../providers/reward_provider.dart';
import '../../providers/task_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/growth_service.dart';
import '../../services/monetization_service.dart';
import '../../utils/countdown_palette.dart';
import '../../widgets/focus_ring.dart';
import '../../widgets/pro_gate.dart';
import 'ambient_player.dart';

class FocusTimerScreen extends StatefulWidget {
  final TaskModel? task;

  const FocusTimerScreen({super.key, this.task});

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen> {
  int _selectedMinutes = 25;
  AmbientSound _ambient = AmbientSound.rain;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final focus = context.read<FocusProvider>();
      final taskProvider = context.read<TaskProvider>();
      final targetTask = widget.task ?? taskProvider.oneThing;
      if (targetTask != null) {
        focus.setTask(targetTask);
      }
    });
  }

  void _showCantFocusModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: EkagraColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(EkagraRadius.xl)),
        ),
        padding: const EdgeInsets.all(EkagraSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('It\'s okay. Let\'s figure this out.', style: EkagraTypography.h3),
            const SizedBox(height: EkagraSpacing.sm),
            Text(
              'ADHD brains need adjustments. Pick what feels easiest:',
              style: EkagraTypography.caption,
            ),
            const SizedBox(height: EkagraSpacing.md),

            ListTile(
              leading: const Text('🔄', style: TextStyle(fontSize: 22)),
              title: const Text('Switch tasks'),
              subtitle: const Text('Pick another task from your list'),
              onTap: () {
                Navigator.pop(ctx);
                context.read<TaskProvider>().skipOneThing();
              },
            ),
            ListTile(
              leading: const Text('🤝', style: TextStyle(fontSize: 22)),
              title: const Text('Body double with someone'),
              subtitle: const Text('Focus alongside 100+ active users'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, AppRoutes.bodyDouble);
              },
            ),
            ListTile(
              leading: const Text('⏸', style: TextStyle(fontSize: 22)),
              title: const Text('Take a break'),
              subtitle: const Text('Pause timer for a quick 5-min breather'),
              onTap: () {
                Navigator.pop(ctx);
                context.read<FocusProvider>().pauseTimer();
              },
            ),
            ListTile(
              leading: const Text('🍫', style: TextStyle(fontSize: 22)),
              title: const Text('Need a dopamine hit?'),
              subtitle: const Text('Unlock a quick reward to boost momentum'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, AppRoutes.rewardReveal);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final focus = context.watch<FocusProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final currentTask = focus.currentTask ?? widget.task ?? taskProvider.oneThing;

    // Colour transitions at 25% / 10% remaining (WI-2.2, Rule 3): warm
    // amber then warm coral — never red.
    final plannedSeconds =
        (focus.session?.plannedMinutes ?? _selectedMinutes) * 60;
    final ringColor = focus.isIdle
        ? EkagraColors.focusActive
        : CountdownPalette.colorForRemainingFraction(
            plannedSeconds <= 0 ? 0 : focus.remaining.inSeconds / plannedSeconds,
          );

    return Scaffold(
      backgroundColor: EkagraColors.background,
      appBar: AppBar(
        title: const Text('Focus Mode 🎯'),
        actions: [
          IconButton(
            icon: Text(
              _getAmbientEmoji(_ambient),
              style: const TextStyle(fontSize: 22),
            ),
            onPressed: () {
              AmbientPlayerSheet.show(context, _ambient, (s) {
                setState(() => _ambient = s);
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: EkagraSpacing.xl),
          child: Column(
            children: [
              const Spacer(),

              // Central Focus Ring
              FocusRing(
                progress: focus.progress,
                remaining: focus.remaining,
                color: ringColor,
              ),

              const SizedBox(height: EkagraSpacing.xl),

              // Task Title & Micro commitment
              if (currentTask != null) ...[
                Text(
                  currentTask.title,
                  style: EkagraTypography.h2,
                  textAlign: TextAlign.center,
                ),
                if (currentTask.microCommitment != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '"${currentTask.microCommitment}"',
                    style: EkagraTypography.encouragement.copyWith(
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],

              const Spacer(),

              // Duration selector (if idle)
              if (focus.isIdle) ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [5, 15, 25, 45, 60].map((mins) {
                      final isSel = _selectedMinutes == mins;
                      // Spec O1: free tier gets the default 25 only. The 5
                      // minute option is deliberately Pro-gated too — it is
                      // the highest-value duration for a low-capacity day,
                      // which is exactly when someone decides this app is
                      // worth paying for.
                      final locked = !MonetizationService.instance.isPro &&
                          mins != 25;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('$mins'),
                              if (locked) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.lock_outline_rounded,
                                  size: 12,
                                  color: EkagraColors.textTertiary,
                                ),
                              ],
                            ],
                          ),
                          selected: isSel,
                          selectedColor:
                              EkagraColors.primary.withValues(alpha: 0.2),
                          onSelected: (_) async {
                            if (locked) {
                              final unlocked = await ProGate.guard(
                                context,
                                feature: ProFeature.allFocusDurations,
                                trigger: PaywallTrigger.focusDuration,
                              );
                              if (!unlocked) return;
                            }
                            if (!mounted) return;
                            setState(() => _selectedMinutes = mins);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: EkagraSpacing.lg),
              ],

              // Controls
              Row(
                children: [
                  if (focus.isIdle)
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            focus.startTimer(
                              Duration(minutes: _selectedMinutes),
                            );
                            track(Ev.focusSessionStarted, {
                              'duration': _selectedMinutes,
                              'ambient': _ambient.name,
                              'has_task': currentTask != null,
                            });
                            GrowthService.instance.completeStep(
                              ActivationStep.firstFocusStarted,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: EkagraColors.primary,
                          ),
                          child: const Text(
                            'Start Focus ⏱️',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    )
                  else ...[
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            if (focus.isRunning) {
                              focus.pauseTimer();
                            } else {
                              focus.resumeTimer();
                            }
                          },
                          icon: Icon(
                            focus.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          ),
                          label: Text(focus.isRunning ? 'Pause ⏸' : 'Resume ▶'),
                        ),
                      ),
                    ),
                    const SizedBox(width: EkagraSpacing.md),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final elapsed = focus.elapsedSeconds ~/ 60;
                            final rewardProvider = context.read<RewardProvider>();
                            final navigator = Navigator.of(context);
                            focus.completeTimer();
                            if (currentTask != null) {
                              await taskProvider.completeTask(currentTask.id);
                              if (!mounted) return;
                              rewardProvider.recordTaskCompletion(currentTask.id);
                            }
                            if (!mounted) return;
                            navigator.pushReplacementNamed(
                              AppRoutes.focusComplete,
                              arguments: FocusCompleteArgs(
                                minutes: elapsed > 0 ? elapsed : _selectedMinutes,
                                taskTitle: currentTask?.title,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: EkagraColors.success,
                          ),
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('Done! ✅'),
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: EkagraSpacing.md),

              // "Can't focus?" Button
              TextButton(
                onPressed: _showCantFocusModal,
                child: Text(
                  '😵 Can\'t focus? (It\'s okay. Let\'s adjust.)',
                  style: EkagraTypography.caption.copyWith(
                    color: EkagraColors.textSecondary,
                  ),
                ),
              ),

              const SizedBox(height: EkagraSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  String _getAmbientEmoji(AmbientSound sound) {
    switch (sound) {
      case AmbientSound.rain:
        return '🌧️';
      case AmbientSound.lofi:
        return '🎵';
      case AmbientSound.cafe:
        return '☕';
      case AmbientSound.ocean:
        return '🌊';
      case AmbientSound.fireplace:
        return '🔥';
      case AmbientSound.forest:
        return '🌲';
      case AmbientSound.none:
        return '🔇';
    }
  }
}
