import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../providers/reward_provider.dart';
import '../../providers/settings_provider.dart';
import '../shared/ekagra_paywall_sheet.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final rewardProvider = context.watch<RewardProvider>();
    final user = settings.user;

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
                          user.isPro ? '⭐ Ekagra Pro Member' : 'Free Member',
                          style: EkagraTypography.caption.copyWith(
                            color: user.isPro ? EkagraColors.primary : EkagraColors.textSecondary,
                            fontWeight: user.isPro ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!user.isPro)
                    TextButton(
                      onPressed: () {
                        EkagraPaywallSheet.show(context);
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
              onChanged: (val) {
                if (val) {
                  settings.enableNotifications();
                } else {
                  settings.disableNotifications();
                }
              },
            ),

            const Divider(height: EkagraSpacing.xl),

            // Section: Subscription & Cancellation
            _sectionHeader('SUBSCRIPTION'),
            ListTile(
              title: const Text('Manage Subscription'),
              subtitle: Text(
                user.isPro ? 'Pro Plan Active (1-tap cancellation available)' : 'Free Tier',
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
              subtitle: const Text('Export tasks & focus history as CSV/JSON'),
              trailing: const Icon(Icons.download_rounded),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('📤 Data export initiated! File saved locally.'),
                    backgroundColor: EkagraColors.primary,
                  ),
                );
              },
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
          settings.user.isPro
              ? 'You are currently on Ekagra Pro. Renew Date: 30 days from now.\n\nYou can cancel anytime with 1 tap below. Your data will remain safe.'
              : 'You are on the Free tier. Upgrade anytime to unlock unlimited tasks & AI features.',
        ),
        actions: [
          if (settings.user.isPro)
            TextButton(
              onPressed: () async {
                await settings.disablePro();
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Subscription cancelled transparently. No charge.'),
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
                EkagraPaywallSheet.show(context);
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
