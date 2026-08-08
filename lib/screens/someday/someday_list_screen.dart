import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/task_model.dart';
import '../../providers/task_provider.dart';

class SomedayListScreen extends StatelessWidget {
  const SomedayListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final somedayTasks = taskProvider.somedayTasks;

    return Scaffold(
      backgroundColor: EkagraColors.background,
      appBar: AppBar(
        title: const Text('Someday / Maybe 📦'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(EkagraSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'No pressure. These are here whenever you\'re ready.',
                style: EkagraTypography.caption,
              ),
              const SizedBox(height: EkagraSpacing.lg),

              Expanded(
                child: somedayTasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('📦', style: TextStyle(fontSize: 40)),
                            const SizedBox(height: EkagraSpacing.sm),
                            Text('Someday list is empty', style: EkagraTypography.bodyBold),
                            const SizedBox(height: EkagraSpacing.xs),
                            Text(
                              'Move low-priority aspirational ideas here anytime.',
                              style: EkagraTypography.caption,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: somedayTasks.length,
                        itemBuilder: (context, index) {
                          final task = somedayTasks[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: EkagraSpacing.sm),
                            child: ListTile(
                              leading: Text(task.emoji ?? '🎨', style: const TextStyle(fontSize: 24)),
                              title: Text(task.title, style: EkagraTypography.bodyBold),
                              subtitle: Text('Added ${_formatAge(task.createdAt)}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.arrow_upward_rounded),
                                    tooltip: 'Move to Today',
                                    onPressed: () {
                                      final updated = task.copyWith(
                                        scheduleType: TaskScheduleType.today,
                                      );
                                      taskProvider.updateTask(updated);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded),
                                    onPressed: () {
                                      taskProvider.archiveTask(task.id);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatAge(DateTime date) {
    final diff = DateTime.now().difference(date).inDays;
    if (diff == 0) return 'today';
    if (diff == 1) return 'yesterday';
    return '$diff days ago';
  }
}
