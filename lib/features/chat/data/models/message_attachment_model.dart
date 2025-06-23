// In lib/features/chat/data/models/message_attachment_model.dart

import 'package:bikerr/features/chat/domain/entitiy/message_attachment_entity.dart';

class MessageAttachmentModel extends MessageAttachmentEntity {
  const MessageAttachmentModel({
    required super.id,
    required super.key,
    required super.fileType,
    required super.messageId,
  });

  // Factory constructor to create a MessageAttachmentModel from a JSON Map
  factory MessageAttachmentModel.fromJson(Map<String, dynamic> json) {
    // Using ?? with default values to handle potentially missing keys gracefully
    return MessageAttachmentModel(
      id: json['id'] ?? 0, // Assuming id is an int, default to 0
      key: json['key'] ?? '', // Assuming key is a String, default to empty
      fileType:
          json['fileType'] ??
          '', // Assuming fileType is a String, default to empty
      messageId:
          json['messageId'] ?? 0, // Assuming messageId is an int, default to 0
    );
  }

  // Note: toJson is typically needed if sending this model TO the backend.
  // The structure for sending might be different from the received structure.
  // Example (if needed):
  /*
  Map<String, dynamic> toJson() {
    return {
      'id': id, // May or may not be needed when sending
      'key': key,
      'fileType': fileType,
      'messageId': messageId, // May or may not be needed when sending
    };
  }
  */
}
