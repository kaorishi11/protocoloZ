import 'package:flutter/material.dart';

class StatPanel extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const StatPanel({super.key, required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: const Color(0xFF19231D), borderRadius: BorderRadius.circular(16)),
    child: Row(children: [
      Icon(icon, color: const Color(0xFF9AB47C), size: 25),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Color(0xFFA6ADA7), fontSize: 12)),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
      ])),
    ]),
  );
}
