import 'dart:async';

import 'package:bikerr/features/auth/domain/usecase/forgot_password_usecase.dart';
import 'package:bikerr/features/auth/domain/usecase/login_usecase.dart';
import 'package:bikerr/features/auth/domain/usecase/refesh_token_usecase.dart';
import 'package:bikerr/features/auth/domain/usecase/register_usecase.dart';
import 'package:bikerr/features/auth/domain/usecase/verify_email_usecase.dart';
import 'package:bikerr/services/session/session_manager.dart';
import 'package:bikerr/utils/enums/enums.dart';
import 'package:bikerr/utils/exceptions/app_exceptions.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:traccar_gennissi/traccar_gennissi.dart';
part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final RegisterUsecase registerUsecase;
  final VerifyEmailUsecase verifyEmailUsecase;
  final LoginUsecase loginUsecase;
  final ForgotPasswordUsecase forgotPasswordUsecase;
  final RefeshTokenUsecase refreshTokenUsecase;

  AuthBloc({
    required this.refreshTokenUsecase,
    required this.forgotPasswordUsecase,
    required this.registerUsecase,
    required this.verifyEmailUsecase,
    required this.loginUsecase,
  }) : super(const AuthState()) {
    // Use const with default constructor
    on<EmailChanged>(_onEmailChanged);
    on<PasswordChanged>(_onPasswordChanged);
    on<ConfirmPasswordChanged>(_onConfirmPasswordChanged);
    on<NameChanged>(_onNameChanged);
    on<RegisterEvent>(_onRegister);
    on<VerifyEmail>(_onVerifyEmail);
    on<Otp1Changed>(_onOtp1Changed);
    on<Otp2Changed>(_onOtp2Changed);
    on<Otp3Changed>(_onOtp3Changed);
    on<Otp4Changed>(_onOtp4Changed);
    on<Otp5Changed>(_onOtp5Changed);
    on<Otp6Changed>(_onOtp6Changed);
    on<LoginEvent>(_onLogin);
    on<ForgotPassword>(_onForgotPassword);
    on<VerifyForgotPasswordOtp>(_onVerifyForgotPasswordOtp);
    on<ResetPassword>(_onResetPassword);
    on<RefreshAccessTokenEvent>(_onRefreshAccessToken);
    on<LogoutEvent>(_onLogout); // Add handler for LogoutEvent
  }

  Future<void> _onRegister(RegisterEvent event, Emitter<AuthState> emit) async {
    print("AuthBloc: Running Register");
    try {
      emit(
        state.copywith(
          postApiStatus: PostApiStatus.loading,
          message: "Loading",
          requiresReauthentication: false, // Reset
        ),
      );
      print("Email in AuthBloc: ${state.email}");
      print("Password in AuthBloc: ${state.password}");

      // The usecase calls the repository, which calls the datasource.
      // AuthenticationFailedException might be thrown by the underlying API call.
      final result = await registerUsecase.call(
        name: state.name,
        email: state.email,
        password: state.password,
      );

      print("Result printed in AuthBloc: ${result}");

      result.fold(
        (success) {
          print("User id returned is ${success.data?.id}");
          emit(
            state.copywith(
              postApiStatus: PostApiStatus.success,
              message: success.data?.message ?? "User created Successfully",
              id: success.data!.id,
              email: success.data!.email,
              requiresReauthentication: false, // Successfully registered
            ),
          );
        },
        (error) {
          print("Error in Register $error");
          emit(
            state.copywith(
              postApiStatus: PostApiStatus.error,
              message: error.message, // Emit the String error message
              requiresReauthentication:
                  false, // It was a registration error, not reauth
            ),
          );
        },
      );
    } on AuthenticationFailedException catch (e) {
      // **CATCH THE SPECIFIC AUTHENTICATION FAILURE EXCEPTION (less likely for register, but possible)**
      print(
        "AuthBloc: Caught AuthenticationFailedException during registration: ${e.message}",
      );
      // This shouldn't happen during initial registration typically,
      // but handle it defensively if an underlying call requires auth unexpectedly.
      // Clear session and indicate reauth is required.
      await SessionManager.instance.clearSession();
      emit(
        state.copywith(
          postApiStatus: PostApiStatus.error, // Or specific status
          message: e.message,
          requiresReauthentication: true, // **THIS IS THE KEY FLAG**
        ),
      );
    } catch (e) {
      print("Error in Register try catch ${e}");
      emit(
        state.copywith(
          postApiStatus: PostApiStatus.error,
          message: e.toString(), // Emit the String error message
          requiresReauthentication: false, // Generic error
        ),
      );
    }
  }

  FutureOr<void> _onVerifyEmail(
    VerifyEmail event,
    Emitter<AuthState> emit,
  ) async {
    print("AuthBloc: Running Verify Email");
    try {
      emit(
        state.copywith(
          postApiStatus: PostApiStatus.loading,
          message: "Loading",
          requiresReauthentication: false, // Reset
        ),
      );
      print("Email in verify AuthBloc: ${event.email}");
      print("Password in verify AuthBloc: ${event.password}");
      print("UserId in verify AuthBloc: ${event.userId}");

      final otp =
          '${state.otp1}${state.otp2}${state.otp3}${state.otp4}${state.otp5}${state.otp6}';
      print("OTP in auth bloc verify: ${otp}");

      // The usecase calls the repository, which calls the datasource.
      // AuthenticationFailedException might be thrown by the underlying API call.
      final result = await verifyEmailUsecase.call(
        userId: event.userId,
        email: event.email,
        password: event.password,
        token: otp,
      );

      print("Result printed in AuthBloc: ${result}");

      result.fold(
        (success) {
          emit(
            state.copywith(
              postApiStatus: PostApiStatus.success,
              message: success.data?.message ?? "User created Successfully",
              requiresReauthentication: false, // Successfully verified
            ),
          );
        },
        (error) {
          print("Error in Verify Email $error");
          emit(
            state.copywith(
              postApiStatus: PostApiStatus.error,
              message: error.message, // Emit the String error message
              requiresReauthentication: false, // It was a verification error
            ),
          );
        },
      );
    } on AuthenticationFailedException catch (e) {
      // **CATCH THE SPECIFIC AUTHENTICATION FAILURE EXCEPTION (less likely for verify, but possible)**
      print(
        "AuthBloc: Caught AuthenticationFailedException during email verification: ${e.message}",
      );
      // This shouldn't happen during initial verification typically,
      // but handle it defensively. Clear session and indicate reauth needed.
      await SessionManager.instance.clearSession();
      emit(
        state.copywith(
          postApiStatus: PostApiStatus.error, // Or specific status
          message: e.message,
          requiresReauthentication: true, // **THIS IS THE KEY FLAG**
        ),
      );
    } catch (e) {
      emit(
        state.copywith(
          postApiStatus: PostApiStatus.error,
          message: e.toString(), // Emit the String error message
          requiresReauthentication: false, // Generic error
        ),
      );
    }
  }

  FutureOr<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    print("AuthBloc: Running Login");
    try {
      final SessionManager sessionManager = SessionManager.instance;
      emit(
        state.copywith(
          postApiStatus: PostApiStatus.loading,
          message: "Loading",
          requiresReauthentication: false, // Reset
        ),
      );
      print("Email in Login AuthBloc: ${state.email}");
      print("Password in Login AuthBloc: ${state.password}");

      // The usecase calls the repository, which calls the datasource.
      // AuthenticationFailedException might be thrown by the underlying API call
      // (e.g., if /login endpoint itself requires auth for some reason, unlikely but possible).
      final result = await loginUsecase.call(
        email: state.email,
        password: state.password,
      );

      print("Result printed in Login AuthBloc: ${result}");

      await result.fold(
        (success) async {
          // Login success response should contain tokens and user data
          final user = success.data!;
          print("User logged in successfully: ${user.id}");
          print("User traccar token: ${user.traccarToken}");

          // Save session data including tokens
          await sessionManager.setSession(
            userId: '${user.id}',
            traccarId: user.traccarId,
            jwtRefreshToken: user.jwtRefreshToken, // Use nullable properties
            jwtAccessToken: user.jwtAccessToken, // Use nullable properties
            traccarToken: user.traccarToken
          );
          print("Session data saved.");
          await Traccar.setBearerToken(user.traccarToken ?? "Empty Traccar Token", user.traccarId ?? 0);
          emit(
            state.copywith(
              postApiStatus: PostApiStatus.success,
              message:
                  "User Logged in Successfully", // User model doesn't have message
              id: user.id,
              email: user.email,
              // Update tokens in state (optional)
              refreshToken: user.jwtRefreshToken,
              accessToken: user.jwtAccessToken,
              requiresReauthentication: false, // Successfully authenticated
            ),
          );
          print("AuthBloc: Login success state emitted.");
        },
        (error) {
          print("Error in Login $error");
          emit(
            state.copywith(
              postApiStatus: PostApiStatus.error,
              message: error.message, // Emit the String error message
              requiresReauthentication:
                  false, // It was a login credential error, not reauth
            ),
          );
          print("AuthBloc: Login error state emitted.");
        },
      );
    } on AuthenticationFailedException catch (e) {
      // **CATCH THE SPECIFIC AUTHENTICATION FAILURE EXCEPTION (unlikely for login, but defensive)**
      print(
        "AuthBloc: Caught AuthenticationFailedException during login: ${e.message}",
      );
      // This is very unlikely for a /login endpoint, but handle defensively.
      // Clear session (it should already be cleared if this exception originated from NetworkServicesApi)
      await SessionManager.instance.clearSession();
      emit(
        state.copywith(
          postApiStatus: PostApiStatus.error, // Or specific status
          message: e.message,
          requiresReauthentication: true, // **THIS IS THE KEY FLAG**
        ),
      );
      print(
        "AuthBloc: State emitted with requiresReauthentication: true after login auth failure.",
      );
    } catch (e) {
      print("Error in Login try catch ${e}");
      emit(
        state.copywith(
          postApiStatus: PostApiStatus.error,
          message: e.toString(), // Emit the String error message
          requiresReauthentication: false, // Generic error
        ),
      );
      print("AuthBloc: Generic error state emitted during login.");
    }
  }

  // --- ADD LOGOUT HANDLER ---
  FutureOr<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    print("AuthBloc: Handling LogoutEvent");
    // Clear session data from storage
    await SessionManager.instance.clearSession();
    // Reset the state to unauthenticated/initial
    emit(
      const AuthState(requiresReauthentication: true),
    ); // Reset state, indicate reauth needed
    print("AuthBloc: Session cleared, state reset to unauthenticated.");
    // You might also want to navigate to the login screen here
    // (or have a listener in your main App widget for requiresReauthentication state)
  }
  // --------------------------

  FutureOr<void> _onRefreshAccessToken(
    RefreshAccessTokenEvent event,
    Emitter<AuthState> emit,
  ) async {
    print("AuthBloc: Handling RefreshAccessTokenEvent");
    emit(
      state.copywith(
        postApiStatus: PostApiStatus.loading,
        message: "Refreshing access token...",
        requiresReauthentication:
            false, // Reset this flag before attempting refresh
      ),
    );

    try {
      final refreshToken = SessionManager.instance.jwtRefreshToken;

      if (refreshToken == null || refreshToken.isEmpty) {
        print("AuthBloc: No refresh token found in session manager.");
        // This should ideally not happen if _refreshAccessToken logic is correct
        // but as a fallback, treat as auth failure.
        emit(
          state.copywith(
            postApiStatus: PostApiStatus.error,
            message: "No refresh token found. Please login again.",
            requiresReauthentication: true, // Indicate reauth needed
          ),
        );
        // Also clear session just in case
        await SessionManager.instance.clearSession();
        return;
      }

      // The usecase calls the repository, which calls the datasource.
      // AuthenticationFailedException is thrown from the datasource/network layer.
      final result = await refreshTokenUsecase.call(refreshToken: refreshToken);

      result.fold(
        (success) async {
          final newAccessToken = success.data!;
          // SessionManager.instance.setSession is already called in NetworkServicesApi._refreshAccessToken
          // when the refresh is successful. No need to call updateAccessToken here.

          print("AuthBloc: Access token refreshed successfully via usecase.");
          emit(
            state.copywith(
              // Update access token in state (optional, session manager is the source of truth)
              // accessToken: newAccessToken, // You can update state if needed
              postApiStatus: PostApiStatus.success, // Or PostApiStatus.idle
              message: "Access token refreshed successfully.",
              requiresReauthentication: false, // Successfully authenticated
            ),
          );
        },
        (error) {
          // This branch is for generic ApiErrors caught by the datasource that weren't AuthenticationFailedException
          print(
            "AuthBloc: RefreshAccessTokenEvent received ApiError: ${error.message}",
          );
          emit(
            state.copywith(
              postApiStatus:
                  PostApiStatus.error, // Indicate API error during refresh
              message: error.message,
              requiresReauthentication:
                  false, // It was an API error, not necessarily requiring reauth *yet*
              // unless this error *is* the reauth signal, which we handle below.
            ),
          );
        },
      );
    } on AuthenticationFailedException catch (e) {
      // **CATCH THE SPECIFIC AUTHENTICATION FAILURE EXCEPTION**
      print(
        "AuthBloc: Caught AuthenticationFailedException during token refresh: ${e.message}",
      );
      // SessionManager.instance.clearSession() is already called in NetworkServicesApi on refresh failure.
      // Emit state to indicate re-authentication is required.
      emit(
        state.copywith(
          postApiStatus:
              PostApiStatus.error, // Or a specific 'unauthenticated' status
          message: e.message, // Use the message from the exception
          requiresReauthentication: true, // **THIS IS THE KEY FLAG**
        ),
      );
      print("AuthBloc: State emitted with requiresReauthentication: true.");
    } catch (e) {
      // Catch any other unexpected exceptions
      print("AuthBloc: Unexpected error during token refresh: $e");
      emit(
        state.copywith(
          postApiStatus: PostApiStatus.error,
          message:
              "An unexpected error occurred during token refresh: ${e.toString()}",
          requiresReauthentication:
              false, // Unless this unexpected error *implies* auth failure
        ),
      );
    }
  }

  FutureOr<void> _onOtp1Changed(Otp1Changed event, Emitter<AuthState> emit) {
    print("Otp1 changed ${event.num}");
    emit(state.copywith(otp1: event.num));
  }

  FutureOr<void> _onOtp2Changed(Otp2Changed event, Emitter<AuthState> emit) {
    print("Otp2 changed ${event.num}");
    emit(state.copywith(otp2: event.num));
  }

  FutureOr<void> _onOtp3Changed(Otp3Changed event, Emitter<AuthState> emit) {
    print("Otp3 changed ${event.num}");
    emit(state.copywith(otp3: event.num));
  }

  FutureOr<void> _onOtp4Changed(Otp4Changed event, Emitter<AuthState> emit) {
    print("Otp4 changed ${event.num}");
    emit(state.copywith(otp4: event.num));
  }

  FutureOr<void> _onOtp5Changed(Otp5Changed event, Emitter<AuthState> emit) {
    print("Otp5 changed ${event.num}");
    emit(state.copywith(otp5: event.num));
  }

  FutureOr<void> _onOtp6Changed(Otp6Changed event, Emitter<AuthState> emit) {
    print("Otp6 changed ${event.num}");
    emit(state.copywith(otp6: event.num));
  }

  FutureOr<void> _onEmailChanged(EmailChanged event, Emitter<AuthState> emit) {
    print("Email Changed : ${event.email}");
    emit(
      state.copywith(postApiStatus: PostApiStatus.initial, email: event.email),
    );
  }

  FutureOr<void> _onPasswordChanged(
    PasswordChanged event,
    Emitter<AuthState> emit,
  ) {
    print("Password Changed : ${event.password}");
    emit(
      state.copywith(
        postApiStatus: PostApiStatus.initial,
        password: event.password,
      ),
    );
  }

  FutureOr<void> _onNameChanged(NameChanged event, Emitter<AuthState> emit) {
    print("Name Changed : ${event.name}");
    emit(state.copywith(name: event.name));
  }

  FutureOr<void> _onConfirmPasswordChanged(
    ConfirmPasswordChanged event,
    Emitter<AuthState> emit,
  ) {
    print("Confirm Password Changed : ${event.confirmPassword}");
    emit(state.copywith(confirmPassword: event.confirmPassword));
  }

  FutureOr<void> _onForgotPassword(
    ForgotPassword event,
    Emitter<AuthState> emit,
  ) async {
    print("Running forgot password in AuthBloc");
    try {
      emit(
        state.copywith(
          postApiStatus: PostApiStatus.loading,
          message: "Loading",
        ),
      );
      print("Email in forgot password AuthBloc: ${state.email}");
      print("Password in forgot password AuthBloc: ${state.password}");

      final result = await forgotPasswordUsecase.forgotPassword(
        email: state.email,
      );

      print("Result printed in forgot password AuthBloc: ${result}");

      result.fold(
        (success) {
          print(
            "Result printed in forgot password in success AuthBloc: ${success.data}",
          );

          emit(
            state.copywith(
              postApiStatus: PostApiStatus.success,
              message: success.data ?? "O",
            ),
          );
        },
        (error) {
          print("Error in forgot password $error");
          emit(
            state.copywith(
              postApiStatus: PostApiStatus.error,
              message: error.message, // Emit the String error message
            ),
          );
        },
      );
    } catch (e) {
      print("Error in forgot password try catch ${e}");
      emit(
        state.copywith(
          postApiStatus: PostApiStatus.error,
          message: e.toString(), // Emit the String error message
        ),
      );
    }
  }

  FutureOr<void> _onVerifyForgotPasswordOtp(
    VerifyForgotPasswordOtp event,
    Emitter<AuthState> emit,
  ) async {
    print("Running Verify forgot password otp in AuthBloc");
    try {
      emit(
        state.copywith(
          postApiStatus: PostApiStatus.loading,
          message: "Loading",
        ),
      );
      print("Email in verify forgot password otp AuthBloc: ${event.email}");

      final otp =
          '${state.otp1}${state.otp2}${state.otp3}${state.otp4}${state.otp5}${state.otp6}';
      print("OTP in auth bloc verify: ${otp}");
      final result = await forgotPasswordUsecase.verifyForgorPasswordOtp(
        email: event.email,
        token: otp,
      );

      print("Result printed in forgot password otp AuthBloc: ${result}");

      result.fold(
        (success) {
          emit(
            state.copywith(
              postApiStatus: PostApiStatus.success,
              message: success.data?.message ?? "OTP verified!",
            ),
          );
        },
        (error) {
          emit(
            state.copywith(
              postApiStatus: PostApiStatus.error,
              message: error.message, // Emit the String error message
            ),
          );
        },
      );
    } catch (e) {
      emit(
        state.copywith(
          postApiStatus: PostApiStatus.error,
          message: e.toString(), // Emit the String error message
        ),
      );
    }
  }

  FutureOr<void> _onResetPassword(
    ResetPassword event,
    Emitter<AuthState> emit,
  ) async {
    print("Running Verify forgot password otp in AuthBloc");
    try {
      emit(
        state.copywith(
          postApiStatus: PostApiStatus.loading,
          message: "Loading",
        ),
      );
      print(
        "Password in verify forgot password otp AuthBloc: ${state.password}",
      );
      print(
        "Password in verify forgot password otp AuthBloc: ${state.confirmPassword}",
      );

      final otp =
          '${state.otp1}${state.otp2}${state.otp3}${state.otp4}${state.otp5}${state.otp6}';
      print("OTP in auth bloc verify: ${otp}");
      final result = await forgotPasswordUsecase.resetPassword(
        email: event.email,
        token: event.token,
        password: state.password,
      );

      print("Result printed in forgot password otp AuthBloc: ${result}");

      result.fold(
        (success) {
          emit(
            state.copywith(
              postApiStatus: PostApiStatus.success,
              message: success.data?.message ?? "OTP verified!",
            ),
          );
        },
        (error) {
          emit(
            state.copywith(
              postApiStatus: PostApiStatus.error,
              message: error.message, // Emit the String error message
            ),
          );
        },
      );
    } catch (e) {
      emit(
        state.copywith(
          postApiStatus: PostApiStatus.error,
          message: e.toString(), // Emit the String error message
        ),
      );
    }
  }
}
