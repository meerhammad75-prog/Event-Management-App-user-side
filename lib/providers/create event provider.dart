import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../model/events.dart';
import '../services/cloudinary_service.dart';

class CreateEventProvider extends ChangeNotifier {
  // ── Form Controllers ──────────────────────────────────────────────────────
  final TextEditingController titleController    = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController detailController   = TextEditingController();

  // ── Picker State ──────────────────────────────────────────────────────────
  DateTime?  selectedDate;
  TimeOfDay? selectedTime;
  TimeOfDay? selectedEndTime;
  String?    imagePath; // local file path from image_picker

  // ── Status ────────────────────────────────────────────────────────────────
  String? error;
  bool    isLoading = false;

  // ── Created Events (local cache) ──────────────────────────────────────────
  final List<Event> createdEvents = [];

  // ── Setters ───────────────────────────────────────────────────────────────
  void setDate(DateTime date)      { selectedDate    = date;  notifyListeners(); }
  void setTime(TimeOfDay time)     { selectedTime    = time;  notifyListeners(); }
  void setEndTime(TimeOfDay time)  { selectedEndTime = time;  notifyListeners(); }
  void setImagePath(String path)   { imagePath       = path;  notifyListeners(); }
  void clearImage()                { imagePath       = null;  notifyListeners(); }

  // ── Validation ────────────────────────────────────────────────────────────
  bool validate() {
    if (titleController.text.trim().isEmpty) {
      error = 'Title is required';        notifyListeners(); return false;
    }
    if (selectedDate == null) {
      error = 'Date is required';         notifyListeners(); return false;
    }
    if (selectedTime == null) {
      error = 'Time is required';         notifyListeners(); return false;
    }
    if (locationController.text.trim().isEmpty) {
      error = 'Location is required';     notifyListeners(); return false;
    }
    if (detailController.text.trim().isEmpty) {
      error = 'Event detail is required'; notifyListeners(); return false;
    }
    error = null;
    return true;
  }

  // ── Submit: Cloudinary + Firestore ────────────────────────────────────────
  Future<Event> submitEvent() async {
    isLoading = true;
    notifyListeners();

    try {
      // 1. Upload image to Cloudinary if user picked one
      String imageUrl = 'assets/images/eventimage.png';
      if (imagePath != null) {
        final uploaded = await CloudinaryService.uploadImage(imagePath!);
        if (uploaded != null) {
          imageUrl = uploaded;
        } else {
          debugPrint('Cloudinary upload returned null, using fallback image');
        }
      }

      // 2. Build date/time objects
      final date  = selectedDate!;
      final start = DateTime(
        date.year, date.month, date.day,
        selectedTime!.hour, selectedTime!.minute,
      );
      final end = selectedEndTime != null
          ? DateTime(date.year, date.month, date.day,
          selectedEndTime!.hour, selectedEndTime!.minute)
          : start.add(const Duration(hours: 1));

      final title    = titleController.text.trim();
      final location = locationController.text.trim();
      final detail   = detailController.text.trim();
      final uid      = FirebaseAuth.instance.currentUser?.uid ?? '';

      // 3. Save to Firestore 'events' collection
      final docRef = await FirebaseFirestore.instance
          .collection('events')
          .add({
        'title':      title,
        'location':   location,
        'detail':     detail,
        'imageUrl':   imageUrl,
        'date':       Timestamp.fromDate(date),
        'startTime':  Timestamp.fromDate(start),
        'endTime':    Timestamp.fromDate(end),
        'createdBy':  uid,
        'createdAt':  FieldValue.serverTimestamp(),
      });

      debugPrint('Event saved to Firestore: ${docRef.id}');

      // 4. Build local Event model
      final event = Event(
        title:     title,
        location:  location,
        startTime: start,
        endTime:   end,
        imageUrl:  imageUrl,
      );

      createdEvents.add(event);
      _reset();
      return event;

    } catch (e) {
      error = 'Failed to create event: $e';
      debugPrint('CreateEventProvider error: $e');
      rethrow; // let the screen handle it
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── Reset ─────────────────────────────────────────────────────────────────
  void _reset() {
    titleController.clear();
    locationController.clear();
    detailController.clear();
    selectedDate    = null;
    selectedTime    = null;
    selectedEndTime = null;
    imagePath       = null;
    error           = null;
  }

  @override
  void dispose() {
    titleController.dispose();
    locationController.dispose();
    detailController.dispose();
    super.dispose();
  }
}