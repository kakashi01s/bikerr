import 'package:bikerr/features/chat/data/models/message_model.dart';
import 'package:bikerr/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:bikerr/utils/apiResult/api_error.dart';
import 'package:bikerr/utils/apiResult/result.dart';
import 'package:dartz/dartz.dart';

class ReplyToMessageUsecase {
  final ChatRepositoryImpl chatRepositoryImpl;

  ReplyToMessageUsecase({required this.chatRepositoryImpl});

  Future<Either<Result<MessageModel>, ApiError>> call({
    required int parentMessageId,
    required String content,
  }) async {
    return await chatRepositoryImpl.replyToMessage(
      parentMessageId: parentMessageId,
      content: content,
    );
  }
}
