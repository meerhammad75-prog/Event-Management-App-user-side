import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/cloudinary_service.dart';

class VoteProvider extends ChangeNotifier {
  final questionController = TextEditingController();
  final option1Controller  = TextEditingController();
  final option2Controller  = TextEditingController();

  String? imagePath;   // local file path
  bool    isLoading = false;
  String? error;

  void setImage(String path) { imagePath = path; notifyListeners(); }
  void clearImage()          { imagePath = null; notifyListeners(); }

  bool _validate() {
    if (questionController.text.trim().isEmpty) {
      error = 'Question is required'; return false;
    }
    if (option1Controller.text.trim().isEmpty ||
        option2Controller.text.trim().isEmpty) {
      error = 'Both options are required'; return false;
    }
    error = null;
    return true;
  }

  Future<bool> submitVote() async {
    if (!_validate()) {
      notifyListeners();
      return false;
    }

    isLoading = true;
    notifyListeners();

    try {
      // 1. Upload image to Cloudinary if one was picked
      String imageUrl = 'assets/images/eventimage.png';
      if (imagePath != null) {
        final uploaded = await CloudinaryService.uploadImage(imagePath!);
        if (uploaded != null) imageUrl = uploaded;
      }

      // 2. Save poll to Firestore 'polls' collection
      await FirebaseFirestore.instance.collection('polls').add({
        'question':  questionController.text.trim(),
        'imageUrl':  imageUrl,
        'options': [
          {'text': option1Controller.text.trim(), 'voteCount': '0'},
          {'text': option2Controller.text.trim(), 'voteCount': '0'},
        ],
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Clear form
      questionController.clear();
      option1Controller.clear();
      option2Controller.clear();
      imagePath = null;

      return true;

    } catch (e) {
      error = 'Failed to submit: $e';
      debugPrint('VoteProvider error: $e');
      return false;

    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    questionController.dispose();
    option1Controller.dispose();
    option2Controller.dispose();
    super.dispose();
  }
}