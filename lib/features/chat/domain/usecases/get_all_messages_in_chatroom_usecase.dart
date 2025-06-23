// Example: In lib/features/chat/domain/usecases/get_all_messages_in_chatroom_usecase.dart

import 'package:bikerr/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:bikerr/utils/apiResult/api_error.dart'; // Assuming ApiError exists
import 'package:bikerr/utils/apiResult/result.dart'; // Assuming Result exists
import 'package:dartz/dartz.dart'; // Assuming dartz package for Either

class GetAllMessagesInChatroomUsecase {
  final ChatRepositoryImpl chatRepository; // Dependency on repository

  GetAllMessagesInChatroomUsecase({required this.chatRepository});

  // <<< CORRECTED CALL METHOD SIGNATURE >>>
  Future<Either<Result<Map<String, dynamic>>, ApiError>> call({
    required int chatRoomId,
    required int page,
    required int pageSize,
  }) async {
    // Simply call the corresponding repository method
    return await chatRepository.getAllMessagesInAChatGroup(
      chatRoomId: chatRoomId,
      page: page,
      pageSize: pageSize,
    );
  }

  // <<< END CORRECTION >>>
}
