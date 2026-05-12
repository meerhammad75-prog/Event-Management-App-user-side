import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Scaffold(
      backgroundColor:
      Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: const Text("Terms & Conditions"),
        backgroundColor: const Color(0xFFCC2222),
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('app_content')
            .doc('terms_conditions')
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

          // No Data
          if (!snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(
              child: Text("No Terms Found"),
            );
          }

          final data =
          snapshot.data!.data() as Map<String, dynamic>;

          final List sections =
              data['sections'] ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),

            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [

                ...sections.map((section) {
                  return Padding(
                    padding:
                    const EdgeInsets.only(bottom: 22),

                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,

                      children: [

                        Text(
                          section['heading'] ?? '',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight:
                            FontWeight.bold,
                            color: textColor,
                          ),
                        ),

                        const SizedBox(height: 8),

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