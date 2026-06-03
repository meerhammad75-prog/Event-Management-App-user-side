import 'dart:io';
import 'package:eventmanagementapp/providers/create%20event%20provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'home.dart';
import 'model/events.dart';

class CreateEventScreen extends StatelessWidget {
  final void Function(Event event)? onEventCreated;

  const CreateEventScreen({super.key, this.onEventCreated});

  Future<void> _pickDate(BuildContext context, CreateEventProvider p) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final picked = await showDatePicker(
      context: context,
      initialDate: p.selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: isDark
              ? const ColorScheme.dark(
            primary: Color(0xFFCF3232),
            onPrimary: Colors.white,
          )
              : const ColorScheme.light(
            primary: Color(0xFFCF3232),
            onPrimary: Colors.white,
            onSurface: Colors.black87,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) p.setDate(picked);
  }

  Future<void> _pickTime(
      BuildContext context, CreateEventProvider p, {bool isEnd = false}) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initial = isEnd
        ? (p.selectedEndTime ?? TimeOfDay.now())
        : (p.selectedTime ?? TimeOfDay.now());

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: isDark
              ? const ColorScheme.dark(
            primary: Color(0xFFCF3232),
            onPrimary: Colors.white,
          )
              : const ColorScheme.light(
            primary: Color(0xFFCF3232),
            onPrimary: Colors.white,
            onSurface: Colors.black87,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      isEnd ? p.setEndTime(picked) : p.setTime(picked);
    }
  }

  Future<void> _showImageOptions(
      BuildContext context, CreateEventProvider p) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: Color(0xFFCF3232)),
              title: Text('Take a photo',
                  style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87)),
              onTap: () async {
                Navigator.pop(context);
                await _getImage(context, p, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: Color(0xFFCF3232)),
              title: Text('Choose from gallery',
                  style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87)),
              onTap: () async {
                Navigator.pop(context);
                await _getImage(context, p, ImageSource.gallery);
              },
            ),
            if (p.imagePath != null)
              ListTile(
                leading:
                const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Remove image',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  p.clearImage();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _getImage(
      BuildContext context, CreateEventProvider p, ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (picked != null) p.setImagePath(picked.path);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick image: $e')),
        );
      }
    }
  }

// Replace the existing _submit method with this:
  Future<void> _submit(BuildContext context, CreateEventProvider p) async {
    if (!p.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(p.error ?? 'Please fill all fields'),
          backgroundColor: Colors.red[700],
        ),
      );
      return;
    }

    try {
      final event = await p.submitEvent(); // now async
      onEventCreated?.call(event);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event created successfully!'),
          backgroundColor: Color(0xFFCF3232),
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            themeNotifier: ValueNotifier(ThemeMode.light),
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create event: $e'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }
  String _formatDate(DateTime? d) =>
      d == null ? '' : '${d.day}/${d.month}/${d.year}';

  String _formatTime(TimeOfDay? t) {
    if (t == null) return '';
    final h = t.hour > 12
        ? t.hour - 12
        : (t.hour == 0 ? 12 : t.hour);
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return ChangeNotifierProvider(
      create: (_) => CreateEventProvider(),
      child: Consumer<CreateEventProvider>(
        builder: (context, p, _) => Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: textColor),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Create Event',
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Label('Title', isDark: isDark),
                const SizedBox(height: 8),
                _Field(
                  controller: p.titleController,
                  hint: 'Made in Melanin! Black History Month Social',
                  isDark: isDark,
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Label('Date', isDark: isDark),
                          const SizedBox(height: 8),
                          _Tappable(
                            value: _formatDate(p.selectedDate),
                            hint: 'DD/MM/YYYY',
                            icon: Icons.calendar_today_outlined,
                            onTap: () => _pickDate(context, p),
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Label('Time', isDark: isDark),
                          const SizedBox(height: 8),
                          _Tappable(
                            value: _formatTime(p.selectedTime),
                            hint: '12:00 PM',
                            icon: Icons.access_time_outlined,
                            onTap: () => _pickTime(context, p),
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                _Label('Location', isDark: isDark),
                const SizedBox(height: 8),
                _Field(
                  controller: p.locationController,
                  hint: '1901 Thornridge Cir. Shiloh, Hawaii 81063',
                  isDark: isDark,
                ),

                const SizedBox(height: 20),

                _Label('Event Detail', isDark: isDark),
                const SizedBox(height: 8),
                _Field(
                  controller: p.detailController,
                  hint:
                  'Lorem ipsum dolor sit amet consectetur. Lectus viverra '
                      'fermentum natoque nibh enim aliquam tincidunt eu purus...',
                  maxLines: 6,
                  minLines: 5,
                  isDark: isDark,
                ),

                const SizedBox(height: 20),

                _Label('Upload Image', isDark: isDark),
                const SizedBox(height: 8),
                _ImageBox(
                  imagePath: p.imagePath,
                  onTap: () => _showImageOptions(context, p),
                  isDark: isDark,
                ),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child:
// Replace the ElevatedButton in build() with this:
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: p.isLoading ? null : () => _submit(context, p),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFCF3232),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: p.isLoading
                          ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                          : const Text(
                        'Create Event',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Reusable Widgets ──────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  final bool isDark;
  const _Label(this.text, {required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int? maxLines;
  final int? minLines;
  final bool isDark;

  const _Field({
    required this.controller,
    required this.hint,
    required this.isDark,
    this.maxLines = 1,
    this.minLines,
  });

  @override
  Widget build(BuildContext context) {
    final fieldFill = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final borderColor =
    isDark ? Colors.grey.shade700 : Colors.grey.shade300;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.grey.shade600 : Colors.grey.shade400;

    return TextField(
      controller: controller,
      maxLines: maxLines,
      minLines: minLines,
      style: TextStyle(fontSize: 14, color: textColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 14, color: hintColor),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        filled: true,
        fillColor: fieldFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFCF3232), width: 1.5),
        ),
      ),
    );
  }
}

class _Tappable extends StatelessWidget {
  final String value;
  final String hint;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  const _Tappable({
    required this.value,
    required this.hint,
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final fieldFill = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final borderColor =
    isDark ? Colors.grey.shade700 : Colors.grey.shade300;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.grey.shade600 : Colors.grey.shade400;
    final iconColor = isDark ? Colors.grey.shade400 : Colors.grey.shade500;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: fieldFill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value.isEmpty ? hint : value,
                style: TextStyle(
                  fontSize: 13,
                  color: value.isEmpty ? hintColor : textColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(icon, size: 18, color: iconColor),
          ],
        ),
      ),
    );
  }
}

class _ImageBox extends StatelessWidget {
  final String? imagePath;
  final VoidCallback onTap;
  final bool isDark;

  const _ImageBox({
    this.imagePath,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final fieldFill = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final borderColor =
    isDark ? Colors.grey.shade700 : Colors.grey.shade300;
    final iconColor = isDark ? Colors.grey.shade400 : Colors.grey.shade500;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        height: 110,
        decoration: BoxDecoration(
          color: fieldFill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: imagePath != null
            ? ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(File(imagePath!), fit: BoxFit.cover),
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.edit,
                      color: Colors.white, size: 14),
                ),
              ),
            ],
          ),
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.upload_outlined, size: 30, color: iconColor),
            const SizedBox(height: 6),
            Text(
              'Upload',
              style: TextStyle(fontSize: 13, color: iconColor),
            ),
          ],
        ),
      ),
    );
  }
}