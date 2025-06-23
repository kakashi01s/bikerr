import 'package:equatable/equatable.dart';

class MessageAttachmentEntity extends Equatable {
  final int id;
  final String key; // The S3 key for the attachment
  final String fileType; // The file type (e.g., 'jpg', 'png', 'pdf')
  final int messageId; // The ID of the message this attachment belongs to

  const MessageAttachmentEntity({
    required this.id,
    required this.key,
    required this.fileType,
    required this.messageId,
  });

  @override
  List<Object?> get props => [id, key, fileType, messageId];

  @override
  bool get stringify => true;
}
