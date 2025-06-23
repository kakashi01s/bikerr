import 'package:bikerr/features/auth/data/models/user_model.dart';
import 'package:bikerr/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bikerr/utils/apiResult/api_error.dart';
import 'package:bikerr/utils/apiResult/result.dart';
import 'package:dartz/dartz.dart';

class ForgotPasswordUsecase {
  final AuthRepositoryImpl authRepositoryImpl;

  ForgotPasswordUsecase({required this.authRepositoryImpl});

  Future<Either<Result<String>, ApiError>> forgotPassword({
    required String email,
  }) async {
    return await authRepositoryImpl.forgotPassword(email: email);
  }

  Future<Either<Result<UserModel>, ApiError>> verifyForgorPasswordOtp({
    required String email,
    required String token,
  }) async {
    return await authRepositoryImpl.verifyForgotPasswordOtp(
      email: email,
      token: token,
    );
  }

  Future<Either<Result<UserModel>, ApiError>> resetPassword({
    required String email,
    required String password,
    required String token,
  }) async {
    return await authRepositoryImpl.resetPassword(
      email: email,
      token: token,
      password: password,
    );
  }
}
