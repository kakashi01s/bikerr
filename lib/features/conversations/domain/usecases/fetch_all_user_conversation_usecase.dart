import 'package:bikerr/features/conversations/data/repositories/conversation_repository_impl.dart';
import 'package:bikerr/utils/apiResult/api_error.dart';
import 'package:bikerr/utils/apiResult/result.dart';
import 'package:dartz/dartz.dart';

class FetchAllUserConversationUseCase {
  final ConversationRepositoryImpl conversationRepositoryImpl;

  FetchAllUserConversationUseCase({required this.conversationRepositoryImpl});

  Future<Either<Result<Map<String, dynamic>>, ApiError>> call({
    int? page,
    int? limit,
  }) async {
    return await conversationRepositoryImpl.getAllUserConversations(
      page: page,
      limit: limit,
    );
  }
}
