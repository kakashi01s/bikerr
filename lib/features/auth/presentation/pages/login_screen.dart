import 'package:bikerr/config/constants.dart';
import 'package:bikerr/config/routes/route_names.dart';
import 'package:bikerr/core/theme.dart';
import 'package:bikerr/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bikerr/features/auth/presentation/widgets/login_prompt.dart';
import 'package:bikerr/utils/di/service_locator.dart';
import 'package:bikerr/utils/enums/enums.dart';
import 'package:bikerr/utils/widgets/buttons/app_button.dart';
import 'package:bikerr/utils/widgets/common/bg_scaffold.dart';
import 'package:bikerr/utils/widgets/common/text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late AuthBloc _authBloc;
  final _formKey = GlobalKey<FormState>();
  final FocusNode _emailFocusNode = FocusNode();
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

                  Text(AppText.login, style: textTheme.titleLarge),

                  SizedBox(height: 20),

                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        BlocBuilder<AuthBloc, AuthState>(
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
                                duration: Duration(seconds: 5), content: Text("Logged In Successfully!"),

                              );

                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(snackBar);

                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                RoutesName.basePage,

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

                                content: Text("Logged In Successfully!"),
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
                                    color: AppColors.bikerrRedFill,
                                  ),
                                );
                              }
                              return AppButtonComponent(
                                label: "Submit",
                                onPressed: () {
                                  context.read<AuthBloc>().add(LoginEvent());
                                },
                              );
                            },
                          ),
                        ),
                        SizedBox(height: 15),
                        LoginPrompt(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              RoutesName.forgotPasswordScreen,
                            );
                          },
                          title: "Forgot Password?",
                          subtitle: " ",
                        ),
                        SizedBox(height: 5),
                        LoginPrompt(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              RoutesName.registerScreen,
                            );
                          },
                          title: "Don't have an Account?",
                          subtitle: "Register Here!",
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
