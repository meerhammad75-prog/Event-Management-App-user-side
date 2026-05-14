import 'dart:io';
import 'package:flutter/material.dart';
import '../model/events.dart';

/// Provider that holds form state for the Create Event screen
/// and maintains a list of user-created events.
class CreateEventProvider extends ChangeNotifier {
  // ── Form Controllers ──────────────────────────────────────────────────────
  final TextEditingController titleController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController detailController = TextEditingController();

  // ── Picker State ─────────────────────────────────────────────────────────
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  TimeOfDay? selectedEndTime;
  String? imagePath; // local file path from image_picker

  // ── Validation ────────────────────────────────────────────────────────────
  String? error;
  bool isLoading = false;

  // ── Created Events ────────────────────────────────────────────────────────
  final List<Event> createdEvents = [];

  // ── Setters ───────────────────────────────────────────────────────────────
  void setDate(DateTime date) {
    selectedDate = date;
    notifyListeners();
  }

  void setTime(TimeOfDay time) {
    selectedTime = time;
    notifyListeners();
  }

  void setEndTime(TimeOfDay time) {
    selectedEndTime = time;
    notifyListeners();
  }

  void setImagePath(String path) {
    imagePath = path;
    notifyListeners();
  }

  void clearImage() {
    imagePath = null;
    notifyListeners();
  }

  // ── Validation ────────────────────────────────────────────────────────────
  bool validate() {
    if (titleController.text.trim().isEmpty) {
      error = 'Title is required';
      notifyListeners();
      return false;
    }
    if (selectedDate == null) {
      error = 'Date is required';
      notifyListeners();
      return false;
    }
    if (selectedTime == null) {
      error = 'Time is required';
      notifyListeners();
      return false;
    }
    if (locationController.text.trim().isEmpty) {
      error = 'Location is required';
      notifyListeners();
      return false;
    }
    if (detailController.text.trim().isEmpty) {
      error = 'Event detail is required';
      notifyListeners();
      return false;
    }
    error = null;
    return true;
  }

  // ── Build & Save Event ────────────────────────────────────────────────────
  /// Builds an [Event] from current form state and adds it to [createdEvents].
  /// Returns the new event so callers can add it to HomeScreen's list.
  Event submitEvent() {
    final date = selectedDate!;
    final start = DateTime(
      date.year, date.month, date.day,
      selectedTime!.hour, selectedTime!.minute,
    );
    final end = selectedEndTime != null
        ? DateTime(date.year, date.month, date.day,
        selectedEndTime!.hour, selectedEndTime!.minute)
        : start.add(const Duration(hours: 1));

    // Use local file path as imageUrl; existing _buildImage helpers already
    // handle both http URLs and asset paths — we add file: support in the
    // new screen and reuse the same pattern elsewhere.
    final imageUrl = imagePath ?? 'assets/images/eventimage.png';

    final event = Event(
      title: titleController.text.trim(),
      location: locationController.text.trim(),
      startTime: start,
      endTime: end,
      imageUrl: imageUrl,
    );

    createdEvents.add(event);
    notifyListeners();
    _reset();
    return event;
  }

  // ── Reset ─────────────────────────────────────────────────────────────────
  void _reset() {
    titleController.clear();
    locationController.clear();
    detailController.clear();
    selectedDate = null;
    selectedTime = null;
    selectedEndTime = null;
    imagePath = null;
    error = null;
    isLoading = false;
  }

  @override
  void dispose() {
    titleController.dispose();
    locationController.dispose();
    detailController.dispose();
    super.dispose();
  }
}