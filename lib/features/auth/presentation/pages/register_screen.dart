import 'package:bikerr/config/constants.dart';
import 'package:bikerr/config/routes/route_names.dart';
import 'package:bikerr/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bikerr/features/auth/presentation/widgets/login_prompt.dart';
import 'package:bikerr/utils/di/service_locator.dart';
import 'package:bikerr/utils/enums/enums.dart';
import 'package:bikerr/utils/widgets/buttons/app_button.dart';
import 'package:bikerr/utils/widgets/common/bg_scaffold.dart';
import 'package:bikerr/utils/widgets/common/text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late AuthBloc _authBloc;
  final _formKey = GlobalKey<FormState>();
  final FocusNode _usernameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  @override
  void initState() {
    // TODO: implement initState
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
  void dispose() {
    _confirmPasswordFocusNode.dispose();
    _usernameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
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
                  Image.asset(AppLogos.bikerrPng),

                  SizedBox(height: 20),

                  Text(AppText.signUP, style: textTheme.titleLarge),

                  SizedBox(height: 20),

                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        BlocBuilder<AuthBloc, AuthState>(
                          buildWhen:
                              (previous, current) =>
                                  previous.name != current.name,
                          builder: (context, state) {
                            return TextFieldComponent(
                              label: "User Name",
                              focusNode: _usernameFocusNode,
                              isPassword: false,
                              onChanged: (value) {
                                context.read<AuthBloc>().add(
                                  NameChanged(name: value),
                                );
                              },
                              svgAsset: 'assets/images/logo_user.svg',
                            );
                          },
                        ),
                        SizedBox(height: 5),
                        BlocBuilder<AuthBloc, AuthState>(
                          buildWhen:
                              (previous, current) =>
                                  previous.email != current.email,
                          builder: (context, state) {
                            return TextFieldComponent(
                              label: "Email",
                              focusNode: _emailFocusNode,
                              isPassword: false,
                              onChanged: (value) {
                                context.read<AuthBloc>().add(
                                  EmailChanged(email: value),
                                );
                              },
                              svgAsset: 'assets/images/logo_at.svg',
                            );
                          },
                        ),

                        SizedBox(height: 5),

                        BlocBuilder<AuthBloc, AuthState>(
                          buildWhen:
                              (previous, current) =>
                                  previous.password != current.password,
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
                              svgAsset: 'assets/images/logo_lock.svg',
                            );
                          },
                        ),

                        SizedBox(height: 5),
                        BlocBuilder<AuthBloc, AuthState>(
                          buildWhen:
                              (previous, current) =>
                                  previous.confirmPassword !=
                                  current.confirmPassword,
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
                              Navigator.pushNamed(
                                context,
                                RoutesName.verifyOtpScreen,
                                arguments: {
                                  'id': state.id,
                                  'email': state.email,
                                  'password': state.password,
                                  'source': 'register',
                                },
                              );
                            }
                          },
                          child: BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, state) {
                              if (state.postApiStatus ==
                                  PostApiStatus.loading) {
                                return Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              return AppButtonComponent(
                                label: "Submit",
                                onPressed: () {
                                  print("Register cliced from Register screen");
                                  context.read<AuthBloc>().add(RegisterEvent());
                                },
                              );
                            },
                          ),
                        ),

                        SizedBox(height: 5),
                        LoginPrompt(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              RoutesName.loginScreen,
                            );
                          },
                          title: "Already have an Account?",
                          subtitle: "Login Here!",
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
