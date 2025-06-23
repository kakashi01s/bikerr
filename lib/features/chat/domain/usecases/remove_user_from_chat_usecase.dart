import 'package:bikerr/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:bikerr/utils/apiResult/api_error.dart';
import 'package:bikerr/utils/apiResult/result.dart';
import 'package:dartz/dartz.dart';

class RemoveUserFromChatUsecase {
  final ChatRepositoryImpl chatRepositoryImpl;

  RemoveUserFromChatUsecase({required this.chatRepositoryImpl});

  Future<Either<Result<String>, ApiError>> call({
    required String chatRoomId,
    required String memberId,
  }) async {
    return await chatRepositoryImpl.removeUserFromChatRoom(
      chatRoomId: chatRoomId,
      targetUserId: memberId,
    );
  }
}
