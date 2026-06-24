import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/cloudinary_service.dart';
import '../services/fcm_service.dart';
import '../services/notification_service.dart';

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

      // 2. Save poll to Firestore
      final pollRef = await FirebaseFirestore.instance.collection('polls').add({
        'question': questionController.text.trim(),
        'imageUrl': imageUrl,
        'options': [
          {'text': option1Controller.text.trim(), 'voteCount': 0},
          {'text': option2Controller.text.trim(), 'voteCount': 0},
        ],
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Notify all users about the new poll
      await _notifyAllUsers(
        pollId: pollRef.id,
        question: questionController.text.trim(),
      );

      // 4. Clear form
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

  Future<void> _notifyAllUsers({
    required String pollId,
    required String question,
  }) async {
    try {
      debugPrint('🗳️ _notifyAllUsers called for poll: $pollId');

      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      final now = DateTime.now();
      final timeStr = _formatTime(now);
      final docId = 'poll_$pollId';

      // Save to each user's notification screen
      final batch = FirebaseFirestore.instance.batch();
      for (final userDoc in usersSnapshot.docs) {
        final notifRef = FirebaseFirestore.instance
            .collection('users')
            .doc(userDoc.id)
            .collection('notifications')
            .doc(docId);

        batch.set(notifRef, {
          'id': docId,
          'message': '🗳️ New poll: "$question" — cast your vote!',
          'eventId': '',
          'time': timeStr,
          'isRead': false,
          'scheduledFor': Timestamp.fromDate(now),
          'type': 'poll',
          'pollId': pollId,
        });
      }
      await batch.commit();
      debugPrint('🗳️ Firestore notifications saved');

      // Send FCM push to all devices
      await FcmService.sendPollNotificationToAll(question: question);

    } catch (e) {
      debugPrint('🗳️ ERROR in _notifyAllUsers: $e');
    }
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${dt.minute.toString().padLeft(2, '0')} $period';
  }
  @override
  void dispose() {
    questionController.dispose();
    option1Controller.dispose();
    option2Controller.dispose();
    super.dispose();
  }
}