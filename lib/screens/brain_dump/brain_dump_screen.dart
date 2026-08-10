import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../providers/task_provider.dart';

class BrainDumpScreen extends StatefulWidget {
  const BrainDumpScreen({super.key});

  @override
  State<BrainDumpScreen> createState() => _BrainDumpScreenState();
}

class _BrainDumpScreenState extends State<BrainDumpScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<String> _dumpedItems = [];
  bool _isListeningVoice = false;
  bool _showAllTemplates = false;

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

  void _addItem(String text) {
    final clean = text.trim();
    if (clean.isEmpty) return;
    setState(() {
      _dumpedItems.add(clean);
      _controller.clear();
    });
    _focusNode.requestFocus();
  }

  void _removeItem(int index) {
    setState(() {
      _dumpedItems.removeAt(index);
    });
  }

  void _toggleVoice() {
    setState(() {
      _isListeningVoice = !_isListeningVoice;
    });
    if (_isListeningVoice) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _isListeningVoice) {
          _addItem('Call dentist for appointment');
          setState(() {
            _isListeningVoice = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.read<TaskProvider>();
    final featuredTemplates = EkagraConstants.commonTaskTemplates.take(3).toList();
    final remainingTemplates = EkagraConstants.commonTaskTemplates.skip(3).toList();

    return Scaffold(
      backgroundColor: EkagraColors.background,
      appBar: AppBar(
        title: const Text('Brain Dump 🧠'),
        actions: [
          if (_dumpedItems.isNotEmpty)
            TextButton(
              onPressed: () async {
                await taskProvider.addTasks(_dumpedItems);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
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
                      decoration: InputDecoration(
                        hintText: 'Type or speak anything...',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isListeningVoice ? Icons.mic_rounded : Icons.mic_none_rounded,
                            color: _isListeningVoice ? EkagraColors.error : EkagraColors.primary,
                          ),
                          onPressed: _toggleVoice,
                        ),
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

            if (_isListeningVoice)
              Padding(
                padding: const EdgeInsets.all(EkagraSpacing.md),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: EkagraColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(EkagraRadius.full),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: EkagraColors.error, size: 10),
                      SizedBox(width: 8),
                      Text(
                        'Listening... speak clearly',
                        style: TextStyle(
                          color: EkagraColors.error,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
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
                              'Tap a template chip below:',
                              style: EkagraTypography.caption,
                            ),
                            const SizedBox(height: EkagraSpacing.md),

                            // Rule 1 Compliance: Max 3 Primary Featured Templates
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                ...featuredTemplates.map((t) => _templateChip(t)),
                                if (_showAllTemplates)
                                  ...remainingTemplates.map((t) => _templateChip(t)),
                              ],
                            ),

                            const SizedBox(height: EkagraSpacing.sm),

                            TextButton.icon(
                              onPressed: () {
                                setState(() => _showAllTemplates = !_showAllTemplates);
                              },
                              icon: Icon(_showAllTemplates ? Icons.expand_less : Icons.expand_more, size: 18),
                              label: Text(_showAllTemplates ? 'Show fewer prompts' : 'More prompt ideas'),
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
                        onPressed: () async {
                          await taskProvider.addTasks(_dumpedItems);
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        },
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

  Widget _templateChip(String t) {
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
  }
}
