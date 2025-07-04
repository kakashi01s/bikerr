import 'package:bikerr/config/constants.dart';
import 'package:bikerr/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ActionBar extends StatelessWidget {
  final VoidCallback onMessageTap;
  final VoidCallback onDrawerTap;
  final String? speedText; // Receives the final, formatted speed string

  const ActionBar({
    super.key,
    required this.onMessageTap,
    this.speedText, required this.onDrawerTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      color: AppColors.bikerrbgColor,
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Ensures column doesn't take extra space
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: GestureDetector(
                    onTap: onDrawerTap,
                    child: SvgPicture.asset(AppLogos.drawer, height: 30)

                ),
              ),
              Row(
                children: [
                  SvgPicture.asset(AppLogos.post, height: 30),
                  const SizedBox(width: 12),
                  SvgPicture.asset(AppLogos.notification, height: 30),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: onMessageTap,
                    child: SvgPicture.asset(AppLogos.messages, height: 30),
                  ),
                ],
              ),
            ],
          ),
          // Conditionally build the speed row only if speedText is available
          if (speedText != null && speedText!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    speedText!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}