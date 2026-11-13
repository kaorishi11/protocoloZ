import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
class ImageSourceSheet extends StatelessWidget {
  const ImageSourceSheet({super.key});
  static Future<ImageSource?> show(BuildContext context) => showModalBottomSheet<ImageSource>(
    context: context, backgroundColor: const Color(0xFF19231D), builder: (_) => const ImageSourceSheet(),
  );
  @override
  Widget build(BuildContext context) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Padding(padding: EdgeInsets.all(16), child: Text('Selecionar imagem', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
    ListTile(leading: const Icon(Icons.camera_alt_outlined), title: const Text('Tirar foto'), onTap: () => Navigator.pop(context, ImageSource.camera)),
    ListTile(leading: const Icon(Icons.photo_library_outlined), title: const Text('Escolher da galeria'), onTap: () => Navigator.pop(context, ImageSource.gallery)),
  ]));
}
