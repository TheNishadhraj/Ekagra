import 'package:flutter/material.dart';

import '../../config/theme.dart';

enum AmbientSound { rain, lofi, cafe, ocean, fireplace, forest, none }

class AmbientPlayerSheet extends StatefulWidget {
  final AmbientSound currentSound;
  final ValueChanged<AmbientSound> onSelected;

  const AmbientPlayerSheet({
    super.key,
    required this.currentSound,
    required this.onSelected,
  });

  static Future<void> show(
    BuildContext context,
    AmbientSound current,
    ValueChanged<AmbientSound> onSelected,
  ) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => AmbientPlayerSheet(
        currentSound: current,
        onSelected: onSelected,
      ),
    );
  }

  @override
  State<AmbientPlayerSheet> createState() => _AmbientPlayerSheetState();
}

class _AmbientPlayerSheetState extends State<AmbientPlayerSheet> {
  late AmbientSound _selected;

  final _sounds = const [
    _SoundOption(AmbientSound.rain, '🌧️', 'Rain', 'Gentle rain without thunder'),
    _SoundOption(AmbientSound.lofi, '🎵', 'Lofi Beats', 'Chill instrumental beats'),
    _SoundOption(AmbientSound.cafe, '☕', 'Café', 'Coffee shop background ambiance'),
    _SoundOption(AmbientSound.ocean, '🌊', 'Ocean Waves', 'Calming ocean waves'),
    _SoundOption(AmbientSound.fireplace, '🔥', 'Fireplace', 'Warm crackling fireplace'),
    _SoundOption(AmbientSound.forest, '🌲', 'Forest', 'Birds & gentle nature sounds'),
    _SoundOption(AmbientSound.none, '🔇', 'None', 'Silent focus mode'),
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.currentSound;
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
      padding: const EdgeInsets.all(EkagraSpacing.lg),
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

          Text('Ambient Focus Sounds 🎧', style: EkagraTypography.h3),
          const SizedBox(height: 4),
          Text(
            'Background audio helps ADHD brains stay in the zone.',
            style: EkagraTypography.caption,
          ),
          const SizedBox(height: EkagraSpacing.lg),

          ..._sounds.map((opt) {
            final isSel = _selected == opt.sound;
            return ListTile(
              onTap: () {
                setState(() => _selected = opt.sound);
                widget.onSelected(opt.sound);
                Navigator.pop(context);
              },
              leading: Text(opt.emoji, style: const TextStyle(fontSize: 24)),
              title: Text(opt.label, style: EkagraTypography.bodyBold),
              subtitle: Text(opt.subtitle, style: EkagraTypography.tiny),
              trailing: isSel
                  ? const Icon(Icons.check_circle_rounded, color: EkagraColors.primary)
                  : null,
            );
          }),
          const SizedBox(height: EkagraSpacing.md),
        ],
      ),
    );
  }
}

class _SoundOption {
  final AmbientSound sound;
  final String emoji;
  final String label;
  final String subtitle;

  const _SoundOption(this.sound, this.emoji, this.label, this.subtitle);
}
