import 'package:flutter/material.dart';
import '../core/constants.dart';

class TemaSeciciWidget extends StatelessWidget {
  final ThemeMode mevcutMod;
  final int pastelIndex;
  final Future<void> Function(ThemeMode) onMod;
  final Future<void> Function(int) onPastel;

  const TemaSeciciWidget({
    super.key,
    required this.mevcutMod,
    required this.pastelIndex,
    required this.onMod,
    required this.onPastel,
  });

  IconData _modIkon() => switch (mevcutMod) {
        ThemeMode.light => Icons.light_mode,
        ThemeMode.dark => Icons.dark_mode,
        _ => Icons.brightness_auto,
      };

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(_modIkon()),
      tooltip: 'Tema',
      onSelected: (v) {
        if (v == 'light') onMod(ThemeMode.light);
        if (v == 'dark') onMod(ThemeMode.dark);
        if (v == 'system') onMod(ThemeMode.system);
        if (v.startsWith('pastel:')) {
          onPastel(int.parse(v.split(':')[1]));
        }
      },
      itemBuilder: (ctx) => [
        const PopupMenuItem(value: 'light', child: Text('Açık Tema')),
        const PopupMenuItem(value: 'dark', child: Text('Koyu Tema')),
        const PopupMenuItem(value: 'system', child: Text('Sistem Teması')),
        const PopupMenuDivider(),
        for (int i = 0; i < AppConstants.pastelRenkler.length; i++)
          PopupMenuItem(
            value: 'pastel:$i',
            child: Row(children: [
              Container(width: 20, height: 20,
                  decoration: BoxDecoration(
                    color: AppConstants.pastelRenkler[i],
                    shape: BoxShape.circle,
                  )),
              const SizedBox(width: 10),
              Text(AppConstants.pastelAdlari[i]),
              if (i == pastelIndex)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.check, size: 16),
                ),
            ]),
          ),
      ],
    );
  }
}