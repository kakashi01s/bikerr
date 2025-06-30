import 'package:bikerr/config/routes/route_names.dart';
import 'package:bikerr/features/auth/presentation/pages/forgot_password_screen.dart';
import 'package:bikerr/features/auth/presentation/pages/login_screen.dart';
import 'package:bikerr/features/auth/presentation/pages/register_screen.dart';
import 'package:bikerr/features/auth/presentation/pages/reset_password_screen.dart';
import 'package:bikerr/features/auth/presentation/pages/splash_screen.dart';
import 'package:bikerr/features/auth/presentation/pages/verify_otp.dart';
import 'package:bikerr/features/base/presentation/bloc/base_bloc.dart';
import 'package:bikerr/features/base/presentation/pages/base_page.dart';
import 'package:bikerr/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:bikerr/features/chat/presentation/pages/base_chat_screen.dart';
import 'package:bikerr/features/chat/presentation/pages/chat_screen.dart';
import 'package:bikerr/features/conversations/presentation/bloc/conversation_bloc.dart';
import 'package:bikerr/features/conversations/presentation/pages/conversation_screen.dart';
import 'package:bikerr/features/conversations/presentation/pages/create_new_conversations.dart';
import 'package:bikerr/features/conversations/presentation/pages/join_new_conversations.dart';
import 'package:bikerr/features/map/presentation/bloc/map_bloc.dart';
import 'package:bikerr/features/map/presentation/pages/geo_fence_screen.dart';
import 'package:bikerr/features/map/presentation/pages/map_screen.dart';
import 'package:bikerr/utils/di/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class Routes {
  final BaseBloc baseBloc = BaseBloc();
  Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RoutesName.basePage:
        return MaterialPageRoute(
          builder:
              (_) => BlocProvider<BaseBloc>.value(
                value: baseBloc,
                child: BasePage(),
              ),
        );
      case RoutesName.splashScreen:
        return MaterialPageRoute(builder: (context) => const SplashScreen());
       case RoutesName.geoFenceScreen:
         final arguments = settings.arguments as Map<String, dynamic>?;
         final position = arguments?['position'];

        return MaterialPageRoute(builder: (context) => GeoFenceScreen(position: position));
      case RoutesName.mapScreen:
        return MaterialPageRoute(builder: (context) {
          return BlocProvider(
            create: (context) => sl<MapBloc>(),
            child: MapScreen(),);
        });
      case RoutesName.registerScreen:
        return MaterialPageRoute(builder: (context) => const RegisterScreen());
      case RoutesName.joinChatScreen:
        return MaterialPageRoute(
          builder: (context) {
            return BlocProvider(
              create: (context) => sl<ConversationBloc>(),
              child: JoinNewConversations(),
            );
          },
        );
      case RoutesName.loginScreen:
        return MaterialPageRoute(builder: (context) => const LoginScreen());
      case RoutesName.conversationsScreen:
        return MaterialPageRoute(
          builder: (context) => const ConversationScreen(),
        );
      case RoutesName.forgotPasswordScreen:
        return MaterialPageRoute(
          builder: (context) => const ForgotPasswordScreen(),
        );
      case RoutesName.verifyOtpScreen:
        final arguments = settings.arguments as Map<String, dynamic>?;
        final id = arguments?['id'];
        final password = arguments?['password'];
        final email = arguments?['email'];
        final source = arguments?['source'];
        return MaterialPageRoute(
          builder:
              (context) => VerifyOtpScreen(
                id: id,
                password: password,
                email: email,
                source: source,
              ),
        );
      case RoutesName.resetPassword:
        final arguments = settings.arguments as Map<String, dynamic>?;
        final email = arguments?['email'];
        final token = arguments?['token'];
        return MaterialPageRoute(
          builder: (context) => ResetPasswordScreen(email: email, token: token),
        );
      case RoutesName.chatScreen:
        final arguments = settings.arguments as Map<String, dynamic>?;
        final chatRoomId = arguments?['chatRoomId'];
        return MaterialPageRoute(
          builder:
              (context) => BlocProvider(
                create: (context) => context.read<ChatBloc>(),
                child: ChatScreen(chatRoomId: chatRoomId),
              ),
        );
      case RoutesName.baseChatScreen:
        final arguments = settings.arguments as Map<String, dynamic>?;
        // Safely extract chatRoomId and explicitly cast to nullable int
        final int? chatRoomId = arguments?['chatRoomId'] as int?;
        final String chatRoomName = arguments?['chatRoomName'] as String;

        // Check if chatRoomId is null before navigating
        if (chatRoomId == null) {
          // Handle the case where chatRoomId is missing or null in the route arguments.
          print(
            'Navigation Error: chatRoomId is missing for BaseChatScreen route.',
          );

          // Navigate back to the previous screen
          return MaterialPageRoute(
            builder: (context) {
              return const Scaffold(
                body: Center(
                  child: Text('Invalid chat room. Please try again.'),
                ),
              );
            },
          );
        } else {
          // If chatRoomId is not null, proceed with navigation to BaseAppChatScreen
          // Pass the guaranteed non-null chatRoomId to the constructor
          return MaterialPageRoute(
            builder: (context) {
              // Use a Builder to get a context that is a descendant of the route's context.
              // This ensures the BlocProvider is associated with the correct context scope
              // before its child (BaseAppChatScreen) attempts to read it in initState.
              return BlocProvider(
                create: (context) => sl<ChatBloc>(),
                child: BaseChatScreen(
                  chatRoomId: chatRoomId,
                  chatRoomName: chatRoomName,
                ),
              );
            },
          );

        }

      case RoutesName.createChatGroupsScreen:
        return MaterialPageRoute(
          builder: (context) => const CreateNewConversations(),
        );
      default:
        return MaterialPageRoute(
          builder: (context) {
            return const Scaffold(
              body: Center(child: Text('No Route Generated')),
            );
          },
        );
    }
  }
}
