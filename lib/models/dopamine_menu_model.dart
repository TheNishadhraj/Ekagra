import 'package:uuid/uuid.dart';

enum RewardTier { quick, medium, big }

class DopamineItem {
  final String id;
  final String emoji;
  final String text;
  final int durationMinutes;
  final RewardTier tier;
  final bool isCustom;
  final DateTime createdAt;

  const DopamineItem({
    required this.id,
    required this.emoji,
    required this.text,
    required this.durationMinutes,
    required this.tier,
    this.isCustom = false,
    required this.createdAt,
  });

  factory DopamineItem.create({
    required String emoji,
    required String text,
    required int durationMinutes,
    required RewardTier tier,
    bool isCustom = false,
  }) {
    return DopamineItem(
      id: const Uuid().v4(),
      emoji: emoji,
      text: text,
      durationMinutes: durationMinutes,
      tier: tier,
      isCustom: isCustom,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'emoji': emoji,
        'text': text,
        'durationMinutes': durationMinutes,
        'tier': tier.name,
        'isCustom': isCustom,
        'createdAt': createdAt.toIso8601String(),
      };

  factory DopamineItem.fromJson(Map<String, dynamic> json) {
    return DopamineItem(
      id: json['id'] as String,
      emoji: json['emoji'] as String,
      text: json['text'] as String,
      durationMinutes: json['durationMinutes'] as int,
      tier: RewardTier.values.byName(json['tier'] as String),
      isCustom: json['isCustom'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class DopamineMenu {
  final List<DopamineItem> quick;
  final List<DopamineItem> medium;
  final List<DopamineItem> big;

  const DopamineMenu({
    this.quick = const [],
    this.medium = const [],
    this.big = const [],
  });

  List<DopamineItem> get all => [...quick, ...medium, ...big];

  List<DopamineItem> forTier(RewardTier tier) {
    switch (tier) {
      case RewardTier.quick:
        return quick;
      case RewardTier.medium:
        return medium;
      case RewardTier.big:
        return big;
    }
  }

  DopamineMenu copyWith({
    List<DopamineItem>? quick,
    List<DopamineItem>? medium,
    List<DopamineItem>? big,
  }) {
    return DopamineMenu(
      quick: quick ?? this.quick,
      medium: medium ?? this.medium,
      big: big ?? this.big,
    );
  }

  Map<String, dynamic> toJson() => {
        'quick': quick.map((e) => e.toJson()).toList(),
        'medium': medium.map((e) => e.toJson()).toList(),
        'big': big.map((e) => e.toJson()).toList(),
      };

  factory DopamineMenu.fromJson(Map<String, dynamic> json) {
    return DopamineMenu(
      quick: (json['quick'] as List<dynamic>?)
              ?.map((e) => DopamineItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      medium: (json['medium'] as List<dynamic>?)
              ?.map((e) => DopamineItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      big: (json['big'] as List<dynamic>?)
              ?.map((e) => DopamineItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  /// Spec B4 — works with zero setup
  static DopamineMenu get defaults {
    final now = DateTime.now();
    return DopamineMenu(
      quick: [
        DopamineItem(
          id: 'dq1',
          emoji: '🎵',
          text: 'Listen to 1 hype song',
          durationMinutes: 3,
          tier: RewardTier.quick,
          createdAt: now,
        ),
        DopamineItem(
          id: 'dq2',
          emoji: '🍫',
          text: 'Eat a snack',
          durationMinutes: 2,
          tier: RewardTier.quick,
          createdAt: now,
        ),
        DopamineItem(
          id: 'dq3',
          emoji: '💃',
          text: '60-second dance break',
          durationMinutes: 1,
          tier: RewardTier.quick,
          createdAt: now,
        ),
      ],
      medium: [
        DopamineItem(
          id: 'dm1',
          emoji: '🚶',
          text: 'Take a short walk',
          durationMinutes: 15,
          tier: RewardTier.medium,
          createdAt: now,
        ),
        DopamineItem(
          id: 'dm2',
          emoji: '☕',
          text: 'Make a fancy coffee',
          durationMinutes: 10,
          tier: RewardTier.medium,
          createdAt: now,
        ),
        DopamineItem(
          id: 'dm3',
          emoji: '🐕',
          text: 'Pet/play with your pet',
          durationMinutes: 10,
          tier: RewardTier.medium,
          createdAt: now,
        ),
      ],
      big: [
        DopamineItem(
          id: 'db1',
          emoji: '📺',
          text: 'Watch an episode of your show',
          durationMinutes: 45,
          tier: RewardTier.big,
          createdAt: now,
        ),
        DopamineItem(
          id: 'db2',
          emoji: '🛁',
          text: 'Take a long bath/shower',
          durationMinutes: 30,
          tier: RewardTier.big,
          createdAt: now,
        ),
        DopamineItem(
          id: 'db3',
          emoji: '🎮',
          text: 'Gaming session',
          durationMinutes: 60,
          tier: RewardTier.big,
          createdAt: now,
        ),
      ],
    );
  }

  static Map<RewardTier, List<DopamineItem>> get predefinedPool {
    final now = DateTime.now();
    return {
      RewardTier.quick: [
        DopamineItem(
          id: 'pq1',
          emoji: '🎵',
          text: 'Listen to 1 hype song',
          durationMinutes: 3,
          tier: RewardTier.quick,
          createdAt: now,
        ),
        DopamineItem(
          id: 'pq2',
          emoji: '🍫',
          text: 'Eat a snack',
          durationMinutes: 2,
          tier: RewardTier.quick,
          createdAt: now,
        ),
        DopamineItem(
          id: 'pq3',
          emoji: '📱',
          text: 'Scroll social media guilt-free',
          durationMinutes: 2,
          tier: RewardTier.quick,
          createdAt: now,
        ),
        DopamineItem(
          id: 'pq4',
          emoji: '🎮',
          text: 'Play 1 round of a game',
          durationMinutes: 3,
          tier: RewardTier.quick,
          createdAt: now,
        ),
        DopamineItem(
          id: 'pq5',
          emoji: '💃',
          text: '60-second dance break',
          durationMinutes: 1,
          tier: RewardTier.quick,
          createdAt: now,
        ),
        DopamineItem(
          id: 'pq6',
          emoji: '☕',
          text: 'Make a quick tea/coffee',
          durationMinutes: 3,
          tier: RewardTier.quick,
          createdAt: now,
        ),
        DopamineItem(
          id: 'pq7',
          emoji: '🌈',
          text: 'Watch a funny reel',
          durationMinutes: 2,
          tier: RewardTier.quick,
          createdAt: now,
        ),
        DopamineItem(
          id: 'pq8',
          emoji: '🫧',
          text: 'Pop bubble wrap (yes, really)',
          durationMinutes: 1,
          tier: RewardTier.quick,
          createdAt: now,
        ),
      ],
      RewardTier.medium: [
        DopamineItem(
          id: 'pm1',
          emoji: '🚶',
          text: 'Take a short walk',
          durationMinutes: 15,
          tier: RewardTier.medium,
          createdAt: now,
        ),
        DopamineItem(
          id: 'pm2',
          emoji: '☕',
          text: 'Make a fancy coffee',
          durationMinutes: 10,
          tier: RewardTier.medium,
          createdAt: now,
        ),
        DopamineItem(
          id: 'pm3',
          emoji: '🎬',
          text: 'Watch a YouTube video',
          durationMinutes: 15,
          tier: RewardTier.medium,
          createdAt: now,
        ),
        DopamineItem(
          id: 'pm4',
          emoji: '🐕',
          text: 'Pet/play with your pet',
          durationMinutes: 10,
          tier: RewardTier.medium,
          createdAt: now,
        ),
        DopamineItem(
          id: 'pm5',
          emoji: '🎵',
          text: 'Listen to a full album',
          durationMinutes: 15,
          tier: RewardTier.medium,
          createdAt: now,
        ),
        DopamineItem(
          id: 'pm6',
          emoji: '🧖',
          text: 'Quick skincare routine',
          durationMinutes: 10,
          tier: RewardTier.medium,
          createdAt: now,
        ),
        DopamineItem(
          id: 'pm7',
          emoji: '📞',
          text: 'Call a friend',
          durationMinutes: 15,
          tier: RewardTier.medium,
          createdAt: now,
        ),
        DopamineItem(
          id: 'pm8',
          emoji: '🧁',
          text: 'Bake something simple',
          durationMinutes: 15,
          tier: RewardTier.medium,
          createdAt: now,
        ),
      ],
      RewardTier.big: [
        DopamineItem(
          id: 'pb1',
          emoji: '📺',
          text: 'Watch an episode of your show',
          durationMinutes: 45,
          tier: RewardTier.big,
          createdAt: now,
        ),
        DopamineItem(
          id: 'pb2',
          emoji: '🛁',
          text: 'Take a long bath/shower',
          durationMinutes: 30,
          tier: RewardTier.big,
          createdAt: now,
        ),
        DopamineItem(
          id: 'pb3',
          emoji: '🎮',
          text: 'Gaming session',
          durationMinutes: 60,
          tier: RewardTier.big,
          createdAt: now,
        ),
        DopamineItem(
          id: 'pb4',
          emoji: '🎨',
          text: 'Creative time (art, music, etc.)',
          durationMinutes: 45,
          tier: RewardTier.big,
          createdAt: now,
        ),
        DopamineItem(
          id: 'pb5',
          emoji: '🛍️',
          text: 'Online window shopping',
          durationMinutes: 30,
          tier: RewardTier.big,
          createdAt: now,
        ),
        DopamineItem(
          id: 'pb6',
          emoji: '📖',
          text: 'Read a book/manga',
          durationMinutes: 30,
          tier: RewardTier.big,
          createdAt: now,
        ),
        DopamineItem(
          id: 'pb7',
          emoji: '🌳',
          text: 'Go outside for a while',
          durationMinutes: 30,
          tier: RewardTier.big,
          createdAt: now,
        ),
        DopamineItem(
          id: 'pb8',
          emoji: '😴',
          text: 'Guilt-free nap',
          durationMinutes: 30,
          tier: RewardTier.big,
          createdAt: now,
        ),
      ],
    };
  }
}

class DopamineMenuDefaults {
  DopamineMenuDefaults._();
  static Map<String, List<DopamineItem>> get pool => {
        'quick': DopamineMenu.predefinedPool[RewardTier.quick]!,
        'medium': DopamineMenu.predefinedPool[RewardTier.medium]!,
        'big': DopamineMenu.predefinedPool[RewardTier.big]!,
      };
}
