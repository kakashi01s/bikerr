// Base entity for ChatRoomUser (represents a user's membership and role in a specific chat room)
import 'package:bikerr/features/auth/data/models/user_model.dart';
import 'package:equatable/equatable.dart';

abstract class ChatRoomUserEntity extends Equatable {
  final int userId;
  final String role; // e.g., 'OWNER', 'MODERATOR', 'MEMBER'
  final UserModel user; // Details of the user associated with this membership

  const ChatRoomUserEntity({
    required this.userId,
    required this.role,
    required this.user,
  });

  @override
  List<Object?> get props => [userId, role, user]; // Implement props for Equatable
}
