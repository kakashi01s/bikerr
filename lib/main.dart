import 'package:bikerr/config/routes/route_names.dart';
import 'package:bikerr/config/routes/routes.dart';
import 'package:bikerr/core/theme.dart';
import 'package:bikerr/utils/di/service_locator.dart' as di;
import 'package:bikerr/utils/socket/socket_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await di.init();
  final socketService = SocketService();
  await socketService.initSocket();

  runApp(const MyApp());
}

@pragma("vm:entry-point")
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bikerr',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: RoutesName.splashScreen,
      onGenerateRoute: Routes().generateRoute,
    );
  }
}
