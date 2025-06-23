import 'package:bikerr/features/conversations/data/datasources/conversation_remote_data_source.dart';
import 'package:bikerr/features/conversations/domain/repositories/conversation_repository.dart';
import 'package:bikerr/utils/apiResult/api_error.dart';
import 'package:bikerr/utils/apiResult/result.dart';
import 'package:dartz/dartz.dart';

class ConversationRepositoryImpl extends ConversationRepository {
  final ConversationRemoteDataSource conversationRemoteDataSource;

  ConversationRepositoryImpl({required this.conversationRemoteDataSource});

  @override
  Future<Either<Result<Map<String, dynamic>>, ApiError>>
  getAllUserConversations({int? page, int? limit}) async {
    return await conversationRemoteDataSource.getAllUserConversations(
      page: page,
      limit: limit,
    );
  }

  @override
  Future<Either<Result<Map<String, dynamic>>, ApiError>>
  getAllChatRoomsPaginated({int? page, int? limit}) async {
    return await conversationRemoteDataSource.getAllChatGroups(
      page: page,
      limit: limit,
    );
  }

  @override
  Future<Either<Result<Map<String, dynamic>>, ApiError>> joinNewChatGroup({required String chatRoomId,required String userId}) async{
    return await conversationRemoteDataSource.joinNewChatGroup(chatRoomId: chatRoomId, userId:  userId);
    throw UnimplementedError();
  }


}
