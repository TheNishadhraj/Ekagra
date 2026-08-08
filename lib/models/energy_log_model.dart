enum EnergyLevel {
  drained, // 😫
  low, // 😐
  medium, // 🙂
  high, // 😄
  superHigh, // 🔥
}

extension EnergyLevelX on EnergyLevel {
  String get emoji {
    switch (this) {
      case EnergyLevel.drained:
        return '😫';
      case EnergyLevel.low:
        return '😐';
      case EnergyLevel.medium:
        return '🙂';
      case EnergyLevel.high:
        return '😄';
      case EnergyLevel.superHigh:
        return '🔥';
    }
  }

  String get response {
    switch (this) {
      case EnergyLevel.drained:
        return 'Rest might be what you need right now';
      case EnergyLevel.low:
        return 'Let\'s keep it simple today';
      case EnergyLevel.medium:
        return 'Good energy! Let\'s tackle some tasks';
      case EnergyLevel.high:
        return 'Great energy! Perfect for important stuff';
      case EnergyLevel.superHigh:
        return 'You\'re on fire! Let\'s make the most of it';
    }
  }
}

class EnergyLog {
  final EnergyLevel level;
  final DateTime timestamp;

  const EnergyLog({required this.level, required this.timestamp});

  Map<String, dynamic> toJson() => {
        'level': level.name,
        'timestamp': timestamp.toIso8601String(),
      };

  factory EnergyLog.fromJson(Map<String, dynamic> json) {
    return EnergyLog(
      level: EnergyLevel.values.byName(json['level'] as String),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
