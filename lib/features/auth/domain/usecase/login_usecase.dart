import 'package:bikerr/features/auth/data/models/user_model.dart';
import 'package:bikerr/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bikerr/utils/apiResult/api_error.dart';
import 'package:bikerr/utils/apiResult/result.dart';
import 'package:dartz/dartz.dart';

class LoginUsecase {
  final AuthRepositoryImpl authRepositoryImpl;

  LoginUsecase({required this.authRepositoryImpl});

  Future<Either<Result<UserModel>, ApiError>> call({
    required String email,
    required String password,
  }) {
    return authRepositoryImpl.login(email: email, password: password);
  }
}
