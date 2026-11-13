import 'package:flutter/material.dart';

class FactionBadge extends StatelessWidget {
  final String symbol;
  final String colorHex;
  const FactionBadge({super.key, required this.symbol, required this.colorHex});

  Color get _color {
    final value = colorHex.replaceFirst('#', '');
    return Color(int.parse('FF$value', radix: 16));
  }

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: 25, backgroundColor: _color.withValues(alpha: .18),
    child: Text(symbol, style: TextStyle(color: _color, fontSize: 24)),
  );
}
