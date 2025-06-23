// In lib/features/chat/domain/entitiy/message_entity.dart

import 'package:bikerr/features/auth/data/models/user_model.dart'; // Assuming UserModel is used
import 'package:equatable/equatable.dart'; // Import Equatable for props

class MessageEntity extends Equatable {
  // Extend Equatable
  final int id;
  final String? content;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isEdited;
  final int? parentMessageId;
  final int senderId;
  final int chatRoomId;
  final UserModel user;
  final String timestamp; // <-- Kept the timestamp field

  // Field for the parent message entity
  final MessageEntity? parentMessage;

  MessageEntity({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.isEdited,
    required this.parentMessageId,
    required this.senderId,
    required this.chatRoomId,
    required this.user,
    required this.timestamp, // <-- Include in constructor
    this.parentMessage, // Nullable parentMessage
  });

  // Equatable props should include all final fields for comparison
  @override
  List<Object?> get props => [
    id,
    content,
    createdAt,
    updatedAt,
    isEdited,
    parentMessageId,
    senderId,
    chatRoomId,
    user,
    timestamp, // <-- Include timestamp in props
    parentMessage, // Include parentMessage in props (can be null)
  ];

  @override
  bool get stringify => true; // Optional: For better debug output
}
