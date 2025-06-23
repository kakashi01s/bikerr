import 'package:bikerr/features/auth/domain/entity/user_entity.dart';

class UserModel extends UserEntity {
  UserModel({
    required int id,
    required String name,
    required String email,
    required int? traccarId,
    required DateTime created_at,
    required DateTime updated_at,
    required bool isVerified,
    required String jwtRefreshToken,
    required String jwtAccessToken,
    required String traccarToken,
    required String profileImageKey,

    require,
  }) : super(
         id: id,
         name: name,
         email: email,
         traccarId: traccarId,
         created_at: created_at,
         updated_at: updated_at,
         isVerified: isVerified,
         jwtRefreshToken: jwtRefreshToken,
         jwtAccessToken: jwtAccessToken,
         traccarToken: traccarToken,
         profileImageKey: profileImageKey,
       );

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0, // Default to 0 if id is null
      name:
          json['name'] ?? 'Unknown', // Default to 'Unknown' if name is missing
      email: json['email'] ?? 'Unknown',
      traccarId:
          json['traccarId'] != null
              ? json['traccarId'] as int?
              : null, // Allow null for traccarId
      created_at: DateTime.parse(
        json['created_at'] ?? '1970-01-01T00:00:00.000Z',
      ), // Fallback to a default date if null
      updated_at: DateTime.parse(
        json['updated_at'] ?? '1970-01-01T00:00:00.000Z',
      ), // Fallback to a default date if null
      isVerified: json['isVerified'] ?? false, // Default to false if null
      jwtRefreshToken: json['refreshToken'] ?? '',
      jwtAccessToken: json['accessToken'] ?? '',
      traccarToken: json['traccarToken'] ?? '',
      profileImageKey: json['profileImageKey'] ?? '',
    );
  }
}
