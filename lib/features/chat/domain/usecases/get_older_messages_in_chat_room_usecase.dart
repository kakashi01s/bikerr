import 'package:bikerr/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:bikerr/utils/apiResult/api_error.dart';
import 'package:bikerr/utils/apiResult/result.dart';
import 'package:dartz/dartz.dart';

class GetOlderMessagesInChatroomUsecase {
  final ChatRepositoryImpl chatRepository; // Dependency on repository

  GetOlderMessagesInChatroomUsecase({required this.chatRepository});

  // <<< CORRECTED CALL METHOD SIGNATURE >>>
  Future<Either<Result<Map<String, dynamic>>, ApiError>> call({
    required int chatRoomId,
    required int pageSize,
    int? cursor, // Optional cursor parameter for pagination
  }) async {
    // Simply call the corresponding repository method
    return await chatRepository.getOlderMessages(
      chatRoomId: chatRoomId,
      pageSize: pageSize,
      cursor: cursor, // Pass the cursor
    );
  }

  // <<< END CORRECTION >>>
}
