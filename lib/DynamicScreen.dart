import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DynamicScreen extends StatelessWidget {
  final String docId;

  const DynamicScreen({
    super.key,
    required this.docId,
  });

  @override
  Widget build(BuildContext context) {
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: const Text("Details"),
        backgroundColor: const Color(0xFFCC2222),
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('app_content')
            .doc(docId)
            .get(),

        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFCC2222),
              ),
            );
          }

          // Error / Empty
          if (!snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(
              child: Text("No Data Found"),
            );
          }

          // Firebase Data
          final data =
          snapshot.data!.data() as Map<String, dynamic>;

          final String title = data['title'] ?? '';

          final List sections =
              data['sections'] ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),

            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [
                // Screen Title
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),

                const SizedBox(height: 24),

                // Sections
                ...sections.map((section) {
                  return Padding(
                    padding:
                    const EdgeInsets.only(bottom: 24),

                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,

                      children: [
                        // Heading
                        Text(
                          section['heading'] ?? '',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight:
                            FontWeight.bold,
                            color: textColor,
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Content
                        Text(
                          section['content'] ?? '',
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.7,
                            color:
                            textColor.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }
}