import 'package:bikerr/config/constants.dart';
import 'package:bikerr/config/routes/route_names.dart';
import 'package:bikerr/core/theme.dart';
import 'package:bikerr/services/notifications/notification_service.dart';
import 'package:bikerr/services/session/session_manager.dart';
import 'package:bikerr/utils/di/service_locator.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final SessionManager session = SessionManager.instance;
  late final NotificationService _notificationService;
  final bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _notificationService = sl<NotificationService>();
    _initialize();
  }

  Future<void> _initialize() async {
    final firebaseInit = _initializeFirebase();
    final sessionCheck = _checkLogin();

    await Future.wait([firebaseInit, sessionCheck]);

    _navigateToNextScreen(); // ✅ move here
  }

  Future<void> _initializeFirebase() async {
    final settings = await _notificationService.requestNotificationPermissions(
      context,
    );
    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      print("Notification permissions granted.");
    } else {
      print("Notification permissions not granted.");
      // Optionally handle this (e.g., show a message later)
    }
  }

  Future<void> _checkLogin() async {
    await session.getSession();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: Stack(
        // Use Stack to position widgets on top of each other
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              width: screenWidth,
              child: Image.asset(
                AppLogos.bikerrPng,
                fit: BoxFit.fitWidth, // Make the image take full width
                alignment: Alignment.topCenter,
              ),
            ),
          ),

          // You can add other widgets below the image in the Stack
          // For example, another Row, Column, or Text
          Positioned(
            top: 400,
            left: 0,
            right: 0,
            child: SizedBox(
              width: 100,
              child: SvgPicture.asset(AppLogos.bikerr),
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 10,
            child: SizedBox(
              child: SvgPicture.asset(
                'assets/images/splash_group.svg',
                width: screenWidth,
                alignment: Alignment.topCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Navigate only after the build context is fully available and initialization is done
    if (_initialized) {
      _navigateToNextScreen();
    }
  }

  void _navigateToNextScreen() {
    print(
      "Navigating to next screen... Traccar Id: ${session.traccarId} ${session.jwtRefreshToken}",
    );
    if (session.traccarId == null && session.userId == null) {
      Navigator.pushReplacementNamed(context, RoutesName.loginScreen);
    } else {
      Navigator.pushReplacementNamed(context, RoutesName.basePage);
    }
  }
}
