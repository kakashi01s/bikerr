import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:bikerr/config/constants.dart';
import 'package:bikerr/config/routes/route_names.dart';
import 'package:bikerr/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bikerr/utils/di/service_locator.dart';
import 'package:bikerr/utils/enums/enums.dart';
import 'package:bikerr/utils/widgets/buttons/app_button.dart';
import 'package:bikerr/utils/widgets/common/bg_scaffold.dart';
import 'package:bikerr/utils/widgets/common/text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String token;
  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.token,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  late AuthBloc _authBloc;
  final _formKey = GlobalKey<FormState>();
  final FocusNode _confirmPasswordFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _authBloc = AuthBloc(
      registerUsecase: sl(),
      verifyEmailUsecase: sl(),
      loginUsecase: sl(),
      forgotPasswordUsecase: sl(),
      refreshTokenUsecase: sl(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return BackgroundScaffold(
      isBackBtn: true,
      child: BlocProvider(
        create: (context) => _authBloc,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(30),
            child: Center(
              child: Column(
                children: [
                  Image.asset('assets/images/logo_bikerr.png'),

                  SizedBox(height: 20),

                  Text(
                    AppText.resetPassword,
                    style: textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 20),

                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) {
                            return TextFieldComponent(
                              label: "Password",
                              focusNode: _passwordFocusNode,
                              isPassword: false,
                              onChanged: (value) {
                                context.read<AuthBloc>().add(
                                  PasswordChanged(password: value),
                                );
                              },
                              svgAsset: 'assets/images/logo_at.svg',
                            );
                          },
                        ),
                        SizedBox(height: 5),
                        BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) {
                            return TextFieldComponent(
                              label: "Confirm Password",
                              focusNode: _confirmPasswordFocusNode,
                              isPassword: false,
                              onChanged: (value) {
                                context.read<AuthBloc>().add(
                                  ConfirmPasswordChanged(
                                    confirmPassword: value,
                                  ),
                                );
                              },
                              svgAsset: 'assets/images/logo_lock.svg',
                            );
                          },
                        ),
                        SizedBox(height: 15),
                        BlocListener<AuthBloc, AuthState>(
                          listener: (context, state) {
                            if (state.postApiStatus == PostApiStatus.success) {
                              print("success");

                              var snackBar = SnackBar(
                                /// need to set following properties for best effect of awesome_snackbar_content
                                elevation: 0,
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: Colors.transparent,
                                duration: Duration(seconds: 5),

                                content: AwesomeSnackbarContent(
                                  title: 'Reset Password Successful ',
                                  message: 'Welcome to Biker',

                                  /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
                                  contentType: ContentType.success,
                                ),
                              );

                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(snackBar);

                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                RoutesName.loginScreen,

                                (route) => false,
                              );
                            }
                            if (state.postApiStatus == PostApiStatus.error) {
                              var snackBar = SnackBar(
                                /// need to set following properties for best effect of awesome_snackbar_content
                                elevation: 0,
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: Colors.transparent,
                                duration: Duration(seconds: 5),

                                content: AwesomeSnackbarContent(
                                  title: 'Reset Password Failed ',
                                  message: state.message,

                                  /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
                                  contentType: ContentType.failure,
                                ),
                              );

                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(snackBar);
                            }
                          },
                          child: BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, state) {
                              if (state.postApiStatus ==
                                  PostApiStatus.loading) {
                                return Center(
                                  child: CircularProgressIndicator(
                                    color: DefaultColors.failureRed,
                                  ),
                                );
                              }
                              return AppButtonComponent(
                                label: "Submit",
                                onPressed: () {
                                  context.read<AuthBloc>().add(
                                    ResetPassword(
                                      email: widget.email,
                                      token: widget.token,
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
