import 'package:bikerr/config/constants.dart';
import 'package:bikerr/config/routes/route_names.dart';
import 'package:bikerr/core/theme.dart';
import 'package:bikerr/services/session/session_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar( {super.key});

  @override
  Widget build(BuildContext context) {
    // No Expanded needed here, as PreferredSize will handle the sizing
    return Container(
      color: AppColors.bikerrbgColor,
      padding: const EdgeInsets.all(10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Padding(
          //   padding: const EdgeInsets.only(left: 20),
          //   child: Image.asset(
          //     AppLogos.bikerrPng,
          //     height: 40,
          //     width: 100,
          //     alignment: Alignment.centerLeft,
          //   ),
          // ),
          GestureDetector(
            child: SvgPicture.asset(AppLogos.profile, height: 50),
            onTap: () async {

            },
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight); // Standard app bar height
}