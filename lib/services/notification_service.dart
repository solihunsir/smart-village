import 'package:desaku/utils/app_logger.dart';
import 'package:flutter/material.dart';
import '../services/post_service.dart';

class NotificationService {
  Future<bool> hasNewActivityNotifications() async {
    try {
      final myPostsSummary = await PostService.fetchMyPostsActivitySummary();

      return myPostsSummary.isNotEmpty;
    } catch (e) {
      AppLogger.log('Error fetching notification status: $e');
      return false;
    }
  }
}
