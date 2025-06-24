import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FontSizes {
  static const small = 12.0;
  static const standard = 14.0;
  static const standardUp = 16.0;
  static const medium = 20.0;
  static const large = 28.0;
}

class AppColors {
  static const Color greyText = Color(0xFFB3B9C9);
  static Color markerBg1 = const Color(0xFF000000).withValues(alpha: 0.5);
  static const Color whiteText = Color(0xFFFFFFFF);
  static const Color senderMessage = Color(0xFF7A8194);
  static const Color receiverMessage = Color(0xFF373E4E);
  static const Color sentMessageInput = Color(0xFF3D4354);
  static const Color messageListPage = Color.fromARGB(255, 39, 41, 46);
  static const Color buttonColor = Color(0xFF7A8194);
  static const Color bgColor = Color(0xFF0F0F0F);
  static const Color hintColor = Color(0xFF797979);
  static const Color bikerrRedFill = Color(0xFFFF0000);
  static const Color bikerrRedStroke = Color(0xFFFF0101);
  static const Color bikerrbgColor = Color(0xFF000000);
  static const Color buttonbgColor = Color(0xFF333333);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      primaryColor: Colors.white,
      scaffoldBackgroundColor: const Color(0xFF1B202D),
      textTheme: TextTheme(
        titleMedium: GoogleFonts.poppins(
          fontSize: FontSizes.medium,
          color: AppColors.bikerrRedFill,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: FontSizes.large,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: GoogleFonts.poppins(
          fontSize: FontSizes.large,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),

        bodySmall: GoogleFonts.poppins(
          fontSize: FontSizes.small,
          color: Colors.white,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: FontSizes.large,
          color: Colors.white,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: FontSizes.medium,
          color: Colors.white,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: FontSizes.medium,
          color: AppColors.whiteText,
          fontWeight: FontWeight.w600,
        ),
        displaySmall: GoogleFonts.poppins(
          fontSize: FontSizes.standardUp,
          color: AppColors.hintColor,
          fontWeight: FontWeight.w300,
        ),
        labelSmall: GoogleFonts.poppins(
          fontSize: FontSizes.standardUp,
          color: AppColors.whiteText,
          fontWeight: FontWeight.w300,
        ),
      ),
    );
  }
}
