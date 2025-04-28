import 'dart:io' show Platform; // Import Platform

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// --- Callbacks (Keep as top-level functions for background isolate compatibility) ---

// Callback when a notification response is received (app was terminated or in background)
void _onDidReceiveNotificationResponse(
  NotificationResponse notificationResponse,
) async {
  final String? payload = notificationResponse.payload;
  if (payload != null) {
    debugPrint('Notification payload: $payload');
  }
}

@pragma('vm:entry-point')
void _onDidReceiveBackgroundNotificationResponse(
  NotificationResponse notificationResponse,
) {
  // Handle background notification tap
  final String? payload = notificationResponse.payload;
  debugPrint('Background notification payload: $payload');
}

/// Utility class for handling local notifications.
sealed class NotificationUtils {
  const NotificationUtils._();

  // Private static instance of the plugin
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // Flag to ensure initialization happens only once
  static bool _isInitialized = false;

  /// Initializes the local notifications plugin and requests permissions.
  /// Should be called once during app startup (e.g., in main()).
  static Future<void> init() async {
    if (_isInitialized) {
      debugPrint("NotificationUtils already initialized.");
      return;
    }

    // Define Android initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings(
          'app_icon',
        ); // Use app_icon.png in drawable

    // Define iOS initialization settings
    // Permissions are requested separately below for clarity
    // The onDidReceiveLocalNotification callback is less relevant now
    // as foreground presentation is handled in AppDelegate.swift
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          // No need for onDidReceiveLocalNotification here anymore.
          // Foreground presentation is configured in AppDelegate.swift.
        );

    // Define overall initialization settings
    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
          // macOS settings can be added here if needed
        );

    // Initialize the plugin with callbacks
    await _plugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          _onDidReceiveBackgroundNotificationResponse,
    );

    // Request permissions after initialization
    await _requestPermissions();

    _isInitialized = true;
    debugPrint("NotificationUtils initialized successfully.");
  }

  /// Requests notification permissions for the current platform.
  static Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      // Request POST_NOTIFICATIONS permission on Android 13+
      await androidImplementation?.requestNotificationsPermission();
      // Uncomment below ONLY if you absolutely need SCHEDULE_EXACT_ALARM
      // and have handled the Google Play policy implications.
      // await androidImplementation?.requestExactAlarmsPermission();
    }
  }

  /// Shows a simple notification.
  ///
  /// [id] must be a unique integer for each distinct notification.
  /// [title] is the notification title.
  /// [body] is the main content of the notification.
  /// [payload] is an optional String payload to pass data when the notification is tapped.
  static Future<void> showSimpleNotification(
    int id, // Make ID required for clarity
    String title,
    String body, {
    String? payload,
  }) async {
    if (!_isInitialized) {
      debugPrint(
        "Error: NotificationUtils not initialized. Call initialize() first.",
      );
      return;
    }
    // Define Android notification details
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'auto_nueip', // Unique channel ID
          'Auto Nueip', // Channel name visible in app settings
          channelDescription: 'Auto Nueip notifications',
          largeIcon: DrawableResourceAndroidBitmap('app_large_icon'),
          importance: Importance.max, // High importance for visibility
          priority: Priority.max, // High priority
          ticker: 'NUEIP', // Ticker text (briefly shown in status bar)
        );

    // Define iOS notification details
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert:
          true, // Show alert even if app is in foreground (handled by AppDelegate)
      presentBadge: true, // Update the app icon badge
      presentSound: true, // Play sound
    );

    // Define overall notification details
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Show the notification using the plugin instance
    await _plugin.show(
      id, // Use the provided unique notification ID
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }

  /// Cancels a specific notification by its ID.
  static Future<void> cancelNotification(int id) async {
    if (!_isInitialized) {
      debugPrint("Error: NotificationUtils not initialized.");
      return;
    }
    await _plugin.cancel(id);
    debugPrint("Cancelled notification with id: $id");
  }

  /// Cancels all notifications shown by the app.
  static Future<void> cancelAllNotifications() async {
    if (!_isInitialized) {
      debugPrint("Error: NotificationUtils not initialized.");
      return;
    }
    await _plugin.cancelAll();
    debugPrint("Cancelled all notifications.");
  }
}
