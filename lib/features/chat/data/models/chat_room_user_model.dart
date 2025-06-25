// Concrete model for ChatRoomUser, extending ChatRoomUserEntity
import 'package:bikerr/features/auth/data/models/user_model.dart';
import 'package:bikerr/features/chat/domain/entitiy/chat_room_user_entity.dart';

import 'package:bikerr/features/auth/data/models/user_model.dart'; // Ensure this path is correct
import 'package:bikerr/features/chat/domain/entitiy/chat_room_user_entity.dart'; // Ensure this path is correct

class ChatRoomUserModel extends ChatRoomUserEntity {
  const ChatRoomUserModel({
    required super.userId,
    required super.role,
    required super.user, // This will be a UserModel
  });

  // Factory constructor to create a ChatRoomUserModel from JSON
  factory ChatRoomUserModel.fromJson(Map<String, dynamic> json) {
    // --- User parsing (Robust handling) ---
    UserModel? parsedUser; // Declare as nullable initially
    final userJson = json['user'];

    if (userJson != null && userJson is Map<String, dynamic>) {
      try {
        parsedUser = UserModel.fromJson(userJson);
      } catch (e, s) {
        print('[ChatRoomUserModel] Error parsing nested UserModel: $e\nJSON for user: $userJson\n$s');
        // Decide on fallback:
        // Option 1: Throw to indicate data integrity issue (if user is absolutely required)
        // throw FormatException('Failed to parse user data for ChatRoomUser: $e');

        // Option 2: Use a default/placeholder UserModel (if the app can gracefully handle a missing/partial user)
        // Ensure UserModel constructor can handle defaults or has a factory for this.
        parsedUser = UserModel(
            id: json['userId'] ?? 0, // Fallback ID if possible
            name: 'Unknown User',
            email: 'unknown@example.com',
            // Provide default values for all other required fields in UserModel
            created_at: DateTime(1970),
            updated_at: DateTime(1970),
            isVerified: false,
            jwtRefreshToken: '',
            jwtAccessToken: '',
            traccarId: null,
            traccarToken: '',
            profileImageKey: '',
            sessionCookie: ''
          // ... any other required fields for UserModel
        );
      }
    } else {
      print('[ChatRoomUserModel] Warning: "user" field is missing, null, or not a Map in JSON for userId: ${json['userId']}. Provided value: $userJson');
      // Again, decide on fallback:
      // Option 1 (if user is critical and ChatRoomUserEntity.user is not nullable):
      // throw FormatException('Missing or invalid user data for ChatRoomUser with userId: ${json['userId']}');

      // Option 2 (if ChatRoomUserEntity.user can be nullable, or you use a placeholder):
      // If super.user can be null, you could assign null here if ChatRoomUserEntity allows it.
      // For now, using a placeholder as in the catch block.
      parsedUser = UserModel(
          id: json['userId'] ?? 0, // Fallback ID
          name: 'Unknown User (Data Missing)',
          email: 'unknown@example.com',
          created_at: DateTime(1970),
          updated_at: DateTime(1970),
          isVerified: false,
          jwtRefreshToken: '',
          jwtAccessToken: '',
          traccarId: null,
          traccarToken: '',
          profileImageKey: '',
        sessionCookie: ''
        // ... other required fields
      );
    }
    // --- End User parsing ---

    // Ensure 'userId' and 'role' are present and of the correct type, or provide defaults/handle errors
    final int? userId = json['userId'] as int?; // Or 'as int' if guaranteed non-null
    final String? role = json['role'] as String?; // Or 'as String'

    if (userId == null) {
      // Handle missing userId, e.g., throw, or skip, or use a default if permissible
      print('[ChatRoomUserModel] Error: "userId" is missing or null. JSON: $json');
      throw FormatException('Missing userId in ChatRoomUserModel JSON');
    }

    if (role == null) {
      // Handle missing role
      print('[ChatRoomUserModel] Warning: "role" is missing or null. Using default. JSON: $json');
      // defaultRole = 'member'; // Example default
      throw FormatException('Missing role in ChatRoomUserModel JSON (or assign a default if appropriate)');
    }

    if (parsedUser == null) {
      // This should ideally not be reached if you always assign a placeholder UserModel above.
      // But as a final fallback if you chose to allow parsedUser to be null and super.user is non-nullable.
      print('[ChatRoomUserModel] Critical Error: Parsed user is null and super.user is required. UserID: $userId');
      throw FormatException('Failed to obtain a valid User model for ChatRoomUser with userId: $userId');
    }


    return ChatRoomUserModel(
      userId: userId, // userId is now confirmed non-null or an error was thrown
      role: role,     // role is now confirmed non-null or an error/default was handled
      user: parsedUser, // parsedUser is now a valid UserModel (either parsed or placeholder)
    );
  }
}