import 'package:bikerr/config/constants.dart';
import 'package:bikerr/config/routes/route_names.dart';
import 'package:bikerr/core/theme.dart';
import 'package:bikerr/services/session/session_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class CustomAppBar extends StatelessWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bikerrbgColor,
      padding: const EdgeInsets.all(10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Image.asset(
              AppLogos.bikerrPng,
              height: 40,
              width: 100,
              alignment: Alignment.centerLeft,
            ),
          ),
          GestureDetector(
            child: SvgPicture.asset(AppLogos.profile, height: 50),
            onTap: () async {
              await SessionManager.instance.clearSession();
              Navigator.pushNamedAndRemoveUntil(
                context,
                RoutesName.loginScreen,
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
