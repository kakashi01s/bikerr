import 'dart:convert';

import 'package:bikerr/config/constants.dart';
import 'package:bikerr/utils/apiResult/api_error.dart';
import 'package:bikerr/utils/apiResult/result.dart';
import 'package:bikerr/utils/network/network_api_services.dart';
import 'package:dartz/dartz.dart';

class ConversationRemoteDataSource {
  final _api = NetworkServicesApi();

  Future<Either<Result<Map<String, dynamic>>, ApiError>>
  getAllUserConversations({int? page, int? limit}) async {
    final queryParameters = <String, dynamic>{};
    if (page != null) {
      queryParameters['page'] = page.toString();
    }
    if (limit != null) {
      queryParameters['limit'] = limit.toString();
    }

    final response = await _api.getApi(
      AppUrl.getAllUserConversations,
      queryParameters: queryParameters,
    );

     print('CONVERSATION RESPONSE STATUS ====> ${response.statusCode}');
       print('CONVERSATION RESPONSE BODY ====> ${response.body}');

    if (response.statusCode == 200) {
      final decodedJson = jsonDecode(response.body);
      //   print('JSON CONVERSATION DATA =======>   $decodedJson');
      return Left(Result.success(decodedJson as Map<String, dynamic>));
    } else if (response.statusCode == 404){
      return Right(ApiError(message: "No Messages Found"));
    }
    else {
      return Right(ApiError(message: 'Failed to Fetch Conversations'));
    }
  }

  Future<Either<Result<Map<String, dynamic>>, ApiError>> getAllChatGroups({
    int? page,
    int? limit,
  }) async {
    final queryParameters = <String, dynamic>{};
    if (page != null) {
      queryParameters['page'] = page.toString();
    }
    if (limit != null) {
      queryParameters['limit'] = limit.toString();
    }

    final response = await _api.getApi(
      AppUrl.getAllChatRooms,
      queryParameters: queryParameters,
    );

    //  print('CONVERSATION RESPONSE STATUS ====> ${response.statusCode}');
       print('CONVERSATION RESPONSE BODY ====> ${response.body}');

    if (response.statusCode == 200) {
      final decodedJson = jsonDecode(response.body);
      //   print('JSON CONVERSATION DATA =======>   $decodedJson');
      return Left(Result.success(decodedJson as Map<String, dynamic>));
    } else {
      return Right(ApiError(message: 'Failed to Fetch Conversations'));
    }
  }


  Future<Either<Result<Map<String, dynamic>>, ApiError>> joinNewChatGroup({
    required String chatRoomId, // Renamed from chatGroupId for clarity with route
    required String? userId, // userId is likely inferred from auth token on backend POST
  }) async {
    // Construct the URL with the chatRoomId in the path
    final url = "${AppUrl.joinNewChatRoom}/$chatRoomId"; // Assuming AppUrl.joinChatRoom is "/join"

    // Prepare the request body. userId might be included if backend explicitly needs it
    // but usually, it's extracted from the JWT token on the backend for POST requests.
    final Map<String, dynamic> requestBody = {};
    if (userId != null) {
      requestBody['userId'] = userId; // Include if your backend needs it explicitly in body
    }

    try {
      final response = await _api.postApi(
        url,       // The full URL with chatRoomId
        requestBody, // The body for the POST request
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // 200 OK or 201 Created (common for successful resource creation/modification)
        final decodedJson = jsonDecode(response.body);
        return Left(Result.success(decodedJson as Map<String, dynamic>));
      } else {
        // Handle API errors (e.g., 400 Bad Request, 401 Unauthorized, 404 Not Found)
        // Attempt to parse the error message from the response body
        String errorMessage = 'Failed to join chat room.';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (e) {
          // If body is not JSON or message key is absent
          print('Error parsing error response body: $e');
        }
        return Right(ApiError(message: errorMessage, statusCode: response.statusCode));
      }
    } catch (e) {
      // Handle network errors (e.g., no internet connection)
      return Right(ApiError(message: 'Network error: $e'));
    }
  }

}

