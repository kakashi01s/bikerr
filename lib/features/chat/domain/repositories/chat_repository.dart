// In lib/features/chat/domain/repositories/chat_repository.dart

import 'dart:io';
import 'package:bikerr/features/chat/data/models/chat_room_model.dart';
import 'package:bikerr/features/chat/data/models/message_model.dart'; // Assuming MessageModel is used
import 'package:bikerr/utils/apiResult/api_error.dart'; // Assuming ApiError exists
import 'package:bikerr/utils/apiResult/result.dart'; // Assuming Result exists
import 'package:dartz/dartz.dart'; // Assuming dartz package for Either

abstract class ChatRepository {
  // This returns a map containing chat room details, messages, and pagination
  Future<Either<Result<Map<String, dynamic>>, ApiError>>
  getAllMessagesInAChatGroup({
    required int chatRoomId,
    required int page, // Pass page if your datasource uses it for the request
    required int pageSize,
  });

  // This returns a map containing chat room details, older messages, and pagination
  Future<Either<Result<Map<String, dynamic>>, ApiError>> getOlderMessages({
    required int chatRoomId,
    required int pageSize,
    int? cursor, // Optional cursor parameter for pagination
  });

  // <<< CORRECTED RETURN TYPE: Now returns MessageModel on success >>>
  Future<Either<Result<MessageModel>, ApiError>> sendMessage({
    required int chatRoomId,
    required String content,
    File? imageFile,
  });
  // <<< END CORRECTION >>>

  Future<Either<Result<String>, ApiError>> updateLastReadMessages({
    required int chatRoomId,
  });

  Future<Either<Result<MessageModel>, ApiError>> replyToMessage({
    required int parentMessageId,
    required String content,
    // File? imageFile, // Uncomment if replies can have attachments
  });

  // This method specifically fetches ONLY the chat room details
  Future<Either<Result<ChatRoomModel>, ApiError>> fetchChatRoomDetails({
    required int chatRoomId,
  });

  // Add other chat-related methods here (e.g., create chat room, invite user, etc.)

  // Abstract methods for S3 interactions (used by sendMessage internally)
  Future<Either<Result<Map<String, dynamic>>, ApiError>> getPresignedUrl({
    required String fileType,
    String folder,
    String fileName,
  });
  Future<Either<Result<String>, ApiError>> uploadImageToS3({
    required String uploadUrl,
    required File imageFile,
  });

  Future<Either<Result<String>, ApiError>> removeUserFromChatRoom({
    required String chatRoomId,
    required String targetUserId,
  });
}
