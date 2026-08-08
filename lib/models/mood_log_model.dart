enum MoodLevel {
  rough, // 😢
  low, // 😔
  okay, // 😐
  good, // 🙂
  great, // 😄
}

extension MoodLevelX on MoodLevel {
  String get emoji {
    switch (this) {
      case MoodLevel.rough:
        return '😢';
      case MoodLevel.low:
        return '😔';
      case MoodLevel.okay:
        return '😐';
      case MoodLevel.good:
        return '🙂';
      case MoodLevel.great:
        return '😄';
    }
  }
}

class MoodLog {
  final MoodLevel mood;
  final DateTime timestamp;

  const MoodLog({required this.mood, required this.timestamp});

  Map<String, dynamic> toJson() => {
        'mood': mood.name,
        'timestamp': timestamp.toIso8601String(),
      };

  factory MoodLog.fromJson(Map<String, dynamic> json) {
    return MoodLog(
      mood: MoodLevel.values.byName(json['mood'] as String),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
