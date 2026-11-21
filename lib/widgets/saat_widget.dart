import 'dart:async';
import 'package:flutter/material.dart';
import '../core/utils/tarih_util.dart';

class SaatWidget extends StatefulWidget {
  final bool buyuk;
  final Color? renk;
  const SaatWidget({super.key, this.buyuk = false, this.renk});

  @override
  State<SaatWidget> createState() => _SaatWidgetState();
}

class _SaatWidgetState extends State<SaatWidget> {
  late Timer _timer;
  DateTime _simdi = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _simdi = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stil = widget.buyuk
        ? Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w700, color: widget.renk)
        : Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600, color: widget.renk);
    final altStil = widget.buyuk
        ? Theme.of(context).textTheme.titleMedium?.copyWith(
            color: widget.renk)
        : Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: widget.renk);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(TarihUtil.saatStr(_simdi), style: stil),
        Text(TarihUtil.uzunTarihStr(_simdi), style: altStil),
      ],
    );
  }
}