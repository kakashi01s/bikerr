import 'package:bikerr/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bikerr/utils/apiResult/api_error.dart';
import 'package:bikerr/utils/apiResult/result.dart';
import 'package:dartz/dartz.dart';

class RefeshTokenUsecase {
  final AuthRepositoryImpl authRepositoryImpl;

  RefeshTokenUsecase({required this.authRepositoryImpl});

  Future<Either<Result<String>, ApiError>> call({
    required String refreshToken,
  }) async {
    return await authRepositoryImpl.refreshAccessToken(
      refreshToken: refreshToken,
    );
  }
}
