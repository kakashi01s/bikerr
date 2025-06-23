import 'package:bikerr/core/theme.dart';
import 'package:flutter/material.dart';

class LoginPrompt extends StatelessWidget {
  final VoidCallback onPressed;
  final String title;
  final String subtitle;
  const LoginPrompt({
    super.key,
    required this.onPressed,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onPressed,
        child: RichText(
          text: TextSpan(
            text: title,
            style: const TextStyle(color: AppColors.greyText, fontSize: 15),
            children: [
              TextSpan(text: " "),
              TextSpan(
                text: subtitle,
                style: const TextStyle(
                  color: AppColors.bikerrRedFill,
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
