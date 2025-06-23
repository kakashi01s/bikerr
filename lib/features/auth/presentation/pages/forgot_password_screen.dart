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

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late AuthBloc _authBloc;
  final _formKey = GlobalKey<FormState>();
  final FocusNode _emailFocusNode = FocusNode();

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
                  Image.asset(AppLogos.bikerrPng),

                  SizedBox(height: 20),

                  Text(AppText.forgotPassword, style: textTheme.titleLarge),

                  SizedBox(height: 20),

                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
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

                        SizedBox(height: 15),
                        BlocListener<AuthBloc, AuthState>(
                          listener: (context, state) {
                            if (state.postApiStatus == PostApiStatus.success) {
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                RoutesName.verifyOtpScreen,
                                arguments: {
                                  'source': 'forgotPassword',
                                  'email': state.email,
                                },
                                (route) => false,
                              );
                            }
                          },
                          child: BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, state) {
                              return AppButtonComponent(
                                label: "Submit",
                                onPressed: () {
                                  context.read<AuthBloc>().add(
                                    ForgotPassword(),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        SizedBox(height: 15),
                        LoginPrompt(
                          onPressed: () {},
                          title: "We'll send an OTP to your email",
                          subtitle: " ",
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
