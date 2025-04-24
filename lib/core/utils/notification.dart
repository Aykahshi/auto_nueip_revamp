import 'dart:io' show Platform; // Import Platform

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Global instance of the plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Initialization function
Future<void> initializeNotifications() async {
  // Define Android initialization settings
  // Use the icon file name 'app_icon' (without extension) placed in android/app/src/main/res/drawable
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('app_icon');

  // Define iOS initialization settings
  final DarwinInitializationSettings initializationSettingsIOS =
      const DarwinInitializationSettings(
        requestAlertPermission: true, // Request alert permission
        requestBadgePermission: true, // Request badge permission
        requestSoundPermission: true, // Request sound permission
      );

  // Define overall initialization settings
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
    // macOS settings can be added here if needed
  );

  // Initialize the plugin
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    // This callback is triggered when a notification is tapped
    // and the app is opened or brought to the foreground from the terminated state.
    onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    // This callback is triggered when a notification is tapped
    // and the app is already running in the background.
    onDidReceiveBackgroundNotificationResponse:
        onDidReceiveBackgroundNotificationResponse,
  );

  // Request permissions explicitly on iOS
  if (Platform.isIOS) {
    await _requestIOSPermissions();
  } else if (Platform.isAndroid) {
    // Request POST_NOTIFICATIONS permission on Android 13+
    // The plugin handles requesting SCHEDULE_EXACT_ALARM automatically if needed and declared
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    await androidImplementation
        ?.requestNotificationsPermission(); // Request POST_NOTIFICATIONS
    // await androidImplementation?.requestExactAlarmsPermission(); // Only if you absolutely need SCHEDULE_EXACT_ALARM
  }
}

// Request permissions on iOS
Future<void> _requestIOSPermissions() async {
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >()
      ?.requestPermissions(alert: true, badge: true, sound: true);
}

// Callback for iOS when a notification is received while the app is in the foreground (older iOS versions)
Future<void> onDidReceiveLocalNotification(
  int id,
  String? title,
  String? body,
  String? payload,
) async {
  // Display a dialog, update the UI, etc...
  // This is generally less used now with the foreground presentation options set in AppDelegate
  debugPrint(
    'onDidReceiveLocalNotification: id=$id, title=$title, body=$body, payload=$payload',
  );
}

// Callback when a notification response is received (app was terminated or in background)
void onDidReceiveNotificationResponse(
  NotificationResponse notificationResponse,
) async {
  final String? payload = notificationResponse.payload;
  if (notificationResponse.payload != null) {
    debugPrint('notification payload: $payload');
    // Handle payload, e.g., navigate to a specific screen
  }
  // You can add navigation logic here based on the payload
}

// Callback for background notification response (separate isolate)
// Ensure this function is annotated with @pragma('vm:entry-point')
@pragma('vm:entry-point')
void onDidReceiveBackgroundNotificationResponse(
  NotificationResponse notificationResponse,
) {
  // Handle background notification tap
  final String? payload = notificationResponse.payload;
  debugPrint('background notification payload: $payload');
  // IMPORTANT: Keep this handler lightweight, avoid heavy computation or UI logic.
  // If needed, store information (e.g., in SharedPreferences) and handle it when the app launches.
}

// Function to show a simple notification
Future<void> showSimpleNotification(
  String title,
  String body, {
  String? payload,
}) async {
  // Define Android notification details
  const AndroidNotificationDetails
  androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'your_channel_id', // channel_id: Must match channel created in AndroidManifest (if any) or just be unique
    'your_channel_name', // channel_name
    channelDescription: 'your_channel_description', // channel_description
    importance: Importance.max,
    priority: Priority.high,
    ticker: 'ticker', // Ticker text shown briefly in status bar
    // You can add sound, vibration patterns etc. here
  );

  // Define iOS notification details
  const DarwinNotificationDetails iOSPlatformChannelSpecifics =
      DarwinNotificationDetails(
        presentAlert:
            true, // Present an alert when the notification is delivered
        presentBadge: true, // Update the app icon badge number
        presentSound: true, // Play a sound
        // badgeNumber: 1, // Optional: set a specific badge number
        // You can specify category identifiers for actions etc. here
      );

  // Define overall notification details
  const NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
    iOS: iOSPlatformChannelSpecifics,
  );

  // Show the notification
  await flutterLocalNotificationsPlugin.show(
    0, // Notification ID (must be unique for each notification)
    title,
    body,
    platformChannelSpecifics,
    payload: payload, // Optional payload string
  );
}

// --- Callbacks (Keep as top-level functions for background isolate compatibility) ---

// Callback when a notification response is received (app was terminated or in background)
void _onDidReceiveNotificationResponse(
  NotificationResponse notificationResponse,
) async {
  final String? payload = notificationResponse.payload;
  if (payload != null) {
    debugPrint('Notification payload: $payload');
    // TODO: Implement payload handling, e.g., navigation based on payload
  }
}

// Callback for background notification response (separate isolate)
// Ensure this function is annotated with @pragma('vm:entry-point')
@pragma('vm:entry-point')
void _onDidReceiveBackgroundNotificationResponse(
  NotificationResponse notificationResponse,
) {
  // Handle background notification tap
  final String? payload = notificationResponse.payload;
  debugPrint('Background notification payload: $payload');
  // IMPORTANT: Keep this handler lightweight. Avoid heavy computation or UI logic.
  // Consider using shared_preferences or similar to pass data to the main app instance.
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
      // Optionally, you could attempt initialization here, but it's better practice
      // to ensure initialization happens predictably at app start.
      // await initialize(); // Or throw an error
      return;
    }
    // Define Android notification details
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'auto_nueip', // Unique channel ID
          'Auto Nueip', // Channel name visible in app settings
          channelDescription: 'Auto Nueip notifications',
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
      // badgeNumber: 1, // Optionally set a specific badge number
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
