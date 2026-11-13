import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeviceMediaRepository {
  DeviceMediaRepository(this.client);
  final SupabaseClient client;
  final ImagePicker picker = ImagePicker();

  Future<XFile?> pickImage(ImageSource source) async {
    return await picker.pickImage(source: source, imageQuality: 82, maxWidth: 1600);
  }

  Future<String> upload({required XFile file, required String bucket, required String path}) async {
    final bytes = await file.readAsBytes();
    final ext = file.name.contains('.') ? file.name.split('.').last.toLowerCase() : 'jpg';
    final contentType = ext == 'png' ? 'image/png' : 'image/jpeg';
    await client.storage.from(bucket).uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(upsert: true, contentType: contentType),
    );
    return client.storage.from(bucket).getPublicUrl(path);
  }
}
