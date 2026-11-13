import 'package:flutter/material.dart';

class ItemTile extends StatelessWidget {
  final String name;
  final String category;
  final String icon;
  final int quantity;
  const ItemTile({super.key, required this.name, required this.category, required this.icon, required this.quantity});

  @override
  Widget build(BuildContext context) => ListTile(
    leading: CircleAvatar(backgroundColor: const Color(0xFF29382D), child: Text(icon, style: const TextStyle(fontSize: 21))),
    title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
    subtitle: Text(category, style: const TextStyle(color: Color(0xFFA6ADA7))),
    trailing: Text('x$quantity', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
  );
}
