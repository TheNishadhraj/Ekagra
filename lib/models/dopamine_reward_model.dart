import 'package:uuid/uuid.dart';

import 'dopamine_menu_model.dart';

class DopamineReward {
  final String id;
  final DopamineItem item;
  final bool isRare;
  final String? rareMessage;
  final DateTime earnedAt;
  final String? relatedTaskId;
  final String? relatedTaskTitle;

  const DopamineReward({
    required this.id,
    required this.item,
    this.isRare = false,
    this.rareMessage,
    required this.earnedAt,
    this.relatedTaskId,
    this.relatedTaskTitle,
  });

  String get emoji => item.emoji;
  String get title => item.text;
  String? get description => rareMessage ?? '${item.durationMinutes} min reward';

  factory DopamineReward.fromItem(
    DopamineItem item, {
    bool isRare = false,
    String? rareMessage,
    String? relatedTaskId,
    String? relatedTaskTitle,
  }) {
    return DopamineReward(
      id: const Uuid().v4(),
      item: item,
      isRare: isRare,
      rareMessage: rareMessage,
      earnedAt: DateTime.now(),
      relatedTaskId: relatedTaskId,
      relatedTaskTitle: relatedTaskTitle,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'item': item.toJson(),
        'isRare': isRare,
        'rareMessage': rareMessage,
        'earnedAt': earnedAt.toIso8601String(),
        'relatedTaskId': relatedTaskId,
        'relatedTaskTitle': relatedTaskTitle,
      };

  factory DopamineReward.fromJson(Map<String, dynamic> json) {
    return DopamineReward(
      id: json['id'] as String,
      item: DopamineItem.fromJson(json['item'] as Map<String, dynamic>),
      isRare: json['isRare'] as bool? ?? false,
      rareMessage: json['rareMessage'] as String?,
      earnedAt: DateTime.parse(json['earnedAt'] as String),
      relatedTaskId: json['relatedTaskId'] as String?,
      relatedTaskTitle: json['relatedTaskTitle'] as String?,
    );
  }
}
