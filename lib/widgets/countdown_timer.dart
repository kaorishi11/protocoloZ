import 'dart:async';
import 'package:flutter/material.dart';

class CountdownTimer extends StatefulWidget {
  final DateTime endsAt;
  const CountdownTimer({super.key, required this.endsAt});
  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late Timer _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() { super.initState(); _update(); _timer = Timer.periodic(const Duration(seconds: 1), (_) => _update()); }
  void _update() {
    final d = widget.endsAt.difference(DateTime.now());
    if (mounted) setState(() => _remaining = d.isNegative ? Duration.zero : d);
  }
  @override
  void dispose() { _timer.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final h = _remaining.inHours.toString().padLeft(2, '0');
    final m = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return Text('$h:$m:$s', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 2));
  }
}
