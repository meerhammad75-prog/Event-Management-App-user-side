import 'dart:io';
import 'package:eventmanagementapp/providers/vote%20provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class VoteScreen extends StatelessWidget {
  const VoteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => VoteProvider(),
      child: const _VoteScreenContent(),
    );
  }
}

class _VoteScreenContent extends StatelessWidget {
  const _VoteScreenContent();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Vote',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        titleSpacing: 0,
      ),
      body: const _VoteBody(),
    );
  }
}

class _VoteBody extends StatelessWidget {
  const _VoteBody();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VoteProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionLabel(text: 'Question', isDark: isDark),
                const SizedBox(height: 8),
                _InputField(
                  controller: provider.questionController,
                  hintText: 'Made in Melanin! Black History Month Social',
                  isDark: isDark,
                ),
                const SizedBox(height: 24),

                _SectionLabel(text: 'Options', isDark: isDark),
                const SizedBox(height: 8),
                _InputField(
                  controller: provider.option1Controller,
                  hintText: 'Option 1',
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _InputField(
                  controller: provider.option2Controller,
                  hintText: 'Option 2',
                  isDark: isDark,
                ),
                const SizedBox(height: 24),

                _SectionLabel(text: 'Upload Image', isDark: isDark),
                const SizedBox(height: 8),
                _ImageUploadBox(isDark: isDark),
              ],
            ),
          ),
        ),

        Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            top: 12,
          ),
          child: const _VoteButton(),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  const _SectionLabel({required this.text, required this.isDark});

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

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool isDark;

  const _InputField({
    required this.controller,
    required this.hintText,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final fieldFill = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final borderColor =
    isDark ? Colors.grey.shade700 : const Color(0xFFE0E0E0);
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor =
    isDark ? Colors.grey.shade600 : const Color(0xFFAAAAAA);

    return TextFormField(
      controller: controller,
      style: TextStyle(fontSize: 14, color: textColor),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(fontSize: 14, color: hintColor),
        filled: true,
        fillColor: fieldFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
          const BorderSide(color: Color(0xFFCC2222), width: 1.5),
        ),
      ),
    );
  }
}

class _ImageUploadBox extends StatelessWidget {
  final bool isDark;
  const _ImageUploadBox({required this.isDark});

  Future<void> _pickImage(BuildContext context) async {
    final provider = context.read<VoteProvider>();
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      provider.setImage(picked.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VoteProvider>();
    final imagePath = provider.imagePath;
    final fieldFill = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final borderColor =
    isDark ? Colors.grey.shade700 : const Color(0xFFE0E0E0);
    final iconColor = isDark ? Colors.grey.shade400 : Colors.black54;

    return GestureDetector(
      onTap: () => _pickImage(context),
      child: Container(
        width: 130,
        height: 120,
        decoration: BoxDecoration(
          color: fieldFill,
          border: Border.all(color: borderColor, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: imagePath != null
            ? ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Stack(
            children: [
              Image.file(
                File(imagePath),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: () => provider.clearImage(),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(3),
                    child: const Icon(Icons.close,
                        color: Colors.white, size: 14),
                  ),
                ),
              ),
            ],
          ),
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.upload, size: 32, color: iconColor),
            const SizedBox(height: 6),
            Text(
              'Upload',
              style: TextStyle(fontSize: 14, color: iconColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _VoteButton extends StatelessWidget {
  const _VoteButton();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VoteProvider>();

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: provider.isLoading
            ? null
            : () async {
          final success = await provider.submitVote();
          if (!context.mounted) return;

          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Poll created successfully!'),
                backgroundColor: Color(0xFFCC2222),
              ),
            );
            Navigator.pop(context); // go back to admin screen
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(provider.error ?? 'Something went wrong'),
                backgroundColor: Colors.red[900],
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFCC2222),
          disabledBackgroundColor:
          const Color(0xFFCC2222).withOpacity(0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: provider.isLoading
            ? const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : const Text(
          'Vote',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}