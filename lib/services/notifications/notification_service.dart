import 'dart:io';
import 'dart:math';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<NotificationSettings> requestNotificationPermissions(
    BuildContext context,
  ) async {
    try {
      NotificationSettings settings = await FirebaseMessaging.instance
          .requestPermission(
            alert: true,
            announcement: true,
            carPlay: false,
            badge: true,
            criticalAlert: true,
            provisional: false,
            sound: true,
          );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print("User granted notification permission");
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        print("User granted provisional permission");

        // Consider prompting user to upgrade to full permissions
      } else {
        print("User denied permission");
      }
      return settings;
    } catch (e) {
      print("Error requesting notification permissions: $e");

      // Provide default or fallback values for all parameters
      return const NotificationSettings(
        authorizationStatus: AuthorizationStatus.denied,
        alert: AppleNotificationSetting.disabled,
        announcement: AppleNotificationSetting.disabled,
        badge: AppleNotificationSetting.disabled,
        carPlay: AppleNotificationSetting.disabled,
        criticalAlert: AppleNotificationSetting.disabled,
        lockScreen: AppleNotificationSetting.disabled,
        notificationCenter: AppleNotificationSetting.disabled,
        showPreviews: AppleShowPreviewSetting.notSupported,
        sound: AppleNotificationSetting.disabled,
        timeSensitive: AppleNotificationSetting.disabled,
        providesAppNotificationSettings: AppleNotificationSetting.enabled,
      );
    }
  }

  void initLocalNotifications(
    BuildContext context,
    RemoteMessage message,
  ) async {
    var androidInitialization = AndroidInitializationSettings(
      "ic_notification",
    );
    var iosInitialization = DarwinInitializationSettings();

    var initializationSettings = InitializationSettings(
      android: androidInitialization,
      iOS: iosInitialization,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (payload) {},
    );
  }

  void firebaseInit() {
    FirebaseMessaging.onMessage.listen((message) {
      if (kDebugMode) {
        print("notification title ========> ${message.notification?.title}");
        print("notification title ========> ${message.notification?.body}");
      }
      showNotification(message);
    });
  }

  Future<void> showNotification(RemoteMessage message) async {
    AndroidNotificationChannel channel = AndroidNotificationChannel(
      Random.secure().nextInt(100000).toString(),
      "High Importance",
      importance: Importance.high,
    );
    AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: "High Importance",
          importance: Importance.high,
          priority: Priority.high,
          ticker: 'ticker',
          icon: 'ic_notification',
        );

    DarwinNotificationDetails darwinNotificationDetails =
        DarwinNotificationDetails();

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
    );
    Future.delayed(Duration.zero, () {
      _flutterLocalNotificationsPlugin.show(
        0,
        message.notification?.title.toString(),
        message.notification?.body.toString(),
        notificationDetails,
      );
    });
  }

  Future<String?> getDeviceToken() async {
    try {
      if (Platform.isIOS) {
        String? token = await firebaseMessaging.getAPNSToken();
        if (token == null) {
          print("APNs token is null");
          return null; // Or throw an exception
        }
        return token;
      } else {
        String? token = await firebaseMessaging.getToken();
        if (token == null) {
          print("FCM token is null");
          return null; // Or throw an exception
        }
        return token;
      }
    } catch (e) {
      print("Error getting device token: $e");
      return null; // Or rethrow the exception
    }
  }
}
