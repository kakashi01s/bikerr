import 'dart:io';

import 'package:bikerr/features/chat/data/models/message_model.dart';
import 'package:bikerr/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:bikerr/utils/apiResult/api_error.dart';
import 'package:bikerr/utils/apiResult/result.dart';
import 'package:dartz/dartz.dart';

class SendMessageUseCase {
  final ChatRepositoryImpl repository;

  SendMessageUseCase({required this.repository});

  Future<Either<Result<MessageModel>, ApiError>> call({
    required int chatRoomId,
    required String content,
    File? imageFile,
  }) {
    return repository.sendMessage(
      chatRoomId: chatRoomId,
      content: content,
      imageFile: imageFile,
    );
  }
}
