import 'package:bikerr/core/theme.dart';
import 'package:flutter/material.dart';

class AppButtonComponent extends StatelessWidget {
  final VoidCallback onPressed;

  final String label;
  const AppButtonComponent({
    super.key,
    required this.onPressed,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: 60,
      width: 400,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.bikerrRedFill.withOpacity(0.25),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          side: BorderSide(color: AppColors.bikerrRedStroke),
        ),
        child: Center(child: Text(label, style: textTheme.displayMedium)),
      ),
    );
  }
}
