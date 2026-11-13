import 'package:flutter/material.dart';

class HordeAlertBanner extends StatelessWidget {
  final String message;
  const HordeAlertBanner({super.key, required this.message});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: const Color(0xFF4A2020), borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFFC83D3D))),
    child: Row(children: [
      const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF7777), size: 28),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('ALERTA DE HORDA', style: TextStyle(color: Color(0xFFFF9999), fontWeight: FontWeight.bold, letterSpacing: 1)),
        Text(message),
      ])),
    ]),
  );
}
