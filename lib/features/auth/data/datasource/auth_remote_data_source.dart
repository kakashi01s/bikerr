import 'dart:convert';

import 'package:bikerr/config/constants.dart';
import 'package:bikerr/features/auth/data/models/user_model.dart';
import 'package:bikerr/utils/apiResult/api_error.dart';
import 'package:bikerr/utils/apiResult/result.dart';
import 'package:bikerr/utils/exceptions/app_exceptions.dart';
import 'package:bikerr/utils/network/network_api_services.dart';
import 'package:dartz/dartz.dart';

class AuthRemoteDataSource {
  final _api = NetworkServicesApi();

  Future<Either<Result<String>, ApiError>> refreshAccessToken({
    required String refreshToken,
  }) async {
    final Map<String, dynamic> data = {'refreshToken': refreshToken};

    try {
      // Let AuthenticationFailedException propagate from _api.postApi
      final response = await _api.postApi(AppUrl.refreshAccessToken, data);
      final resp = jsonDecode(response.body);
      print("Refresh token response: ${resp}");

      // The success case should return the new access token
      if (response.statusCode == 200) {
        // Ensure 'data' and 'accessToken' keys exist before accessing
        final newAccessToken = resp['data']?['accessToken'];
        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          return Left(Result.success(newAccessToken));
        } else {
          // This case might be caught by NetworkServicesApi._refreshAccessToken as a failure
          // but adding a check here provides robustness.
          throw FetchDataException(
            "Refresh token endpoint did not return a valid access token.",
          );
        }
      } else {
        // Handle API errors returned by the refresh endpoint that are NOT 401/403
        // NetworkServicesApi should throw AuthenticationFailedException for 401/403
        // If we reach here for a non-200, it's likely handled by FetchDataException in _sendRequest
        // But if the backend returns a non-401/403 error structure, handle it as ApiError
        return Right(
          ApiError(message: resp['message'] ?? 'Unknown refresh token error'),
        );
      }
    } on AuthenticationFailedException {
      // **Crucially, re-throw the specific exception**
      rethrow;
    } catch (e) {
      // Catch any other unexpected exceptions during the datasource logic
      print("Error refreshing access token in datasource: $e");
      return Right(ApiError(message: e.toString()));
    }
  }

  Future<Either<Result<UserModel>, ApiError>> register({
    required String email,
    required String name,
    required String password,
  }) async {
    final Map<String, dynamic> data = {
      'email': email,
      'password': password,
      'name': name,
    };
    try {
      final response = await _api.postApi(AppUrl.registerApi, data);
      final resp = jsonDecode(response.body);
      print("Response returned is:  ${resp['data']["newUser"]}");
      var dt = UserModel.fromJson(resp['data']['newUser']);
      if (response.statusCode == 200) {
        return Left(Result.success(dt));
      } else {
        // NetworkServicesApi should handle throwing based on status codes >= 400
        // If we reach here, it means _api.postApi returned a non-exception error.
        return Right(
          ApiError(message: resp['message'] ?? 'Unknown registration error'),
        );
      }
    } on AuthenticationFailedException {
      rethrow; // Re-throw auth errors
    } catch (e) {
      print("Error during registration datasource: $e");
      return Right(ApiError(message: e.toString()));
    }
  }

  Future<Either<Result<UserModel>, ApiError>> verifyEmail({
    required String email,
    required String token,
    required int userId,
    required String password,
  }) async {
    final Map<String, dynamic> data = {
      'token': token,
      'userId': userId,
      'email': email,
      'password': password,
    };
    print("Runnig in verifyEmail datasource : ${email}");
    try {
      final response = await _api.postApi(AppUrl.verifyEmail, data);
      final resp = jsonDecode(response.body);
      print("Printing response in verifyEmail datasource ${resp['data']}");
      if (response.statusCode == 200) {
        return Left(Result.success(UserModel.fromJson(resp['data']['user'])));
      } else {
        // NetworkServicesApi should handle throwing based on status codes >= 400
        return Right(
          ApiError(
            message: resp['message'] ?? 'Unknown email verification error',
          ),
        );
      }
    } on AuthenticationFailedException {
      rethrow; // Re-throw auth errors
    } catch (e) {
      print("Error while verifying user: $e");
      return Right(ApiError(message: e.toString()));
    }
  }

  Future<Either<Result<UserModel>, ApiError>> login({
    required String email,
    required String password,
  }) async {
    final Map<String, dynamic> data = {'email': email, 'password': password};

    print("Runnig in login remote datasource : ${email}");
    try {
      final response = await _api.postApi(AppUrl.loginApi, data);
      final resp = jsonDecode(response.body);
      print("Printing response in login datasource ${resp['data']}");
      if (response.statusCode == 200) {
        // Assuming the login response includes tokens and user data directly in the data field
        final userDataJson = resp['data']?['user'];
        if (userDataJson != null) {
          final user = UserModel.fromJson(userDataJson);
          // Login success response should contain tokens for SessionManager
          // Extract tokens and user data here and pass to the domain/usecase layer
          // The usecase or Bloc is responsible for saving the session
          return Left(
            Result.success(user),
          ); // Return the user model which includes tokens
        } else {
          throw FetchDataException(
            "Login successful but user data is missing from response.",
          );
        }
      } else {
        // NetworkServicesApi should handle throwing based on status codes >= 400
        return Right(
          ApiError(message: resp['message'] ?? 'Unknown login error'),
        );
      }
    } on AuthenticationFailedException {
      rethrow; // Re-throw auth errors
    } catch (e) {
      print("Error while logging in datasource: $e");
      return Right(ApiError(message: e.toString()));
    }
  }

  Future<Either<Result<String>, ApiError>> forgotPassword({
    required String email,
  }) async {
    final Map<String, dynamic> data = {'email': email};

    print(("Running in forgot password Auth remote data source"));

    final response = await _api.postApi(AppUrl.forgotPassword, data);

    final resp = jsonDecode(response.body);
    print("Printing response in forgot password datasource ${resp['message']}");

    try {
      if (response.statusCode == 200) {
        return Left(Result.success(resp['message']));
      } else {
        return Right(ApiError(message: resp['message']));
      }
    } catch (e) {
      print("Error while verifying user: $e");
      return Right(ApiError(message: e.toString()));
    }
  }

  Future<Either<Result<UserModel>, ApiError>> verifyForgotPasswordOtp({
    required String token,
    required String email,
  }) async {
    final Map<String, dynamic> data = {'email': email, 'token': token};

    print(("Running in verify forgot password Auth remote data source"));

    final response = await _api.postApi(AppUrl.verifyForgotPasswordOtp, data);

    final resp = jsonDecode(response.body);
    print(
      "Printing response in verify forgot password otp datasource ${resp['data']}",
    );

    try {
      if (response.statusCode == 200) {
        return Left(Result.success(UserModel.fromJson(resp['data']['user'])));
      } else {
        return Right(ApiError(message: resp['message']));
      }
    } catch (e) {
      print("Error while verifying user: $e");
      return Right(ApiError(message: e.toString()));
    }
  }

  Future<Either<Result<UserModel>, ApiError>> resetPassword({
    required String email,
    required String password,
    required String token,
  }) async {
    final Map<String, dynamic> data = {
      'email': email,
      'token': token,
      'password': password,
    };

    print(("Running in reset password  Auth remote data source"));

    final response = await _api.postApi(AppUrl.resetPassword, data);

    final resp = jsonDecode(response.body);
    print("Printing response in reset password otp datasource ${resp['data']}");

    try {
      if (response.statusCode == 200) {
        return Left(Result.success(UserModel.fromJson(resp['data']['user'])));
      } else {
        return Right(ApiError(message: resp['message']));
      }
    } catch (e) {
      print("Error while verifying user: $e");
      return Right(ApiError(message: e.toString()));
    }
  }
}
