
import '../../../chat/data/models/message_model.dart';

class ConversationEntity {
  final int id;
  final String name;
  final bool isGroup;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isInviteOnly;
  final List<ConversationUser>? users; // <--- CHANGED HERE
  final List<MessageModel> messages;
  final int unreadCount;

  ConversationEntity({
    required this.id,
    required this.name,
    required this.isGroup,
    required this.createdAt,
    required this.updatedAt,
    required this.isInviteOnly,
    required this.users, // <--- Ensure this matches the new type
    required this.messages,
    required this.unreadCount,
  });

// You can add a method to calculate unread count based on messages and lastReadAt, if required
}

class ConversationUser {
  final int? id; // Assuming user ID is still relevant
  final String? name;
  final String? profileImageKey; // Optional: profile image specific to conversation context

  ConversationUser({
    required this.id,
    required this.name,
    this.profileImageKey,
  });
}