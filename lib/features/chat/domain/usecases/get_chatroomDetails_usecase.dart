import 'package:bikerr/features/chat/data/models/chat_room_model.dart';
import 'package:bikerr/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:bikerr/utils/apiResult/api_error.dart';
import 'package:bikerr/utils/apiResult/result.dart';
import 'package:dartz/dartz.dart';

class GetChatroomdetailsUsecase {
  final ChatRepositoryImpl chatRepositoryImpl;

  GetChatroomdetailsUsecase({required this.chatRepositoryImpl});

  Future<Either<Result<ChatRoomModel>, ApiError>> call({
    required int chatRoomId,
  }) async {
    return await chatRepositoryImpl.fetchChatRoomDetails(
      chatRoomId: chatRoomId,
    );
  }
}
