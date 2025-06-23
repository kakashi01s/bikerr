import 'dart:convert';
import 'dart:io';

import 'package:bikerr/config/constants.dart'; // Assuming AppUrl is defined here
import 'package:bikerr/features/chat/data/models/chat_room_model.dart';
import 'package:bikerr/features/chat/data/models/message_model.dart'; // Assuming MessageModel exists
import 'package:bikerr/utils/apiResult/api_error.dart'; // Assuming ApiError exists
import 'package:bikerr/utils/apiResult/result.dart'; // Assuming Result exists
import 'package:bikerr/utils/network/network_api_services.dart'; // Assuming NetworkServicesApi exists
import 'package:dartz/dartz.dart'; // Assuming dartz package for Either
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart'; // Added for getting MIME type (used in upload)

abstract class ChatDataSource {
  Future<Either<Result<ChatRoomModel>, ApiError>> fetchChatRoomDetails({
    required int chatRoomId,
  });

  Future<Either<Result<Map<String, dynamic>>, ApiError>> getAllMessages({
    required int chatRoomId,
    int pageSize = 20,
    int? page,
  });

  Future<Either<Result<Map<String, dynamic>>, ApiError>> getOlderMessages({
    required int chatRoomId,
    required int pageSize,
    int? cursor,
  });

  Future<Either<Result<MessageModel>, ApiError>> sendMessage({
    required int chatRoomId,
    required String content,
    File? imageFile,
  });

  Future<Either<Result<String>, ApiError>> updateLastReadMessages({
    required int chatRoomId,
  });

  Future<Either<Result<MessageModel>, ApiError>> replyToMessage({
    required int parentMessageId,
    required String content,
  });

  Future<Either<Result<Map<String, dynamic>>, ApiError>> getPresignedUrl({
    required String fileType,
    String folder,
    String fileName,
  });

  Future<Either<Result<String>, ApiError>> uploadImageToS3({
    required String uploadUrl,
    required File imageFile,
  });
  Future<Either<Result<String>, ApiError>> removeUserFromChatRoom({
    required String chatRoomId,
    required String targetUserId,
  });
}

class ChatRemoteDataSource implements ChatDataSource {
  final _api = NetworkServicesApi();

