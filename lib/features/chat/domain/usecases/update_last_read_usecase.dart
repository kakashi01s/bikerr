import 'package:bikerr/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:bikerr/utils/apiResult/api_error.dart';
import 'package:bikerr/utils/apiResult/result.dart';
import 'package:dartz/dartz.dart';

class UpdateLastReadUsecase {
  final ChatRepositoryImpl chatRepositoryImpl;

  UpdateLastReadUsecase({required this.chatRepositoryImpl});

  Future<Either<Result<String>, ApiError>> call({
    required int chatRoomId,
  }) async {
    return await chatRepositoryImpl.updateLastReadMessages(
      chatRoomId: chatRoomId,
    );
  }
}
