import 'package:bikerr/features/auth/data/models/user_model.dart';
import 'package:bikerr/utils/apiResult/api_error.dart';
import 'package:bikerr/utils/apiResult/result.dart';
import 'package:dartz/dartz.dart';

abstract class AuthRepository {
  // register repository
  Future<Either<Result<UserModel>, ApiError>> register({
    required String email,
    required String name,
    required String password,
  });

  Future<Either<Result<UserModel>, ApiError>> verifyEmail({
    required String email,
    required String token,
    required int userId,
    required String password,
  });

  Future<Either<Result<UserModel>, ApiError>> login({
    required String email,
    required String password,
  });

  Future<Either<Result<String>, ApiError>> forgotPassword({
    required String email,
  });

  Future<Either<Result<UserModel>, ApiError>> verifyForgotPasswordOtp({
    required String email,
    required String token,
  });
  Future<Either<Result<UserModel>, ApiError>> resetPassword({
    required String email,
    required String token,
    required String password,
  });
  Future<Either<Result<String>, ApiError>> refreshAccessToken({
    required String refreshToken,
  });
}
