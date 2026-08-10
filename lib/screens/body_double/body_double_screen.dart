import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../services/analytics_service.dart';
import '../../services/monetization_service.dart';
import '../../widgets/pro_gate.dart';

class BodyDoubleScreen extends StatefulWidget {
  const BodyDoubleScreen({super.key});

  @override
  State<BodyDoubleScreen> createState() => _BodyDoubleScreenState();
}

class _BodyDoubleScreenState extends State<BodyDoubleScreen> {
  bool _joined = false;
  int _roomCount = 127;
  final List<String> _sentCheers = [];

  final _cheers = const ['👏', '💪', '🔥', '❤️', '🎉', '🌟'];

  /// Body doubling is the strongest network-effect surface in the product:
  /// every additional person in a room makes the room more valuable to
  /// everyone already in it. That is why it is a Pro feature — it is also
  /// why the gate must be soft and never block browsing the room.
  Future<bool> _guardPro() async {
    return ProGate.guard(
      context,
      feature: ProFeature.bodyDoubling,
      trigger: PaywallTrigger.bodyDoubling,
    );
  }

  void _sendCheer(String emoji) {
    setState(() {
      _sentCheers.add(emoji);
    });
    track(Ev.bodyDoubleCheered, {'type': emoji});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$emoji Sent cheer to someone in the focus room!'),
        duration: const Duration(seconds: 1),
        backgroundColor: EkagraColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EkagraColors.background,
      appBar: AppBar(
        title: const Text('Body Doubling 🤝'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(EkagraSpacing.xl),
          child: Column(
            children: [
              // Room Status Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(EkagraSpacing.xl),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      EkagraColors.primary.withValues(alpha: 0.1),
                      EkagraColors.primaryLight.withValues(alpha: 0.2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(EkagraRadius.xl),
                  border: Border.all(
                    color: EkagraColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    const Text('🤝', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: EkagraSpacing.sm),
                    Text(
                      '$_roomCount people focusing right now',
                      style: EkagraTypography.h2.copyWith(fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Silent, anonymous co-working. You are not alone.',
                      style: EkagraTypography.caption,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: EkagraSpacing.xxl),

              if (!_joined) ...[
                Text(
                  'Join the focus room to boost focus alongside others.',
                  style: EkagraTypography.body,
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!await _guardPro()) return;
                      if (!mounted) return;
                      setState(() {
                        _joined = true;
                        _roomCount++;
                      });
                      track(Ev.bodyDoubleJoined, {'room_count': _roomCount});
                    },
                    child: const Text('Join the Focus Room 🚀'),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(EkagraSpacing.lg),
                  decoration: BoxDecoration(
                    color: EkagraColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(EkagraRadius.lg),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.circle, color: EkagraColors.success, size: 12),
                      SizedBox(width: 8),
                      Text(
                        'You are currently in the room',
                        style: TextStyle(
                          color: EkagraColors.success,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: EkagraSpacing.xl),

                Text(
                  'Send a Quick Cheer 💬',
                  style: EkagraTypography.bodyBold,
                ),
                const SizedBox(height: 4),
                Text(
                  'Anonymous cheer to encourage a fellow focus partner.',
                  style: EkagraTypography.caption,
                ),

                const SizedBox(height: EkagraSpacing.md),

                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _cheers.map((emoji) {
                    return InkWell(
                      onTap: () => _sendCheer(emoji),
                      borderRadius: BorderRadius.circular(EkagraRadius.full),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: EkagraColors.surface,
                          borderRadius: BorderRadius.circular(EkagraRadius.full),
                          border: Border.all(
                            color: EkagraColors.primaryLight.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const Spacer(),

                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _joined = false;
                      _roomCount--;
                    });
                  },
                  child: const Text('Leave Room'),
                ),
              ],

              const SizedBox(height: EkagraSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
