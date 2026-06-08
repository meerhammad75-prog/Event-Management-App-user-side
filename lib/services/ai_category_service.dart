import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';


class AiCategoryService {
static String get _apiKey =>
dotenv.env['GROQ_API_KEY'] ?? '';  static const _categories = [
    'Religious', 'Business', 'Fitness', 'Education', 'Community', 'Other'
  ];

  static Future<String> categorize(String title, String detail) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant',
          'max_tokens': 10,
          'messages': [
            {
              'role': 'system',
              'content': 'You are an event categorizer. Reply with only one category name, nothing else.'
            },
            {
              'role': 'user',
              'content': '''Choose exactly one from: ${_categories.join(', ')}.

Event title: $title
Event detail: $detail

Category:'''
            }
          ],
        }),
      );

      debugPrint('Groq response status: ${response.statusCode}');
      debugPrint('Groq response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final raw = data['choices'][0]['message']['content'].trim();
        final match = _categories.firstWhere(
              (c) => c.toLowerCase() == raw.toLowerCase(),
          orElse: () => 'Other',
        );
        return match;
      }
    } catch (e) {
      debugPrint('AI categorization failed: $e');
    }
    debugPrint('Returning Other as fallback');
    return 'Other';
  }
}