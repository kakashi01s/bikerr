import 'package:bikerr/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bikerr/features/auth/domain/entity/user_entity.dart';
import 'package:bikerr/utils/apiResult/api_error.dart';
import 'package:bikerr/utils/apiResult/result.dart';
import 'package:dartz/dartz.dart';

class RegisterUsecase {
  final AuthRepositoryImpl repositoryImpl;

  RegisterUsecase({required this.repositoryImpl});

  Future<Either<Result<UserEntity>, ApiError>> call({
    required String name,
    required String email,
    required String password,
  }) async {
    return await repositoryImpl.register(
      email: email,
      name: name,
      password: password,
    );
  }
}
