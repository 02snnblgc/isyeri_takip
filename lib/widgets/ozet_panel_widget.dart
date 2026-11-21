import 'package:flutter/material.dart';

class OzetPanelWidget extends StatelessWidget {
  final int icerideki;
  final int gelmeyen;
  final int erkenCikan;
  final Color? onRenk;

  const OzetPanelWidget({
    super.key,
    required this.icerideki,
    required this.gelmeyen,
    required this.erkenCikan,
    this.onRenk,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _kart(context, Icons.login, 'İçeride', icerideki,
            Colors.green, onRenk),
        const SizedBox(width: 8),
        _kart(context, Icons.person_off, 'Gelmeyen', gelmeyen,
            Colors.orange, onRenk),
        const SizedBox(width: 8),
        _kart(context, Icons.logout, 'Erken Çıkan', erkenCikan,
            Colors.red, onRenk),
      ],
    );
  }

  Widget _kart(BuildContext context, IconData ikon, String etiket,
      int deger, Color renk, Color? onRenk) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: onRenk == null
              ? renk.withOpacity(0.12)
              : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: onRenk == null ? renk.withOpacity(0.4) : Colors.white24,
              width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(ikon, color: onRenk ?? renk, size: 22),
            const SizedBox(height: 6),
            Text('$deger',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: onRenk ?? renk,
                )),
            const SizedBox(height: 2),
            Text(etiket,
                style: TextStyle(
                  fontSize: 11,
                  color: onRenk ?? renk,
                  fontWeight: FontWeight.w600,
                )),
          ],
        ),
      ),
    );
  }
}