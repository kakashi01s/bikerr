import 'package:bikerr/config/constants.dart';
import 'package:bikerr/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ActionBar extends StatelessWidget {
  final VoidCallback onMessageTap;
  const ActionBar({super.key, required this.onMessageTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      color: AppColors.bikerrbgColor,
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20.0),
            child: SvgPicture.asset(AppLogos.drawer, height: 30),
          ),
          Row(
            children: [
              SvgPicture.asset(AppLogos.post, height: 30),
              const SizedBox(width: 12),
              SvgPicture.asset(AppLogos.notification, height: 30),
              const SizedBox(width: 12),
              GestureDetector(
                child: SvgPicture.asset(AppLogos.messages, height: 30),
                onTap: onMessageTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
