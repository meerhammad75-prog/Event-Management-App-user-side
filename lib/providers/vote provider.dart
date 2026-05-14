import 'package:flutter/material.dart';

class VoteProvider extends ChangeNotifier {
  final TextEditingController questionController = TextEditingController();
  final TextEditingController option1Controller = TextEditingController();
  final TextEditingController option2Controller = TextEditingController();

  String? _imagePath;
  bool _isLoading = false;

  String? get imagePath => _imagePath;
  bool get isLoading => _isLoading;

  void setImage(String path) {
    _imagePath = path;
    notifyListeners();
  }

  void clearImage() {
    _imagePath = null;
    notifyListeners();
  }

  bool get isValid {
    return questionController.text.trim().isNotEmpty &&
        option1Controller.text.trim().isNotEmpty &&
        option2Controller.text.trim().isNotEmpty;
  }

  Future<void> submitVote() async {
    if (!isValid) return;

    _isLoading = true;
    notifyListeners();

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    _isLoading = false;
    notifyListeners();
  }

  void reset() {
    questionController.clear();
    option1Controller.clear();
    option2Controller.clear();
    _imagePath = null;
    notifyListeners();
  }

  @override
  void dispose() {
    questionController.dispose();
    option1Controller.dispose();
    option2Controller.dispose();
    super.dispose();
  }
}