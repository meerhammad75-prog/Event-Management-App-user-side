import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class FcmService {
  static const _projectId = 'eventmanagementapplicati-92181';
  static const _fcmUrl =
      'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send';

  // ── Save FCM token for this user ──────────────────────────────────────────
  static Future<void> saveToken() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'fcmToken': token}, SetOptions(merge: true));

      debugPrint('✅ FCM token saved: $token');
    } catch (e) {
      debugPrint('❌ Error saving FCM token: $e');
    }
  }

  // ── Get OAuth2 access token from service account ──────────────────────────
  static Future<String> _getAccessToken() async {
    final jsonStr = await rootBundle.loadString('assets/service_account.json');
    final json = jsonDecode(jsonStr);

    final credentials = ServiceAccountCredentials.fromJson(json);
    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

    final client = await clientViaServiceAccount(credentials, scopes);
    final token = client.credentials.accessToken.data;
    client.close();
    return token;
  }

  // ── Send notification to a single FCM token ───────────────────────────────
  static Future<void> _sendToToken({
    required String token,
    required String title,
    required String body,
  }) async {
    try {
      final accessToken = await _getAccessToken();

      final response = await http.post(
        Uri.parse(_fcmUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': {
            'token': token,
            'notification': {
              'title': title,
              'body': body,
            },
            'android': {
              'priority': 'high',        // ← priority stays here (message level)
              'notification': {
                'sound': 'default',
                'channel_id': 'poll_notifications',
                // ← removed 'priority' from here, it's not valid in v1 API
              },
            },
          },
        }),
      );

      debugPrint('✅ FCM response status: ${response.statusCode}');
      debugPrint('✅ FCM response body: ${response.body}');
    } catch (e) {
      debugPrint('❌ _sendToToken error: $e');
    }
  }

  // ── Send poll notification to all users ───────────────────────────────────
  static Future<void> sendPollNotificationToAll({
    required String question,
  }) async {
    try {
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      debugPrint('✅ Total users: ${usersSnapshot.docs.length}');

      final tokens = usersSnapshot.docs
          .map((doc) => doc.data()['fcmToken'] as String?)
          .where((token) => token != null && token.isNotEmpty)
          .cast<String>()
          .toList();

      debugPrint('✅ Found ${tokens.length} FCM tokens');
      for (final t in tokens) {
        debugPrint('✅ Token: $t');
      }

      if (tokens.isEmpty) {
        debugPrint('❌ No tokens found — saveToken() may not have run');
        return;
      }

      for (final token in tokens) {
        await _sendToToken(
          token: token,
          title: '🗳️ New Poll Available!',
          body: '$question — cast your vote!',
        );
      }
    } catch (e) {
      debugPrint('❌ Error sending poll notifications: $e');
    }
  }
}