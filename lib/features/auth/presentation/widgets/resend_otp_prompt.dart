import 'dart:async';

import 'package:bikerr/core/theme.dart';
import 'package:flutter/material.dart';

class ResendOtpPrompt extends StatefulWidget {
  final VoidCallback onResendPressed;
  final String title;
  final String subtitle;
  const ResendOtpPrompt({
    super.key,
    required this.onResendPressed,
    required this.title,
    required this.subtitle,
  });

  @override
  State<ResendOtpPrompt> createState() => _ResendOtpPromptState();
}

class _ResendOtpPromptState extends State<ResendOtpPrompt> {
  bool _isResendAvailable = true;
  int _remainingSeconds = 60;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _isResendAvailable = false;
      _remainingSeconds = 60;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        setState(() {
          _isResendAvailable = true;
        });
        _timer.cancel();
      }
    });
  }

  void _handleResendClick() {
    if (_isResendAvailable) {
      widget.onResendPressed();
      _startTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: _handleResendClick,
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            text: widget.title,
            style: const TextStyle(color: AppColors.greyText, fontSize: 15),
            children: [
              const TextSpan(text: " "),
              TextSpan(
                text:
                    _isResendAvailable
                        ? widget.subtitle
                        : "Resend OTP in $_remainingSeconds seconds",
                style: TextStyle(
                  color:
                      _isResendAvailable
                          ? AppColors.bikerrRedFill
                          : AppColors.greyText,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
