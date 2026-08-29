import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../providers/task_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/monetization_service.dart';
import '../../services/voice_dump_parser.dart';
import '../../widgets/pro_gate.dart';

class BrainDumpScreen extends StatefulWidget {
  const BrainDumpScreen({super.key});

  @override
  State<BrainDumpScreen> createState() => _BrainDumpScreenState();
}

class _BrainDumpScreenState extends State<BrainDumpScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<String> _dumpedItems = [];
  final VoiceDumpParser _parser = VoiceDumpParser();

  final List<String> _categoryChips = const [
    '📧 Email',
    '🛒 Shopping',
    '📞 Call',
    '🧹 Clean',
    '📄 Work',
    '💊 Health',
    '💧 Self-care',
  ];

  @override
  void initState() {
    super.initState();
    track(Ev.brainDumpOpened, {'source': 'fab'});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Capture is sacred: we always let the thought land in the list first.
  ///
  /// The gate fires *after* the item is captured, not before — a user who is
  /// mid-brain-dump and gets interrupted by a paywall loses the thought, and
  /// losing the thought is the exact failure mode this whole app exists to
  /// prevent. Spec O2 makes the 11th-task gate non-skippable; we honour that
  /// on save, not on keystroke.
  Future<void> _addItem(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;

    setState(() {
      _dumpedItems.add(clean);
      _controller.clear();
    });
    _focusNode.requestFocus();

    track(Ev.brainDumpTaskAdded, {
      'length': clean.length,
      'source': 'text',
      'index': _dumpedItems.length,
    });

    final taskProvider = context.read<TaskProvider>();
    final money = MonetizationService.instance;
    if (money.isPro) return;

    final projected = taskProvider.activeIncomplete.length + _dumpedItems.length;
    // Fire exactly once, at the moment they cross the line.
    if (projected == money.freeTaskLimit + 1 && mounted) {
      await ProGate.guard(
        context,
        feature: ProFeature.unlimitedTasks,
        trigger: PaywallTrigger.taskLimit,
      );
    }
  }

  void _removeItem(int index) {
    setState(() {
      _dumpedItems.removeAt(index);
    });
  }

  /// WI-2.1 core, shipped without the microphone: split a whole pasted or
  /// typed brain-dump into confirmable task cards, with dates understood.
  /// The on-device voice binding itself is `FeatureFlags.voiceDump`
  /// (unbuilt, honestly) — see docs/briefs/voice-yap-mode-brief.md.
  void _smartSplit() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    final fragments = _parser.parse(text);
    if (fragments.isEmpty) return;

    setState(() {
      for (final f in fragments) {
        _dumpedItems.add(f.matchedTemplate ?? f.title);
      }
      _controller.clear();
    });
    _focusNode.requestFocus();

    track(Ev.brainDumpCompleted, {
      'source': 'smart_split',
      'task_count': fragments.length,
      'with_dates': fragments.where((f) => f.deadline != null).length,
    });
  }

  /// Persist the dump and tell the user the truth about what was saved.
  Future<void> _saveAll(TaskProvider taskProvider) async {
    final attempted = _dumpedItems.length;
    final saved = await taskProvider.addTasks(_dumpedItems);
    if (!mounted) return;

    final overflow = attempted - saved;
    if (overflow > 0) {
      // Honest, shame-free: name what happened and where the items went.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saved $saved. $overflow more need Pro — nothing was lost, '
            'finish a few and they will fit.',
          ),
          backgroundColor: EkagraColors.textSecondary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();

    return Scaffold(
      backgroundColor: EkagraColors.background,
      appBar: AppBar(
        title: const Text('Brain Dump 🧠'),
        actions: [
          if (_dumpedItems.isNotEmpty)
            TextButton(
              onPressed: () => _saveAll(taskProvider),
              child: const Text(
                'Save All',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: EkagraSpacing.lg),
              child: Text(
                'Just dump it. Don\'t think. Don\'t organize. Just type.',
                style: EkagraTypography.caption,
              ),
            ),

            const SizedBox(height: EkagraSpacing.md),

            // Input Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: EkagraSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      textInputAction: TextInputAction.done,
                      onSubmitted: _addItem,
                      decoration: const InputDecoration(
                        hintText: 'Dump anything here — one line or one blob',
                      ),
                    ),
                  ),
                  const SizedBox(width: EkagraSpacing.sm),
                  FloatingActionButton.small(
                    onPressed: () => _addItem(_controller.text),
                    backgroundColor: EkagraColors.primary,
                    elevation: 0,
                    child: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(
                EkagraSpacing.lg, EkagraSpacing.sm, EkagraSpacing.lg, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ActionChip(
                  avatar: const Icon(Icons.auto_awesome, size: 16),
                  label: const Text('Smart split ✨'),
                  backgroundColor: EkagraColors.surface,
                  side: BorderSide(
                    color: EkagraColors.primaryLight.withValues(alpha: 0.3),
                  ),
                  onPressed: _smartSplit,
                ),
              ),
            ),

            const SizedBox(height: EkagraSpacing.md),

            // Quick Category Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: EkagraSpacing.lg),
              child: Row(
                children: _categoryChips.map((chip) {
                  return Padding(
                    padding: const EdgeInsets.only(right: EkagraSpacing.xs),
                    child: ActionChip(
                      label: Text(chip),
                      backgroundColor: EkagraColors.surface,
                      side: BorderSide(
                        color: EkagraColors.primaryLight.withValues(alpha: 0.3),
                      ),
                      onPressed: () {
                        _controller.text = '$chip ';
                        _controller.selection = TextSelection.fromPosition(
                          TextPosition(offset: _controller.text.length),
                        );
                        _focusNode.requestFocus();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: EkagraSpacing.md),

            // Dumped Items List
            Expanded(
              child: _dumpedItems.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(EkagraSpacing.xl),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('💡', style: TextStyle(fontSize: 36)),
                            const SizedBox(height: EkagraSpacing.sm),
                            Text('Stuck on what to dump?', style: EkagraTypography.bodyBold),
                            const SizedBox(height: EkagraSpacing.xs),
                            Text(
                              'Tap any template to add instantly:',
                              style: EkagraTypography.caption,
                            ),
                            const SizedBox(height: EkagraSpacing.md),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: EkagraConstants.commonTaskTemplates.map((t) {
                                return InkWell(
                                  onTap: () => _addItem(t),
                                  borderRadius: BorderRadius.circular(EkagraRadius.full),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: EkagraColors.surfaceElevated,
                                      borderRadius: BorderRadius.circular(EkagraRadius.full),
                                      border: Border.all(
                                        color: EkagraColors.primaryLight.withValues(alpha: 0.2),
                                      ),
                                    ),
                                    child: Text(
                                      '+ $t',
                                      style: EkagraTypography.caption.copyWith(
                                        color: EkagraColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: EkagraSpacing.lg),
                      itemCount: _dumpedItems.length,
                      itemBuilder: (context, index) {
                        final item = _dumpedItems[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: EkagraSpacing.sm),
                          child: Container(
                            padding: const EdgeInsets.all(EkagraSpacing.md),
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
                                  radius: 12,
                                  backgroundColor: EkagraColors.primary.withValues(alpha: 0.1),
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: EkagraColors.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: EkagraSpacing.md),
                                Expanded(
                                  child: Text(
                                    item,
                                    style: EkagraTypography.body,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 20),
                                  color: EkagraColors.textTertiary,
                                  onPressed: () => _removeItem(index),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.1, end: 0),
                        );
                      },
                    ),
            ),

            // Free allowance meter — appears only when it's nearly relevant.
            FreeAllowanceMeter(
              used: taskProvider.activeIncomplete.length + _dumpedItems.length,
              limit: MonetizationService.instance.freeTaskLimit,
            ),

            // Bottom Done Dumping bar
            if (_dumpedItems.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(EkagraSpacing.lg),
                decoration: BoxDecoration(
                  color: EkagraColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => _saveAll(taskProvider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: EkagraColors.primary,
                        ),
                        child: Text(
                          'Done dumping! (${_dumpedItems.length} tasks) Pick ONE → 🎯',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
