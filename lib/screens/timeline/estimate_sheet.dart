import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/task_model.dart';
import '../../providers/focus_provider.dart';
import '../../utils/countdown_palette.dart';

/// "Make active" + estimate + 50% buffer (WI-2.2).
///
/// Llama Life's anti-overwhelm rule: ONE active task at a time. This sheet
/// is the single entry point — from the Day View, one tap on the bolt, one
/// tap to confirm. The buffer offer is the documented ADHD estimation
/// correction, never applied silently.
class EstimateSheet extends StatefulWidget {
  const EstimateSheet({super.key, required this.task});

  final TaskModel task;

  static Future<void> show(BuildContext context, TaskModel task) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EstimateSheet(task: task),
    );
  }

  @override
  State<EstimateSheet> createState() => _EstimateSheetState();
}

class _EstimateSheetState extends State<EstimateSheet> {
  late int _minutes;
  bool _buffered = false;

  @override
  void initState() {
    super.initState();
    _minutes = widget.task.estimatedMinutes ?? 20;
  }

  int get _timerMinutes =>
      _buffered ? CountdownPalette.bufferedMinutes(_minutes) : _minutes;

  void _apply({required bool navigate}) {
    final focus = context.read<FocusProvider>();
    // One active task at a time: setting a task replaces any previous one.
    focus.setTask(widget.task);
    focus.setDuration(_timerMinutes);
    Navigator.pop(context);
    if (navigate) {
      Navigator.pushNamed(context, AppRoutes.focus);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: EkagraColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(EkagraRadius.xl),
        ),
      ),
      padding: EdgeInsets.only(
        top: EkagraSpacing.md,
        left: EkagraSpacing.lg,
        right: EkagraSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + EkagraSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: EkagraColors.textTertiary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: EkagraSpacing.md),
          Text(
            '${widget.task.emoji ?? '🎯'}  ${widget.task.title}',
            style: EkagraTypography.h3,
          ),
          const SizedBox(height: EkagraSpacing.xs),
          Text(
            'How long feels honest for this one?',
            style: EkagraTypography.caption,
          ),
          const SizedBox(height: EkagraSpacing.lg),

          // Estimate stepper — coarse on purpose; precision is paralysis.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _minutes > 5
                    ? () => setState(() => _minutes -= 5)
                    : null,
                icon: const Icon(Icons.remove_circle_outline_rounded),
              ),
              SizedBox(
                width: 96,
                child: Center(
                  child: Text(
                    '$_minutes min',
                    style: EkagraTypography.h2,
                  ),
                ),
              ),
              IconButton(
                onPressed: _minutes < 120
                    ? () => setState(() => _minutes += 5)
                    : null,
                icon: const Icon(Icons.add_circle_outline_rounded),
              ),
            ],
          ),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Add 50% buffer'),
            subtitle: const Text(
              'Your brain underestimates. A little air helps.',
            ),
            value: _buffered,
            activeColor: EkagraColors.primary,
            onChanged: (v) => setState(() => _buffered = v),
          ),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(EkagraSpacing.md),
            decoration: BoxDecoration(
              color: EkagraColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(EkagraRadius.md),
            ),
            child: Text(
              'Your timer: $_timerMinutes min',
              style: EkagraTypography.bodyBold.copyWith(
                color: EkagraColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: EkagraSpacing.lg),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _apply(navigate: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: EkagraColors.primary,
              ),
              icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
              label: const Text('Start focus ⏱️'),
            ),
          ),
          const SizedBox(height: EkagraSpacing.sm),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () => _apply(navigate: false),
              child: const Text('Just make it active'),
            ),
          ),
        ],
      ),
    );
  }
}
