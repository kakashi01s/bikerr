// In lib/features/chat/data/repositories/chat_repository_impl.dart

import 'dart:io';

import 'package:bikerr/features/chat/data/datasources/chat_remote_data_source.dart'; // Assuming data source exists
import 'package:bikerr/features/chat/data/models/chat_room_model.dart';
import 'package:bikerr/features/chat/data/models/message_model.dart'; // Assuming MessageModel exists
import 'package:bikerr/features/chat/domain/repositories/chat_repository.dart'; // Import the interface
import 'package:bikerr/utils/apiResult/api_error.dart'; // Assuming ApiError exists
import 'package:bikerr/utils/apiResult/result.dart'; // Assuming Result exists
import 'package:dartz/dartz.dart'; // Assuming dartz package for Either

class ChatRepositoryImpl implements ChatRepository {
  final ChatDataSource chatRemoteDataSource; // Dependency on data source

  ChatRepositoryImpl({required this.chatRemoteDataSource});

  @override
  // This returns a map containing chat room details, messages, and pagination
  Future<Either<Result<Map<String, dynamic>>, ApiError>>
  getAllMessagesInAChatGroup({
    required int chatRoomId,
    required int page, // Pass page if your datasource uses it for the request
    required int pageSize,
  }) async {
    // Simply pass the call to the remote data source
    return await chatRemoteDataSource.getAllMessages(
      chatRoomId: chatRoomId,
      pageSize: pageSize,
      page: page,
    );
  }

  @override
  // This returns a map containing chat room details, older messages, and pagination
  Future<Either<Result<Map<String, dynamic>>, ApiError>> getOlderMessages({
    required int chatRoomId,
    required int pageSize,
    int? cursor, // Optional cursor parameter for pagination
  }) async {
    // Pass the cursor to fetch older messages via the remote data source
    return await chatRemoteDataSource.getOlderMessages(
      chatRoomId: chatRoomId,
      pageSize: pageSize,
      cursor: cursor, // Use cursor for pagination
    );
  }

  @override
  // <<< CORRECTED RETURN TYPE: Now returns MessageModel on success >>>
  Future<Either<Result<MessageModel>, ApiError>> sendMessage({
    required int chatRoomId,
    required String content,
    File? imageFile,
  }) async {
    // Pass the call to the remote data source
    // The remote data source is responsible for S3 upload if needed
    return chatRemoteDataSource.sendMessage(
      chatRoomId: chatRoomId,
      content: content,
      imageFile: imageFile,
    );
  }
  // <<< END CORRECTION >>>

  @override
  Future<Either<Result<String>, ApiError>> updateLastReadMessages({
    required int chatRoomId,
  }) async {
    // Pass the call to the remote data source
    return await chatRemoteDataSource.updateLastReadMessages(
      chatRoomId: chatRoomId,
    );
  }

  @override
  Future<Either<Result<MessageModel>, ApiError>> replyToMessage({
    required int parentMessageId,
    required String content,
    // File? imageFile, // Uncomment if replies can have attachments and datasource handles it
  }) async {
    // Pass the call to the remote data source
    return await chatRemoteDataSource.replyToMessage(
      parentMessageId: parentMessageId,
      content: content,
      // imageFile: imageFile, // Uncomment if replies can have attachments
    );
  }

  @override
  Future<Either<Result<ChatRoomModel>, ApiError>> fetchChatRoomDetails({
    required int chatRoomId,
  }) async {
    // This method specifically fetches ONLY the chat room details using the dedicated endpoint
    return await chatRemoteDataSource.fetchChatRoomDetails(
      chatRoomId: chatRoomId,
    );
  }

  // Add other chat-related methods implementation here

  // Implement methods for S3 interactions from ChatDataSource
  // These methods are likely used internally by sendMessage, but defined in the abstract class
  @override
  Future<Either<Result<Map<String, dynamic>>, ApiError>> getPresignedUrl({
    required String fileType,
    String folder = 'uploads/messages',
    String fileName = 'file',
  }) async {
    return await chatRemoteDataSource.getPresignedUrl(
      fileType: fileType,
      folder: folder,
      fileName: fileName,
    );
  }

  @override
  Future<Either<Result<String>, ApiError>> uploadImageToS3({
    required String uploadUrl,
    required File imageFile,
  }) async {
    return await chatRemoteDataSource.uploadImageToS3(
      uploadUrl: uploadUrl,
      imageFile: imageFile,
    );
  }

  @override
  Future<Either<Result<String>, ApiError>> removeUserFromChatRoom({
    required String chatRoomId,
    required String targetUserId,
  }) async {
    return await chatRemoteDataSource.removeUserFromChatRoom(
      chatRoomId: chatRoomId,
      targetUserId: targetUserId,
    );
  }
}
