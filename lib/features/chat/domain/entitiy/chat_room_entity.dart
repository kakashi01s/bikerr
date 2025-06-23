// lib/features/chat/domain/entitiy/chat_room_entity.dart
import 'chat_room_user_entity.dart';
import 'message_entity.dart';

abstract class ChatRoomEntity {
  final int id;
  final String? name;
  final String? description;
  final String? state;
  final String? city;
  final bool isGroup;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isInviteOnly;
  final String? image;
  final bool isPublic; // <--- ADD THIS FIELD TO THE ENTITY
  final List<ChatRoomUserEntity> users;
  final List<MessageEntity> messages;
  final int unreadMessages;
  final int memberCount;
  final bool isMember;
  final bool isRequestedByCurrentUser;

  const ChatRoomEntity({
    required this.id,
    this.name,
    this.description,
    this.state,
    this.city,
    required this.isGroup,
    required this.createdAt,
    required this.updatedAt,
    required this.isInviteOnly,
    this.image,
    required this.isPublic, // <--- ADD THIS TO THE ENTITY CONSTRUCTOR
    required this.users,
    required this.messages,
    required this.unreadMessages,
    required this.memberCount,
    required this.isMember,
    required this.isRequestedByCurrentUser,
  });
}