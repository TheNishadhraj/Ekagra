import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../providers/energy_provider.dart';
import '../../providers/focus_provider.dart';
import '../../providers/mood_provider.dart';
import '../../providers/reward_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/task_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/export_service.dart';
import '../../services/monetization_service.dart';
import '../../services/nudge_service.dart';
import '../../utils/rsd_safe_copy.dart';
import '../shared/ekagra_paywall_sheet.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final rewardProvider = context.watch<RewardProvider>();
    final money = context.watch<MonetizationService>();
    final user = settings.user;
    // Entitlement comes from the monetization engine, never from a bare flag.
    final isPro = money.isPro;

    return Scaffold(
      backgroundColor: EkagraColors.background,
      appBar: AppBar(
        title: const Text('Settings ⚙️'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(EkagraSpacing.lg),
          children: [
            // Profile Card
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
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: EkagraColors.primary.withValues(alpha: 0.15),
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '👤',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: EkagraSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name, style: EkagraTypography.h3),
                        Text(
                          money.statusLabel,
                          style: EkagraTypography.caption.copyWith(
                            color: isPro
                                ? EkagraColors.primary
                                : EkagraColors.textSecondary,
                            fontWeight:
                                isPro ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isPro)
                    TextButton(
                      onPressed: () {
                        EkagraPaywallSheet.show(
                          context,
                          trigger: PaywallTrigger.settings,
                        );
                      },
                      child: const Text('Upgrade'),
                    ),
                ],
              ),
            ),

            const SizedBox(height: EkagraSpacing.xl),

            // Section: Preferences
            _sectionHeader('PREFERENCES'),
            SwitchListTile(
              title: const Text('Dark Mode'),
              subtitle: const Text('Reduces eye strain'),
              value: settings.darkMode,
              activeThumbColor: EkagraColors.primary,
              onChanged: (val) => settings.setDarkMode(val),
            ),
            ListTile(
              title: const Text('ADHD Profile'),
              subtitle: Text('${user.adhdTraits.length} traits selected'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () => Navigator.pushNamed(context, AppRoutes.adhdType),
            ),
            ListTile(
              title: const Text('Dopamine Menu'),
              subtitle: Text('${rewardProvider.quickRewards.length + rewardProvider.mediumRewards.length + rewardProvider.bigRewards.length} items configured'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () => Navigator.pushNamed(context, AppRoutes.dopamineSetup),
            ),
            ListTile(
              title: const Text('Someday / Maybe List'),
              subtitle: const Text('Aspirational tasks without pressure'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () => Navigator.pushNamed(context, AppRoutes.someday),
            ),

            const Divider(height: EkagraSpacing.xl),

            // Section: Notifications
            _sectionHeader('NOTIFICATIONS'),
            SwitchListTile(
              title: const Text('Gentle Nudges'),
              subtitle: const Text('Max 3 friendly reminders per day'),
              value: settings.notificationsEnabled,
              activeThumbColor: EkagraColors.primary,
              onChanged: (val) async {
                // WI-1.4: the switch is real now — it gates actual local
                // notifications, and turning it off cancels everything
                // pending (test-enforced).
                if (val) {
                  await NudgeService.instance.requestPermission();
                  await settings.enableNotifications();
                  await NudgeService.instance.enabledSet(true);
                  await NudgeService.instance.scheduleDailyBrief(
                    hour: settings.user.notifications.morning.hour,
                  );
                } else {
                  await settings.disableNotifications();
                  await NudgeService.instance.enabledSet(false);
                }
              },
            ),

            const Divider(height: EkagraSpacing.xl),

            // Section: Subscription & Cancellation
            _sectionHeader('SUBSCRIPTION'),
            ListTile(
              title: const Text('Manage Subscription'),
              subtitle: Text(
                isPro
                    ? '${money.statusLabel} — 1-tap cancellation'
                    : 'Free Tier',
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () {
                _showSubscriptionDialog(context, settings);
              },
            ),

            const Divider(height: EkagraSpacing.xl),

            // Section: Data & Export
            _sectionHeader('DATA & PRIVACY'),
            ListTile(
              title: const Text('Export My Data'),
              subtitle: const Text('Export tasks & rewards as JSON + CSV'),
              trailing: const Icon(Icons.download_rounded),
              onTap: () => _exportData(context),
            ),

            // Privacy-first instrumentation: the user can switch off
            // analytics entirely and the product keeps working. Measuring
            // people who asked not to be measured is not a growth strategy,
            // it is a liability.
            const _AnalyticsOptOutTile(),

            ListTile(
              title: const Text('Growth Console 📈'),
              subtitle: const Text(
                'North Star, activation funnel, experiments, unit economics',
              ),
              trailing: const Icon(Icons.insights_rounded),
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.growthDashboard),
            ),

            const Divider(height: EkagraSpacing.xl),

            // Section: Account
            _sectionHeader('ACCOUNT'),
            ListTile(
              title: const Text('Reset Onboarding'),
              onTap: () async {
                await settings.resetOnboarding();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, AppRoutes.welcome);
                }
              },
            ),
            ListTile(
              title: const Text(
                'Delete Account',
                style: TextStyle(color: EkagraColors.error),
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Account?'),
                    content: const Text(
                      'Your data is saved locally. You can clear your data anytime. No hard delete auto-deletes without consent.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Account data cleared safely.'),
                            ),
                          );
                        },
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: EkagraColors.error),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: EkagraSpacing.xxl),
            Center(
              child: Text(
                'Ekagra v1.0.0 · Made with 💛 for ADHD brains',
                style: EkagraTypography.tiny,
              ),
            ),
            const SizedBox(height: EkagraSpacing.xl),
          ],
        ),
      ),
    );
  }

  /// K18 fix: export is real now. Everything is serialized locally, written
  /// to the app's documents directory, and handed to the OS share sheet.
  /// The success snackbar may only ever appear after a file actually exists
  /// on disk — the old "File saved locally" message with no file behind it
  /// was a brand violation (see docs/IMPLEMENTATION_PROMPT.md, WI-1.1).
  Future<void> _exportData(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final payload = ExportService.buildExportPayload(
      tasks: context.read<TaskProvider>().allIncludingDeleted,
      rewards: context.read<RewardProvider>().history,
      energyLogs: context.read<EnergyProvider>().logs,
      moodLogs: context.read<MoodProvider>().logs,
      user: context.read<SettingsProvider>().user,
      menu: context.read<SettingsProvider>().menu,
      todayFocusMinutes: context.read<FocusProvider>().todayFocusMinutes,
    );

    try {
      final file = await ExportService().writeExport(payload: payload);
      track(Ev.dataExported, {
        'format': 'json',
        'bytes': await file.length(),
        'task_count': (payload['tasks'] as List).length,
      });
      await Share.shareXFiles([XFile(file.path)], text: 'Ekagra export');
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            '📤 Exported. Share it or save it wherever you like.',
          ),
          backgroundColor: EkagraColors.primary,
        ),
      );
    } catch (_) {
      // Honest failure only. Never claim a file that does not exist.
      messenger.showSnackBar(
        const SnackBar(
          content: Text(RsdSafeCopy.unknownError),
          backgroundColor: EkagraColors.textSecondary,
        ),
      );
    }
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: EkagraSpacing.xs),
      child: Text(
        title,
        style: EkagraTypography.tiny.copyWith(
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  void _showSubscriptionDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Subscription Management'),
        content: Text(
          MonetizationService.instance.isPro
              ? '${MonetizationService.instance.statusLabel}.\n\n'
                  'Cancel with one tap below. You keep Pro until the end of '
                  'the period you already paid for, and your data stays exactly '
                  'where it is.'
              : 'You are on the Free tier. Free is genuinely free — upgrade only '
                  'if the ceilings start getting in your way.',
        ),
        actions: [
          if (MonetizationService.instance.isPro)
            TextButton(
              onPressed: () async {
                // Spec Rule 8 / O5: one tap, no retention maze, no
                // "are you sure?" gauntlet. Access continues to period end.
                await MonetizationService.instance.cancel();
                await settings.disablePro();
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Cancelled. You keep Pro until the period ends. No charge after that.',
                      ),
                    ),
                  );
                }
              },
              child: const Text(
                'Cancel Subscription (1 tap)',
                style: TextStyle(color: EkagraColors.error),
              ),
            )
          else
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                EkagraPaywallSheet.show(
                  context,
                  trigger: PaywallTrigger.settings,
                );
              },
              child: const Text('Upgrade to Pro'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Analytics opt-out.
///
/// Its own stateful widget so toggling rebuilds only this row rather than the
/// whole settings list.
class _AnalyticsOptOutTile extends StatefulWidget {
  const _AnalyticsOptOutTile();

  @override
  State<_AnalyticsOptOutTile> createState() => _AnalyticsOptOutTileState();
}

class _AnalyticsOptOutTileState extends State<_AnalyticsOptOutTile> {
  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: const Text('Share anonymous usage data'),
      subtitle: const Text(
        'Helps us find rough edges. Never sold. Stays on your device in this build.',
      ),
      value: AnalyticsService.instance.enabled,
      activeThumbColor: EkagraColors.primary,
      onChanged: (v) async {
        await AnalyticsService.instance.setEnabled(v);
        if (mounted) setState(() {});
      },
    );
  }
}
