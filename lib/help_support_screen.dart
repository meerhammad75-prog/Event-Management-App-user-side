import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ??
            Colors.black;

    return Scaffold(
      backgroundColor:
      Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: const Text("Help & Support"),
        backgroundColor: const Color(0xFFCC2222),
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('app_content')
            .doc('help_support')
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
              child: Text("No Help Data Found"),
            );
          }

          final data =
          snapshot.data!.data() as Map<String, dynamic>;

          final List faqs =
              data['faqs'] ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),

            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [

                // Support Card
                Container(
                  padding: const EdgeInsets.all(18),

                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius:
                    BorderRadius.circular(18),
                  ),

                  child: Column(
                    children: [

                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor:
                          const Color(0xFFCC2222)
                              .withOpacity(0.1),

                          child: const Icon(
                            Icons.email_outlined,
                            color: Color(0xFFCC2222),
                          ),
                        ),

                        title: Text(
                          "Email Support",
                          style: TextStyle(
                            color: textColor,
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),

                        subtitle: Text(
                          data['support_email'] ?? '',
                        ),
                      ),

                      const Divider(),

                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor:
                          const Color(0xFFCC2222)
                              .withOpacity(0.1),

                          child: const Icon(
                            Icons.phone_outlined,
                            color: Color(0xFFCC2222),
                          ),
                        ),

                        title: Text(
                          "Phone Support",
                          style: TextStyle(
                            color: textColor,
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),

                        subtitle: Text(
                          data['support_phone'] ?? '',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // FAQ Title
                Text(
                  "Frequently Asked Questions",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),

                const SizedBox(height: 18),

                // FAQ List
                ...faqs.map((faq) {
                  return Container(
                    margin:
                    const EdgeInsets.only(bottom: 14),

                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius:
                      BorderRadius.circular(16),
                    ),

                    child: ExpansionTile(
                      iconColor:
                      const Color(0xFFCC2222),

                      collapsedIconColor:
                      const Color(0xFFCC2222),

                      title: Text(
                        faq['question'] ?? '',
                        style: TextStyle(
                          fontWeight:
                          FontWeight.w600,
                          color: textColor,
                        ),
                      ),

                      children: [
                        Padding(
                          padding:
                          const EdgeInsets.fromLTRB(
                              16,
                              0,
                              16,
                              16),

                          child: Text(
                            faq['answer'] ?? '',
                            style: TextStyle(
                              height: 1.6,
                              color: textColor
                                  .withOpacity(0.8),
                            ),
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