  // Internal method for fetching messages with pagination.
  // This method expects the backend to return a map containing chatRoom details,
  // a list of messages, and pagination information, all nested under a 'data' key.
  @override
  Future<Either<Result<Map<String, dynamic>>, ApiError>> _fetchMessages({
    required int chatRoomId,
    required int pageSize,
    int? page,
    int? cursor,
  }) async {
    try {
      String url =
          '${AppUrl.getAllMessagesInAChatRoom}/$chatRoomId?pageSize=$pageSize';
      if (page != null) {
        url += '&page=$page';
      }
      if (cursor != null) {
        url += '&cursor=$cursor';
      }

      print(
        '[ChatRemoteDataSource] Fetching messages and chat details from: $url',
      );

      final response = await _api.getApi(url);

      print(
        '[ChatRemoteDataSource] Response Status for Fetch Messages: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final decodedJson = jsonDecode(response.body);

        String URL2 =
            '${AppUrl.updateLastReadMessages}/$chatRoomId';

        print(
          '[ChatRemoteDataSource] Updating Last Read for Chat Room after fetching messages: $url',
        );

        final response2 = await _api.putApi(URL2,{});

        if(response2.statusCode == 200)
        {
          // Assuming backend response structure: { success: true, message: "...", data: { chatRoom: {...}, messages: [...], pagination: {...} } }
          if (decodedJson['data'] != null &&
              decodedJson['data'] is Map<String, dynamic>) {
            print(
              '[ChatRemoteDataSource] Sending latest messages to bloc',
            );
            return Left(
              Result.success(decodedJson['data'] as Map<String, dynamic>),
            );
          } else {
            print(
              '[ChatRemoteDataSource] inside unread check Error: API response data structure unexpected or missing data field for _fetchMessages.',
            );
            return Right(
              ApiError(
                message:
                decodedJson['message'] ??
                    ' inside unrRead check  : Invalid API response data structure: Missing or invalid "data" field.',
              ),
            );
          }
        }
        else {
          print(
            '[ChatRemoteDataSource] Error: API response data structure unexpected or missing data field for _fetchMessages.',
          );
          return Right(
            ApiError(
              message:
              decodedJson['message'] ??
                  'Invalid API response data structure: Missing or invalid "data" field.',
            ),
          );
        }

      } else {
        String errorMessage = 'Failed to fetch messages and chat details';
        try {
          final decodedJson = jsonDecode(response.body);
          errorMessage = decodedJson['message'] ?? errorMessage;
        } catch (_) {
          // Use default if no message in response
        }
        print(
          '[ChatRemoteDataSource] Error fetching messages and chat details: $errorMessage (Status code: ${response.statusCode})',
        );
        return Right(
          ApiError(
            message: '$errorMessage (Status code: ${response.statusCode})',
          ),
        );
      }
    } catch (e) {
      print('[ChatRemoteDataSource] Exception fetching messages: $e');
      return Right(
        ApiError(message: 'Exception during API call: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Result<Map<String, dynamic>>, ApiError>> getAllMessages({
    required int chatRoomId,
    int pageSize = 20,
    int? page,
  }) async {
    return _fetchMessages(
      chatRoomId: chatRoomId,
      page: page,
      pageSize: pageSize,
      cursor: null,
    );
  }

  @override
  Future<Either<Result<Map<String, dynamic>>, ApiError>> getOlderMessages({
    required int chatRoomId,
    required int pageSize,
    int? cursor,
  }) async {
    return _fetchMessages(
      chatRoomId: chatRoomId,
      pageSize: pageSize,
      cursor: cursor,
    );
  }

  @override
  Future<Either<Result<MessageModel>, ApiError>> sendMessage({
    required int chatRoomId,
    required String content,
    File? imageFile,
  }) async {
    try {
      String? uploadedFileKey;

      if (imageFile != null) {
        final presignedUrlResult = await getPresignedUrl(
          fileType:
              lookupMimeType(imageFile.path) ??
              imageFile.path
                  .split('.')
                  .lastWhere((e) => true, orElse: () => 'binary'),
          folder: 'uploads/messages',
          fileName: 'msg_attachment_${DateTime.now().millisecondsSinceEpoch}',
        );

        if (presignedUrlResult.isRight()) {
          final error = presignedUrlResult.fold(
            (_) => ApiError(message: 'Unknown error getting presigned URL'),
            (right) => right,
          );
          print(
            '[ChatRemoteDataSource] Failed to get upload URL: ${error.message}',
          );
          return Right(error);
        }

        final presignedUrlDataResult = presignedUrlResult.fold(
          (left) => left,
          (_) => throw StateError('Expected Left result'),
        );
        final Map<String, dynamic>? presignedUrlData =
            presignedUrlDataResult.data;

        if (presignedUrlData == null ||
            !presignedUrlData.containsKey('uploadUrl') ||
            !presignedUrlData.containsKey('fileKey')) {
          print(
            '[ChatRemoteDataSource] Upload URL or File Key not found in presigned data.',
          );
          return Right(
            ApiError(
              message: 'Upload URL or File Key not found in presigned data',
            ),
          );
        }

        final uploadUrl = presignedUrlData['uploadUrl'] as String;
        uploadedFileKey = presignedUrlData['fileKey'] as String;

        final uploadResult = await uploadImageToS3(
          uploadUrl: uploadUrl,
          imageFile: imageFile,
        );

        if (uploadResult.isRight()) {
          final error = uploadResult.fold(
            (_) => ApiError(message: 'Unknown error during image upload'),
            (error) => error,
          );
          print(
            '[ChatRemoteDataSource] Failed to upload image: ${error.message}',
          );
          return Right(error);
        }
      }

      final payload = {
        'content':
            content.trim().isEmpty && uploadedFileKey != null
                ? ''
                : content
                    .trim(), // Send empty string for content if only image, else trimmed content
        'chatRoomId': chatRoomId,
        'attachments':
            uploadedFileKey != null
                ? [
                  {
                    'fileKey': uploadedFileKey,
                    'fileType':
                        lookupMimeType(imageFile!.path) ??
                        imageFile.path
                            .split('.')
                            .lastWhere((e) => true, orElse: () => 'binary'),
                    'fileName': imageFile.path.split('/').last,
                  },
                ]
                : [],
      };

      if (content.trim().isEmpty && uploadedFileKey == null) {
        print(
          '[ChatRemoteDataSource] Cannot send message: No content or image provided.',
        );
        return Right(ApiError(message: 'Cannot send empty message'));
      }

      print('[ChatRemoteDataSource] Sending message with payload: $payload');
      final response = await _api.postApi(AppUrl.sendMessage, payload);

      print(
        '[ChatRemoteDataSource] Response Status for Send Message: ${response.statusCode}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final decodedJson = jsonDecode(response.body);
          // Backend sends the created message under the 'data' key
          if (decodedJson['data'] != null &&
              decodedJson['data'] is Map<String, dynamic>) {
            final messageData = decodedJson['data'] as Map<String, dynamic>;
            final sentMessage = MessageModel.fromJson(messageData);
            return Left(Result.success(sentMessage));
          } else {
            print(
              '[ChatRemoteDataSource] Failed to send message: Response data format invalid or missing message object.',
            );
            return Right(
              ApiError(
                message:
                    decodedJson['message'] ??
                    'Failed to send message (API response structure error)',
              ),
            );
          }
        } catch (e, stackTrace) {
          print(
            '[ChatRemoteDataSource] Error parsing SendMessage response body: $e\n$stackTrace',
          );
          return Right(
            ApiError(
              message: 'Failed to send message (response parsing error)',
            ),
          );
        }
      } else {
        String errorMessage = 'Failed to send message';
        try {
          final decodedJson = jsonDecode(response.body);
          errorMessage = decodedJson['message'] ?? errorMessage;
        } catch (_) {}
        print(
          '[ChatRemoteDataSource] Error sending message: $errorMessage (Status code: ${response.statusCode})',
        );
        return Right(
          ApiError(message: '$errorMessage (Status: ${response.statusCode})'),
        );
      }
    } catch (e, stackTrace) {
      print(
        '[ChatRemoteDataSource] Exception sending message: $e\n$stackTrace',
      );
      return Right(
        ApiError(message: 'Exception sending message: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Result<String>, ApiError>> updateLastReadMessages({
    required int chatRoomId,
  }) async {
    try {
      final response = await _api.putApi(
        '${AppUrl.updateLastReadMessages}/$chatRoomId',
        {},
      );

      print(
        '[ChatRemoteDataSource] Response Status for Mark as Read: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final decodedJson = jsonDecode(response.body);
        // Backend ApiResponse has a 'success' boolean and a 'message' string.
        // { "success": true, "message": "Marked all messages as read", "data": {} }
        if (decodedJson['success'] == true) {
          return Left(
            Result.success(
              decodedJson['message'] ?? "Last read updated successfully",
            ),
          );
        } else {
          print(
            '[ChatRemoteDataSource] Failed to update last read (API logic): ${decodedJson['message']}',
          );
          return Right(
            ApiError(
              message:
                  decodedJson['message'] ??
                  'Failed to update last read messages (API)',
            ),
          );
        }
      } else {
        String errorMessage = 'Failed to update last read messages';
        try {
          final decodedJson = jsonDecode(response.body);
          errorMessage = decodedJson['message'] ?? errorMessage;
        } catch (_) {}
        print(
          '[ChatRemoteDataSource] Failed to update last read. Status: ${response.statusCode}, Message: $errorMessage',
        );
        return Right(
          ApiError(
            message: '$errorMessage (Status code: ${response.statusCode})',
          ),
        );
      }
    } catch (e, stackTrace) {
      print(
        '[ChatRemoteDataSource] Exception updating last read messages: $e\n$stackTrace',
      );
      return Right(
        ApiError(
          message: 'Exception updating last read messages: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<Either<Result<MessageModel>, ApiError>> replyToMessage({
    required int parentMessageId,
    required String content,
  }) async {
    try {
      final url = '${AppUrl.replyToMessage}/$parentMessageId';
      final payload = {'content': content.trim()};

      print(
        '[ChatRemoteDataSource] Replying to message $parentMessageId via POST to: $url with content: "${content.trim()}"',
      );
      final response = await _api.postApi(url, payload);

      print(
        '[ChatRemoteDataSource] Response Status for Reply: ${response.statusCode}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decodedJson = jsonDecode(response.body);
        // Backend sends the created reply message (with nested parentMessage) under 'data' key
        if (decodedJson['data'] != null &&
            decodedJson['data'] is Map<String, dynamic>) {
          final messageData = decodedJson['data'] as Map<String, dynamic>;
          final repliedMessage = MessageModel.fromJson(messageData);
          print(
            '[ChatRemoteDataSource] Reply successful, received message: ${repliedMessage.id}',
          );
          return Left(Result.success(repliedMessage));
        } else {
          print(
            '[ChatRemoteDataSource] Error: Reply response data format invalid (missing/invalid "data" field).',
          );
          return Right(
            ApiError(
              message:
                  decodedJson['message'] ??
                  'Reply response data format invalid',
            ),
          );
        }
      } else {
        String errorMessage = 'Failed to reply to message';
        try {
          final decodedJson = jsonDecode(response.body);
          errorMessage = decodedJson['message'] ?? errorMessage;
        } catch (_) {}
        print(
          '[ChatRemoteDataSource] Error replying to message: $errorMessage (Status code: ${response.statusCode})',
        );
        return Right(
          ApiError(message: '$errorMessage (Status: ${response.statusCode})'),
        );
      }
    } catch (e, stackTrace) {
      print(
        '[ChatRemoteDataSource] Exception replying to message: $e\n$stackTrace',
      );
      return Right(
        ApiError(message: 'Exception replying to message: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Result<Map<String, dynamic>>, ApiError>> getPresignedUrl({
    required String fileType,
    String folder = 'uploads/messages',
    String fileName = 'file',
  }) async {
    try {
      final response = await _api.postApi(AppUrl.generateUploadUrl, {
        'fileType': fileType,
        'folder': folder,
        'fileName': fileName,
      });

      print(
        '[ChatRemoteDataSource] Response Status for Presigned URL: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final decodedJson = jsonDecode(response.body);
        // Expects { data: { uploadUrl: "...", fileKey: "..." } }
        if (decodedJson['data'] is Map<String, dynamic>) {
          final responseData = decodedJson['data'] as Map<String, dynamic>;
          if (responseData.containsKey('uploadUrl') &&
              responseData.containsKey('fileKey')) {
            return Left(Result.success(responseData));
          } else {
            print(
              '[ChatRemoteDataSource] Upload URL or File Key missing in presigned URL response data.',
            );
            return Right(
              ApiError(
                message:
                    decodedJson['message'] ??
                    'Presigned URL data missing required fields',
              ),
            );
          }
        } else {
          print(
            '[ChatRemoteDataSource] Presigned URL data format invalid (missing/invalid "data" field).',
          );
          return Right(
            ApiError(
              message:
                  decodedJson['message'] ?? 'Presigned URL data format invalid',
            ),
          );
        }
      } else {
        String errorMessage = 'Failed to generate upload URL';
        try {
          final decodedJson = jsonDecode(response.body);
          errorMessage = decodedJson['message'] ?? errorMessage;
        } catch (_) {}
        print(
          '[ChatRemoteDataSource] Error generating upload URL: $errorMessage (Status code: ${response.statusCode})',
        );
        return Right(
          ApiError(message: '$errorMessage (Status: ${response.statusCode})'),
        );
      }
    } catch (e, stackTrace) {
      print(
        '[ChatRemoteDataSource] Exception generating upload URL: $e\n$stackTrace',
      );
      return Right(
        ApiError(message: 'Exception generating upload URL: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Result<String>, ApiError>> uploadImageToS3({
    required String uploadUrl,
    required File imageFile,
  }) async {
    try {
      final uri = Uri.parse(uploadUrl);
      final fileBytes = await imageFile.readAsBytes();
      final String mimeType =
          lookupMimeType(imageFile.path) ?? 'application/octet-stream';

      final response = await http.put(
        uri,
        headers: {'Content-Type': mimeType},
        body: fileBytes,
      );

      print(
        '[ChatRemoteDataSource] Response Status for Image Upload to S3: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        return Left(Result.success('Image uploaded successfully to S3'));
      } else {
        String errorMessage =
            'Failed to upload image to S3. Status: ${response.statusCode}';
        // S3 often returns XML errors, body might not be JSON.
        print(
          '[ChatRemoteDataSource] Failed to upload image to S3. Body: ${response.body}',
        );
        if (response.body.isNotEmpty) {
          // Basic check if it's XML, a more robust XML parsing could be added if needed.
          if (response.body.trim().startsWith('<?xml')) {
            errorMessage =
                'S3 Upload failed (Status: ${response.statusCode}, check S3 logs/permissions)';
          } else {
            errorMessage =
                'S3 Upload failed (Status: ${response.statusCode}, Body: ${response.body.substring(0, (response.body.length > 100 ? 100 : response.body.length))})';
          }
        }
        return Right(ApiError(message: errorMessage));
      }
    } catch (e, stackTrace) {
      print(
        '[ChatRemoteDataSource] Exception uploading image to S3: $e\n$stackTrace',
      );
      return Right(
        ApiError(message: 'Exception uploading image to S3: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Result<ChatRoomModel>, ApiError>> fetchChatRoomDetails({
    required int chatRoomId,
  }) async {
    try {
      final url = '${AppUrl.getChatRoomDetails}/$chatRoomId';
      print('[ChatRemoteDataSource] Fetching chat room details from: $url');

      final response = await _api.getApi(url);
      print(
        '[ChatRemoteDataSource] Response Status for Chat Room Details: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final decodedJson = jsonDecode(response.body);
        // The backend's getChatRoomDetails controller (/getChatRoomDetail/:chatRoomId)
        // returns the chat room object (including users, and potentially initial messages/pagination)
        // directly within the 'data' field of the ApiResponse.
        // Example: { success: true, data: { id: ..., name: ..., users: [...], messages: [...], ... } }
        // ChatRoomModel.fromJson expects a map that directly represents the chat room.
        if (decodedJson['data'] != null &&
            decodedJson['data'] is Map<String, dynamic>) {
          final chatRoomData = decodedJson['data'] as Map<String, dynamic>;
          final chatRoomModel = ChatRoomModel.fromJson(chatRoomData);
          return Left(Result.success(chatRoomModel));
        } else {
          print(
            '[ChatRemoteDataSource] Error: Chat room data is missing or null in response for fetchChatRoomDetails.',
          );
          return Right(
            ApiError(
              message:
                  decodedJson['message'] ??
                  'Failed to fetch chat room details: Data is missing or null.',
            ),
          );
        }
      } else {
        String errorMessage = 'Failed to fetch chat room details';
        try {
          final decodedJson = jsonDecode(response.body);
          errorMessage = decodedJson['message'] ?? errorMessage;
        } catch (_) {}
        print(
          '[ChatRemoteDataSource] Error fetching chat room details: $errorMessage (Status code: ${response.statusCode})',
        );
        return Right(
          ApiError(
            message: '$errorMessage (Status code: ${response.statusCode})',
          ),
        );
      }
    } catch (e, stackTrace) {
      print(
        '[ChatRemoteDataSource] Exception fetching chat room details: $e\n$stackTrace',
      );
      return Right(
        ApiError(
          message: 'Exception fetching chat room details: ${e.toString()}',
        ),
      );
    }
  }

  Future<Either<Result<String>, ApiError>> removeUserFromChatRoom({
    required String chatRoomId,
    required String targetUserId,
  }) async {
    final url = '${AppUrl.removeUser}/$chatRoomId/$targetUserId';
    print(
      '[ChatRemoteDataSource] Requested to remove user from chatGroup: $url',
    );

    final response = await _api.deleteApi(url);

    print(
      '[ChatRemoteDataSource] Response Status for remove user from chatGroup: ${response.statusCode}',
    );
    if (response.statusCode == 200) {
      final decodedJson = jsonDecode(response.body);

      if (decodedJson['message'] != null) {
        final message = decodedJson['message'];
        return Left(Result.success(message));
      } else {
        print('[ChatRemoteDataSource] Error: Error removing user');
        return Right(
          ApiError(
            message: decodedJson['message'] ?? 'Error: Error removing user',
          ),
        );
      }
    } else {
      String errorMessage = 'Error: Error removing user';
      try {
        final decodedJson = jsonDecode(response.body);
        errorMessage = decodedJson['message'] ?? errorMessage;
      } catch (_) {}
      print(
        '[ChatRemoteDataSource] Error: Error removing users: $errorMessage (Status code: ${response.statusCode})',
      );
      return Right(
        ApiError(
          message: '$errorMessage (Status code: ${response.statusCode})',
        ),
      );
    }
  }
}
