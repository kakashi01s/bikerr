// In lib/features/auth/presentation/bloc/auth_state.dart

part of 'auth_bloc.dart';

class AuthState extends Equatable {
  final int id;
  final String name;
  final String email;
  final int traccarId;
  final String verificationToken;
  final String password;
  final String confirmPassword;
  final PostApiStatus postApiStatus;
  final String message;
  final String otp1;
  final String otp2;
  final String otp3;
  final String otp4;
  final String otp5;
  final String otp6;
  final String? refreshToken; // Make nullable as it might be cleared
  final String? accessToken; // Make nullable as it might be cleared

  // --- ADD THIS FIELD ---
  final bool requiresReauthentication; // New field
  // --------------------

  const AuthState({
    this.id = 0,
    this.name = '',
    this.email = '',
    this.verificationToken = '',
    this.traccarId = 0,
    this.password = '',
    this.confirmPassword = '',
    this.message = '',
    this.postApiStatus = PostApiStatus.initial,
    this.otp1 = '',
    this.otp2 = '',
    this.otp3 = '',
    this.otp4 = '',
    this.otp5 = '',
    this.otp6 = '',
    this.refreshToken, // Default is null
    this.accessToken, // Default is null
    // --- Initial value for new field ---
    this.requiresReauthentication = false, // Default to false
    // -----------------------------------
  });

  // --- UPDATED copyWith method ---
  AuthState copywith({
    int? id,
    String? name,
    String? email,
    int? traccarId,
    String? verificationToken,
    String? password,
    String? confirmPassword,
    PostApiStatus? postApiStatus,
    String? message,
    String? otp1,
    String? otp2,
    String? otp3,
    String? otp4,
    String? otp5,
    String? otp6,
    String? refreshToken, // Keep nullable
    String? accessToken, // Keep nullable
    // --- New parameter for new field ---
    bool? requiresReauthentication, // Parameter for the new field
    // -----------------------------------
  }) {
    return AuthState(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      traccarId: traccarId ?? this.traccarId,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      postApiStatus: postApiStatus ?? this.postApiStatus,
      message: message ?? this.message,
      verificationToken: verificationToken ?? this.verificationToken,
      otp1: otp1 ?? this.otp1,
      otp2: otp2 ?? this.otp2,
      otp3: otp3 ?? this.otp3,
      otp4: otp4 ?? this.otp4,
      otp5: otp5 ?? this.otp5,
      otp6: otp6 ?? this.otp6,
      refreshToken: refreshToken ?? this.refreshToken,
      accessToken: accessToken ?? this.accessToken,
      // --- Assign new field ---
      requiresReauthentication:
          requiresReauthentication ?? this.requiresReauthentication,
      // --------------------------
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    traccarId,
    password,
    postApiStatus,
    message,
    confirmPassword,
    verificationToken,
    otp1,
    otp2,
    otp3,
    otp4,
    otp5,
    otp6,
    refreshToken,
    accessToken,
    // --- Include new field in props ---
    requiresReauthentication,
    // ----------------------------------
  ];
}
