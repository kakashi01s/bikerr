import 'package:bikerr/config/constants.dart';
import 'package:bikerr/config/routes/route_names.dart';
import 'package:bikerr/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bikerr/features/auth/presentation/widgets/resend_otp_prompt.dart';
import 'package:bikerr/utils/di/service_locator.dart';
import 'package:bikerr/utils/enums/enums.dart';
import 'package:bikerr/utils/widgets/buttons/app_button.dart';
import 'package:bikerr/utils/widgets/common/bg_scaffold.dart';
import 'package:bikerr/utils/widgets/common/otp_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String? password;
  final int? id;
  final String email;
  final String source;
  const VerifyOtpScreen({
    super.key,
    this.password,
    this.id,
    required this.email,
    required this.source,
  });

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  late AuthBloc _authBloc;
  final _formKey = GlobalKey<FormState>();
  final FocusNode _otp1FocusNode = FocusNode();
  final FocusNode _otp2FocusNode = FocusNode();
  final FocusNode _otp3FocusNode = FocusNode();
  final FocusNode _otp4FocusNode = FocusNode();
  final FocusNode _otp5FocusNode = FocusNode();
  final FocusNode _otp6FocusNode = FocusNode();

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
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return BackgroundScaffold(
      isBackBtn: true,
      child: SingleChildScrollView(
        child: BlocProvider(
          create: (context) => _authBloc,
          child: Padding(
            padding: EdgeInsets.all(30),
            child: Center(
              child: Column(
                children: [
                  SizedBox(height: 100),

                  SvgPicture.asset(AppLogos.emailSent),

                  SizedBox(height: 20),
                  Center(
                    child: Text(
                      widget.source == "forgotPassword"
                          ? "Please verify your OTP"
                          : "We've sen't an OTP to Your email , Please verify it.",
                      style: textTheme.labelSmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(AppText.verifyOTP, style: textTheme.titleLarge),

                  SizedBox(height: 20),

                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              BlocBuilder<AuthBloc, AuthState>(
                                builder: (context, state) {
                                  return OtpTextFieldComponent(
                                    focusNode: _otp1FocusNode,
                                    isPassword: false,
                                    onChanged: (value) {
                                      context.read<AuthBloc>().add(
                                        Otp1Changed(num: value),
                                      );
                                    },
                                  );
                                },
                              ),
                              SizedBox(width: 10),
                              BlocBuilder<AuthBloc, AuthState>(
                                builder: (context, state) {
                                  return OtpTextFieldComponent(
                                    focusNode: _otp2FocusNode,
                                    isPassword: false,
                                    onChanged: (value) {
                                      context.read<AuthBloc>().add(
                                        Otp2Changed(num: value),
                                      );
                                    },
                                  );
                                },
                              ),
                              SizedBox(width: 10),
                              BlocBuilder<AuthBloc, AuthState>(
                                builder: (context, state) {
                                  return OtpTextFieldComponent(
                                    focusNode: _otp3FocusNode,
                                    isPassword: false,
                                    onChanged: (value) {
                                      context.read<AuthBloc>().add(
                                        Otp3Changed(num: value),
                                      );
                                    },
                                  );
                                },
                              ),
                              SizedBox(width: 10),
                              BlocBuilder<AuthBloc, AuthState>(
                                builder: (context, state) {
                                  return OtpTextFieldComponent(
                                    focusNode: _otp4FocusNode,
                                    isPassword: false,
                                    onChanged: (value) {
                                      context.read<AuthBloc>().add(
                                        Otp4Changed(num: value),
                                      );
                                    },
                                  );
                                },
                              ),
                              SizedBox(width: 10),
                              BlocBuilder<AuthBloc, AuthState>(
                                builder: (context, state) {
                                  return OtpTextFieldComponent(
                                    focusNode: _otp5FocusNode,
                                    isPassword: false,
                                    onChanged: (value) {
                                      context.read<AuthBloc>().add(
                                        Otp5Changed(num: value),
                                      );
                                    },
                                  );
                                },
                              ),
                              SizedBox(width: 10),
                              BlocBuilder<AuthBloc, AuthState>(
                                builder: (context, state) {
                                  return OtpTextFieldComponent(
                                    focusNode: _otp6FocusNode,
                                    isPassword: false,
                                    onChanged: (value) {
                                      context.read<AuthBloc>().add(
                                        Otp6Changed(num: value),
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 15),
                        BlocListener<AuthBloc, AuthState>(
                          listener: (context, state) {
                            if (state.postApiStatus == PostApiStatus.success) {
                              print("success");

                              if (widget.source == 'register') {
                                var snackBar = SnackBar(
                                  /// need to set following properties for best effect of awesome_snackbar_content
                                  elevation: 0,
                                  behavior: SnackBarBehavior.fixed,
                                  backgroundColor: Colors.transparent,
                                  duration: Duration(seconds: 5),

                                  content: Text("User Registered Successfully!"),
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

                              if (widget.source == 'forgotPassword') {
                                var snackBar = SnackBar(
                                  /// need to set following properties for best effect of awesome_snackbar_content
                                  elevation: 0,
                                  behavior: SnackBarBehavior.fixed,
                                  backgroundColor: Colors.transparent,
                                  duration: Duration(seconds: 5),

                                  content: Text("OTP Verified"),
                                );

                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(snackBar);

                                final otp =
                                    '${state.otp1}${state.otp2}${state.otp3}${state.otp4}${state.otp5}${state.otp6}';

                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  RoutesName.resetPassword,
                                  arguments: {
                                    'email': widget.email,
                                    'token': otp,
                                  },
                                  (route) => false,
                                );
                              }
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
                              // print("zpass ${widget.password}");
                              // print("zid ${widget.id}");
                              // print("zemail ${widget.email}");

                              return AppButtonComponent(
                                label: "Submit",
                                onPressed: () {
                                  if (widget.source == 'forgotPassword') {
                                    context.read<AuthBloc>().add(
                                      VerifyForgotPasswordOtp(
                                        email: widget.email,
                                      ),
                                    );
                                  } else if (widget.source == 'register') {
                                    context.read<AuthBloc>().add(
                                      VerifyEmail(
                                        userId: widget.id!,
                                        email: widget.email,
                                        password: widget.password!,
                                      ),
                                    );
                                  } else {
                                    var snackBar = SnackBar(
                                      /// need to set following properties for best effect of awesome_snackbar_content
                                      elevation: 0,
                                      behavior: SnackBarBehavior.fixed,
                                      backgroundColor: Colors.transparent,
                                      duration: Duration(seconds: 5),

                                      content: Text("Invalid"),
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
                                },
                              );
                            },
                          ),
                        ),

                        SizedBox(height: 5),
                        ResendOtpPrompt(
                          onResendPressed: () {},
                          title: "Didnt receive an OTP?",
                          subtitle: "Resend Now?",
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
