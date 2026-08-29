import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../providers/task_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/nudge_service.dart';
import '../focus/focus_timer_screen.dart';
import 'milestone_sheet.dart';
import '../home/home_screen.dart';
import '../settings/settings_screen.dart';
import '../timeline/day_view_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _currentIndex = 0;

  final _pages = const [
    HomeScreen(),
    DayViewScreen(),
    FocusTimerScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // WI-5.3: the one-shot milestone celebration, after first frame so the
    // sheet lands on a fully built shell (never blocks the app opening).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) MilestoneSheet.maybeShow(context);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// WI-1.4: the sidekick pattern. Leaving the app *with* a picked One
  /// Thing arms the gentle sequence (max 3, then silence) and one
  /// welcome-back nudge three days out. Coming back cancels both —
  /// "nothing was lost" only ever needs to be said when it is true.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final nudges = NudgeService.instance;
    if (!nudges.enabled) return;

    if (state == AppLifecycleState.paused) {
      track(Ev.appBackgrounded, {});
      final oneThing = context.read<TaskProvider>().oneThing;
      if (oneThing != null) {
        nudges.beginTaskNudges(
          taskId: oneThing.id,
          taskTitle: oneThing.title,
        );
      }
      nudges.scheduleWelcomeBack();
    } else if (state == AppLifecycleState.resumed) {
      nudges.cancelAllTaskNudges();
      nudges.cancelWelcomeBack();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.brainDump);
        },
        backgroundColor: EkagraColors.primary,
        elevation: 6,
        shape: const CircleBorder(),
        child: const Icon(
          Icons.add_rounded,
          size: 32,
          color: Colors.white,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: EkagraColors.surface,
        elevation: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.home_rounded, 'Home'),
              _navItem(1, Icons.today_rounded, 'Day View'),
              const SizedBox(width: 40), // Gap for FAB
              _navItem(2, Icons.timer_rounded, 'Focus'),
              _navItem(3, Icons.person_rounded, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? EkagraColors.primary : EkagraColors.textTertiary;

    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(EkagraRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
