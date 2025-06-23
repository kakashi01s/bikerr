import 'package:bikerr/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bikerr/features/auth/domain/entity/user_entity.dart';
import 'package:bikerr/utils/apiResult/api_error.dart';
import 'package:bikerr/utils/apiResult/result.dart';
import 'package:dartz/dartz.dart';

class VerifyEmailUsecase {
  final AuthRepositoryImpl repositoryImpl;

  VerifyEmailUsecase({required this.repositoryImpl});

  Future<Either<Result<UserEntity>, ApiError>> call({
    required String email,
    required int userId,
    required String token,
    required String password,
  }) async {
    return await repositoryImpl.verifyEmail(
      token: token,
      userId: userId,
      email: email,
      password: password,
    );
  }
}
