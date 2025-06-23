import 'package:dartz/dartz.dart';

import '../../../../utils/apiResult/api_error.dart';
import '../../../../utils/apiResult/result.dart';
import '../../data/repositories/conversation_repository_impl.dart';

class JoinNewChatGroupUseCase {
  final ConversationRepositoryImpl conversationRepositoryImpl;

  JoinNewChatGroupUseCase({required this.conversationRepositoryImpl});

  Future<Either<Result<Map<String, dynamic>>, ApiError>> call({
    required String userId, // Keep if your backend explicitly needs it
    required String chatRoomId
  }) async {
    // This simply passes the call to the repository.
    // Any business logic or validation (if any) related to joining a group
    // would go here *before* calling the repository.
    return await conversationRepositoryImpl.joinNewChatGroup(
      userId: userId,
      chatRoomId: chatRoomId,
    );
  }
}