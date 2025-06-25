// In lib/features/chat/data/models/message_model.dart

import 'package:bikerr/features/auth/data/models/user_model.dart'; // Assuming UserModel exists and has fromJson
import 'package:bikerr/features/chat/data/models/message_attachment_model.dart';
import 'package:bikerr/features/chat/domain/entitiy/message_entity.dart'; // Import the entity
import 'package:equatable/equatable.dart'; // Assuming Equatable is used

class MessageModel extends MessageEntity {
  // Overrides the parentMessage field from MessageEntity with a more specific type.
  // The value is still passed up to the super constructor.
  @override
  final MessageModel? parentMessage;

  // Override attachments field with MessageAttachmentModel type and make it required
  @override
  final List<MessageAttachmentModel> attachments;

  // Constructor matches the entity constructor and includes all fields
  // Use named parameters for clarity, matching the entity constructor
  MessageModel({
    required super.id,
    required super.content, // content can be null for image-only messages
    required super.createdAt,
    required super.updatedAt,
    required super.isEdited,
    required super.parentMessageId, // parentMessageId can be null
    required super.senderId,
    required super.chatRoomId,
    required super.user,
    required super.timestamp, // Kept in constructor, consider if redundant with createdAt
    required this.parentMessage, // Use 'this' as it's an override field, value passed to super
    required this.attachments, // Use 'this' as it's an override field, required
  });

  // Factory constructor to create a MessageModel from a JSON Map
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    // Helper function for safe date time parsing
    DateTime? tryParseDateTime(dynamic dateStr) {
      if (dateStr == null) return null; // Handle null date strings
      if (dateStr is String) {
        try {
          // Attempt to parse the date string. Use toLocal() if backend sends UTC.
          return DateTime.parse(dateStr).toLocal();
        } catch (e) {
          // Log the error but return null to prevent crash
          print('MessageModel: Error parsing date string "$dateStr": $e');
          return null; // Return null on parsing error
        }
      }
      // Handle other potential types if your API sends them (e.g., milliseconds since epoch)
      print(
        'MessageModel: Warning: createdAt/updatedAt is not a string: $dateStr',
      );
      return null; // Return null for unexpected types
    }

    // Parse the parent message from JSON if present
    // Assumes the backend provides the parent message object nested under the key 'parentMessage'
    final parentMessageJson =
        json['parentMessage']; // Adjust 'parentMessage' key based on your backend response
    final MessageModel? parsedParentMessage =
        parentMessageJson != null && parentMessageJson is Map<String, dynamic>
            ? MessageModel.fromJson(
              parentMessageJson,
            ) // Recursively parse the parent message JSON
            : null; // Set to null if parentMessage is not present or not a Map

    // Parse the sender details
    // Assumes the backend provides the sender object nested under the key 'sender'
    final senderJson =
        json['sender']; // Adjust key based on your backend response
    final UserModel parsedSender =
        (senderJson != null && senderJson is Map<String, dynamic>)
            ? UserModel.fromJson(senderJson) // Parse sender user model JSON
            : UserModel(
              // Provide a default/placeholder user model if sender is missing or invalid
              id:
                  json['senderId'] ??
                  0, // Fallback to senderId if sender object is missing
              name: 'Unknown User',
              email: 'unknown@example.com', // Use a placeholder email
              traccarId: null, // Default nullable fields
              created_at: DateTime(1970), // Default DateTime to epoch
              updated_at: DateTime(1970), // Default DateTime to epoch
              isVerified: false,
              jwtRefreshToken: '', // Default empty strings
              jwtAccessToken: '',
              traccarToken: '',
              profileImageKey: null ?? '', // Default nullable field
          sessionCookie: ''
            );

    // Get the timestamp string (if used - logs show backend uses createdAt)
    // If your backend provides a separate timestamp string, parse it here.
    // Otherwise, you might remove the timestamp field if it's redundant with createdAt.
    // For now, keeping it but setting to empty or deriving from createdAt if necessary.
    // Using ?? '' ensures timestampString is always a String.
    final String timestampString =
        json['timestamp']?.toString() ?? // Safely access and convert to string
        (tryParseDateTime(json['createdAt'])?.toIso8601String() ??
            ''); // Derive from createdAt as fallback

    // Parse attachments from JSON
    // Assumes the backend provides a list of attachment objects under the key 'attachments'
    final attachmentsJson =
        json['attachments']; // Expecting 'attachments' key from backend
    final List<MessageAttachmentModel> parsedAttachments =
        (attachmentsJson != null && attachmentsJson is List)
            ? attachmentsJson
                .map(
                  // Ensure each item in the list is treated as a Map<String, dynamic>
                  (item) => MessageAttachmentModel.fromJson(
                    item as Map<String, dynamic>,
                  ),
                )
                .toList()
            : []; // Default to empty list if no attachments or not a list

    // Construct and return the MessageModel instance
    return MessageModel(
      id: json['id'] ?? 0, // Provide default value if ID is missing
      content:
          json['content']
              ?.toString(), // Content can be null, safely access and convert
      createdAt: tryParseDateTime(
        json['createdAt'],
      ), // Use the safe date parser
      updatedAt: tryParseDateTime(
        json['updatedAt'],
      ), // Use the safe date parser
      isEdited: json['isEdited'] ?? false, // Default to false
      parentMessageId:
          json['parentMessageId'], // Nullable int, no default needed
      senderId:
          json['senderId'] ??
          parsedSender.id, // Use senderId from JSON or parsed sender ID
      chatRoomId: json['chatRoomId'] ?? 0, // Provide default
      user: parsedSender, // Use the parsed sender
      timestamp: timestampString, // Assign the parsed/derived timestamp
      parentMessage: parsedParentMessage, // Assign the parsed parentMessage
      attachments: parsedAttachments, // Assign the parsed attachments
    );
  }

  // Implement props for EquatableMixin to define equality based on these fields
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
    timestamp,
    parentMessage, // Include parentMessage in props (can be null)
    attachments, // Include attachments in props
  ];

  @override
  bool get stringify => true; // Optional: For better debug output
}
