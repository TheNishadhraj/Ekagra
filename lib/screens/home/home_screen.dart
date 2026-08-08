import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/task_model.dart';
import '../../providers/energy_provider.dart';
import '../../providers/focus_provider.dart';
import '../../providers/mood_provider.dart';
import '../../providers/reward_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/energy_gauge.dart';
import '../../widgets/mood_selector.dart';
import '../../widgets/task_chip.dart';
import '../task_detail/task_detail_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  bool _showSearch = false;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'Still up? 🌙';
    if (hour < 12) return 'Good morning ☀️';
    if (hour < 17) return 'Good afternoon 🌤️';
    if (hour < 21) return 'Good evening 🌅';
    return 'Night owl mode 🦉';
  }

  double _getDayProgress(int wakeHour, int sleepHour) {
    final now = DateTime.now();
    final wakeMinutes = wakeHour * 60;
    final sleepMinutes = sleepHour * 60;
    final currentMinutes = now.hour * 60 + now.minute;

    if (currentMinutes <= wakeMinutes) return 0.0;
    if (currentMinutes >= sleepMinutes) return 1.0;

    final total = sleepMinutes - wakeMinutes;
    final elapsed = currentMinutes - wakeMinutes;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final energyProvider = context.watch<EnergyProvider>();
    final moodProvider = context.watch<MoodProvider>();
    final focusProvider = context.watch<FocusProvider>();
    final rewardProvider = context.watch<RewardProvider>();

    final user = settings.user;
    final oneThing = taskProvider.oneThing;
    final dayProgress = _getDayProgress(user.wakeHour, user.sleepHour);

    final upcomingTasks = _searchQuery.isEmpty
        ? taskProvider.upcoming
        : taskProvider.tasks
            .where((t) => t.title.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    return Scaffold(
      backgroundColor: EkagraColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Ekagra', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
            const Spacer(),
            IconButton(
              icon: Icon(_showSearch ? Icons.close_rounded : Icons.search_rounded),
              onPressed: () {
                setState(() {
                  _showSearch = !_showSearch;
                  if (!_showSearch) _searchQuery = '';
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings_rounded),
              onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          taskProvider.refreshOneThing(
            energy: energyProvider.currentLevel,
            mood: moodProvider.currentLevel,
          );
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: EkagraSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_showSearch) ...[
                const SizedBox(height: EkagraSpacing.sm),
                TextField(
                  autofocus: true,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search tasks...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: EkagraSpacing.lg,
                      vertical: EkagraSpacing.sm,
                    ),
                    filled: true,
                    fillColor: EkagraColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(EkagraRadius.lg),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: EkagraSpacing.md),
              ],

              // Dynamic Greeting & Encouragement
              Text(
                '${_getGreeting()}, ${user.name}',
                style: EkagraTypography.h2,
              ).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 4),

              Text(
                settings.currentEncouragement,
                style: EkagraTypography.encouragement,
              ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

              const SizedBox(height: EkagraSpacing.lg),

              // Day Progress Bar
              Container(
                padding: const EdgeInsets.all(EkagraSpacing.md),
                decoration: BoxDecoration(
                  color: EkagraColors.surface,
                  borderRadius: BorderRadius.circular(EkagraRadius.lg),
                  border: Border.all(
                    color: EkagraColors.primaryLight.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('DAY PROGRESS', style: EkagraTypography.tiny),
                        Text(
                          '${(dayProgress * 100).toInt()}%',
                          style: EkagraTypography.tiny.copyWith(
                            fontWeight: FontWeight.w700,
                            color: EkagraColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(EkagraRadius.full),
                      child: LinearProgressIndicator(
                        value: dayProgress,
                        minHeight: 8,
                        backgroundColor: EkagraColors.surfaceElevated,
                        color: EkagraColors.primary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: EkagraSpacing.lg),

              // Energy & Mood Check-In Card
              Container(
                padding: const EdgeInsets.all(EkagraSpacing.lg),
                decoration: BoxDecoration(
                  color: EkagraColors.surface,
                  borderRadius: BorderRadius.circular(EkagraRadius.lg),
                  border: Border.all(
                    color: EkagraColors.primaryLight.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How\'s your energy?',
                      style: EkagraTypography.bodyBold.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: EkagraSpacing.sm),
                    EnergyGauge(
                      selected: energyProvider.currentLevel,
                      onSelected: (lvl) {
                        energyProvider.setLevel(lvl);
                        taskProvider.refreshOneThing(
                          energy: lvl,
                          mood: moodProvider.currentLevel,
                        );
                      },
                    ),
                    const Divider(height: EkagraSpacing.xl),
                    Text(
                      'How are you feeling?',
                      style: EkagraTypography.bodyBold.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: EkagraSpacing.sm),
                    MoodSelector(
                      selected: moodProvider.currentLevel,
                      onSelected: (m) {
                        moodProvider.setLevel(m);
                        taskProvider.refreshOneThing(
                          energy: energyProvider.currentLevel,
                          mood: m,
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: EkagraSpacing.xl),

              // YOUR ONE THING CARD
              Row(
                children: [
                  Text(
                    '── YOUR ONE THING ──',
                    style: EkagraTypography.tiny.copyWith(
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: EkagraSpacing.sm),

              _buildOneThingCard(context, oneThing, taskProvider, energyProvider, moodProvider),

              const SizedBox(height: EkagraSpacing.xl),

              // UPCOMING TASKS GRID
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '── UPCOMING ──',
                    style: EkagraTypography.tiny.copyWith(
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.brainDump);
                    },
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add task'),
                  ),
                ],
              ),
              const SizedBox(height: EkagraSpacing.xs),

              if (upcomingTasks.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(EkagraSpacing.xl),
                  decoration: BoxDecoration(
                    color: EkagraColors.surface,
                    borderRadius: BorderRadius.circular(EkagraRadius.lg),
                  ),
                  child: Column(
                    children: [
                      const Text('🌊', style: TextStyle(fontSize: 32)),
                      const SizedBox(height: EkagraSpacing.xs),
                      Text(
                        'Your list is clear! Enjoy the calm',
                        style: EkagraTypography.bodyBold,
                      ),
                      const SizedBox(height: EkagraSpacing.xs),
                      Text(
                        'Or tap + to dump what\'s on your mind.',
                        style: EkagraTypography.caption,
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: upcomingTasks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: EkagraSpacing.sm),
                  itemBuilder: (context, index) {
                    final task = upcomingTasks[index];
                    return TaskChip(
                      task: task,
                      onTap: () {
                        TaskDetailSheet.show(context, task);
                      },
                      onComplete: () {
                        taskProvider.completeTask(task.id);
                        rewardProvider.recordTaskCompletion(task.id);
                      },
                    );
                  },
                ),

              const SizedBox(height: EkagraSpacing.xl),

              // TODAY'S STATS (SHAME-FREE)
              Text(
                '── TODAY\'S STATS ──',
                style: EkagraTypography.tiny.copyWith(
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: EkagraSpacing.sm),

              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      '✅',
                      '${taskProvider.completedToday.length} done',
                      'Tasks completed',
                    ),
                  ),
                  const SizedBox(width: EkagraSpacing.sm),
                  Expanded(
                    child: _statCard(
                      '⏱️',
                      '${focusProvider.todayMinutes} min',
                      'Focus time',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: EkagraSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      '🎁',
                      '${rewardProvider.todayClaimedCount} rewards',
                      'Dopamine earned',
                    ),
                  ),
                  const SizedBox(width: EkagraSpacing.sm),
                  Expanded(
                    child: _statCard(
                      '💛',
                      user.totalActiveDays == 0
                          ? 'Welcome!'
                          : '${user.totalActiveDays} days',
                      'Active days', // Rule 4: Active days, NEVER streak!
                    ),
                  ),
                ],
              ),

              const SizedBox(height: EkagraSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOneThingCard(
    BuildContext context,
    TaskModel? task,
    TaskProvider taskProvider,
    EnergyProvider energyProvider,
    MoodProvider moodProvider,
  ) {
    if (task == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(EkagraSpacing.xl),
        decoration: BoxDecoration(
          color: EkagraColors.surface,
          borderRadius: BorderRadius.circular(EkagraRadius.xl),
          border: Border.all(
            color: EkagraColors.primaryLight.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            const Text('🎯', style: TextStyle(fontSize: 44)),
            const SizedBox(height: EkagraSpacing.sm),
            Text('No active tasks!', style: EkagraTypography.h3),
            const SizedBox(height: 4),
            Text(
              'Dump your ideas to let AI pick ONE thing for you.',
              style: EkagraTypography.caption,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: EkagraSpacing.lg),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.brainDump),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Brain Dump Now 🧠'),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(EkagraSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            EkagraColors.primary.withValues(alpha: 0.08),
            EkagraColors.primaryLight.withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(EkagraRadius.xl),
        border: Border.all(
          color: EkagraColors.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: EkagraColors.primary.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(task.emoji ?? '🎯', style: const TextStyle(fontSize: 28)),
              const SizedBox(width: EkagraSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: EkagraColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(EkagraRadius.full),
                ),
                child: Text(
                  '~${task.estimatedMinutes ?? 15} min · ${task.energyNeeded.name} energy',
                  style: EkagraTypography.tiny.copyWith(
                    color: EkagraColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.more_vert_rounded),
                onPressed: () => TaskDetailSheet.show(context, task),
              ),
            ],
          ),

          const SizedBox(height: EkagraSpacing.sm),

          Text(
            task.title,
            style: EkagraTypography.h2.copyWith(fontSize: 22),
          ),

          if (task.microCommitment != null || task.notes != null) ...[
            const SizedBox(height: EkagraSpacing.xs),
            Text(
              task.microCommitment ?? task.notes ?? '',
              style: EkagraTypography.encouragement.copyWith(
                fontSize: 14,
                color: EkagraColors.textSecondary,
              ),
            ),
          ],

          const SizedBox(height: EkagraSpacing.lg),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.focus,
                      arguments: task,
                    );
                  },
                  icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                  label: const Text('Start Focus ⏱️'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EkagraColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: EkagraSpacing.md),
                  ),
                ),
              ),
              const SizedBox(width: EkagraSpacing.sm),
              OutlinedButton(
                onPressed: () {
                  taskProvider.skipOneThing(
                    energy: energyProvider.currentLevel,
                    mood: moodProvider.currentLevel,
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: EkagraSpacing.lg,
                    vertical: EkagraSpacing.md,
                  ),
                  side: BorderSide(
                    color: EkagraColors.primaryLight.withValues(alpha: 0.5),
                  ),
                ),
                child: const Text('Skip →'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String emoji, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(EkagraSpacing.md),
      decoration: BoxDecoration(
        color: EkagraColors.surface,
        borderRadius: BorderRadius.circular(EkagraRadius.lg),
        border: Border.all(
          color: EkagraColors.primaryLight.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: EkagraSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: EkagraTypography.bodyBold.copyWith(fontSize: 14),
              ),
              Text(
                subtitle,
                style: EkagraTypography.tiny,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
