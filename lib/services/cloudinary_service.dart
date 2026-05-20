import 'package:cloudinary_public/cloudinary_public.dart';

class CloudinaryService {
  static final _cloudinary = CloudinaryPublic(
    "dvhhlesbl",
    "eventapp",
    cache: false,
  );

  static Future<String?> uploadImage(String filePath) async {
    try {
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          filePath,
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      return response.secureUrl;
    } catch (e) {
      if (e is CloudinaryException) {
        print("Cloudinary error: ${e.message}"); // exact reason from server
        print("Request: ${e.request}");
      } else {
        print("Upload failed: $e");
      }
      return null;
    }
  }
}