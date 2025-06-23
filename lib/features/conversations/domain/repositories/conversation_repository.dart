import 'package:bikerr/utils/apiResult/api_error.dart';
import 'package:bikerr/utils/apiResult/result.dart';
import 'package:dartz/dartz.dart';

abstract class ConversationRepository {
  Future<Either<Result<Map<String, dynamic>>, ApiError>>
  getAllUserConversations({int? page, int? limit});
  Future<Either<Result<Map<String, dynamic>>, ApiError>>
  getAllChatRoomsPaginated({int? page, int? limit});
  Future<Either<Result<Map<String,dynamic>>,ApiError>>
  joinNewChatGroup({required String chatRoomId,required String userId});
}
