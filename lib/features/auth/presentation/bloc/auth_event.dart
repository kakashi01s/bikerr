part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class EmailChanged extends AuthEvent {
  final String email;

  const EmailChanged({required this.email});

  @override
  List<Object?> get props => [email];
}

class Otp1Changed extends AuthEvent {
  final String num;

  const Otp1Changed({required this.num});

  @override
  List<Object?> get props => [num];
}

class Otp2Changed extends AuthEvent {
  final String num;

  const Otp2Changed({required this.num});

  @override
  List<Object?> get props => [num];
}

class Otp3Changed extends AuthEvent {
  final String num;

  const Otp3Changed({required this.num});

  @override
  List<Object?> get props => [num];
}

class Otp4Changed extends AuthEvent {
  final String num;

  const Otp4Changed({required this.num});

  @override
  List<Object?> get props => [num];
}

class Otp5Changed extends AuthEvent {
  final String num;

  const Otp5Changed({required this.num});

  @override
  List<Object?> get props => [num];
}

class Otp6Changed extends AuthEvent {
  final String num;

  const Otp6Changed({required this.num});

  @override
  List<Object?> get props => [num];
}

class NameChanged extends AuthEvent {
  final String name;

  const NameChanged({required this.name});
  @override
  List<Object?> get props => [name];
}

class PasswordChanged extends AuthEvent {
  final String password;

  const PasswordChanged({required this.password});
  @override
  List<Object?> get props => [password];
}

class ConfirmPasswordChanged extends AuthEvent {
  final String confirmPassword;

  const ConfirmPasswordChanged({required this.confirmPassword});
  @override
  List<Object?> get props => [confirmPassword];
}

class RegisterEvent extends AuthEvent {}

class VerifyEmail extends AuthEvent {
  final String email;
  final String password;
  final int userId;

  const VerifyEmail({
    required this.userId,
    required this.email,
    required this.password,
  });

  @override
  // TODO: implement props
  List<Object?> get props => [userId, email, password];
}

class LoginEvent extends AuthEvent {}

class ForgotPassword extends AuthEvent {}

class VerifyForgotPasswordOtp extends AuthEvent {
  final String email;

  VerifyForgotPasswordOtp({required this.email});

  @override
  List<Object?> get props => [email];
}

class ResetPassword extends AuthEvent {
  final String email;
  final String token;

  ResetPassword({required this.email, required this.token});

  @override
  List<Object?> get props => [email, token];
}

class RefreshAccessTokenEvent extends AuthEvent {}

class LogoutEvent extends AuthEvent {}
