class UserEntity {
  final int id;
  final String? name;
  final String? email;
  final int? traccarId;
  final DateTime? created_at;
  final DateTime? updated_at;
  final bool? isVerified;
  final String? verificationToken;
  final String? resetToken;
  final String? message;
  final String? jwtRefreshToken;
  final String? jwtAccessToken;
  final String? traccarToken;
  final String? profileImageKey;

  UserEntity({
    required this.jwtRefreshToken,
    required this.jwtAccessToken,
    required this.traccarToken,
    required this.id,
    required this.name,
    required this.email,
    required this.traccarId,
    required this.created_at,
    required this.updated_at,
    required this.isVerified,
    this.verificationToken = ' ',
    this.resetToken = ' ',
    this.message = '',
    this.profileImageKey = '',
  });
}
