import 'package:cloudinary_public/cloudinary_public.dart';

class CloudinaryService {
  final cloudinary = CloudinaryPublic(
    "YOUR_CLOUD_NAME",
    "YOUR_UPLOAD_PRESET",
    cache: false,
  );

  Future<String?> uploadImage(String filePath) async {
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          filePath,
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      return response.secureUrl;
    } catch (e) {
      print("Upload failed: $e");
      return null;
    }
  }
}