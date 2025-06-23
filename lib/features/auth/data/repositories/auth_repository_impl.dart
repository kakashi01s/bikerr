import 'package:bikerr/features/auth/data/datasource/auth_remote_data_source.dart';
import 'package:bikerr/features/auth/data/models/user_model.dart';
import 'package:bikerr/features/auth/domain/repositories/auth_repository.dart';
import 'package:bikerr/utils/apiResult/api_error.dart';
import 'package:bikerr/utils/apiResult/result.dart';
import 'package:dartz/dartz.dart';

class AuthRepositoryImpl extends AuthRepository {
  final AuthRemoteDataSource authRemoteDataSource;

  AuthRepositoryImpl({required this.authRemoteDataSource});
  @override
  Future<Either<Result<UserModel>, ApiError>> register({
    required String email,
    required String name,
    required String password,
  }) async {
    return await authRemoteDataSource.register(
      email: email,
      name: name,
      password: password,
    );
  }

  @override
  Future<Either<Result<UserModel>, ApiError>> verifyEmail({
    required String token,
    required int userId,
    required String email,
    required String password,
  }) async {
    return await authRemoteDataSource.verifyEmail(
      email: email,
      token: token,
      userId: userId,
      password: password,
    );
  }

  @override
  Future<Either<Result<UserModel>, ApiError>> login({
    required String email,
    required String password,
  }) async {
    return await authRemoteDataSource.login(email: email, password: password);
  }

  @override
  Future<Either<Result<String>, ApiError>> forgotPassword({
    required String email,
  }) async {
    return await authRemoteDataSource.forgotPassword(email: email);
  }

  @override
  Future<Either<Result<UserModel>, ApiError>> resetPassword({
    required String email,
    required String token,
    required String password,
  }) async {
    return await authRemoteDataSource.resetPassword(
      email: email,
      password: password,
      token: token,
    );
  }

  @override
  Future<Either<Result<UserModel>, ApiError>> verifyForgotPasswordOtp({
    required String email,
    required String token,
  }) async {
    return await authRemoteDataSource.verifyForgotPasswordOtp(
      token: token,
      email: email,
    );
  }

  @override
  Future<Either<Result<String>, ApiError>> refreshAccessToken({
    required String refreshToken,
  }) async {
    return await authRemoteDataSource.refreshAccessToken(
      refreshToken: refreshToken,
    );
  }
}
