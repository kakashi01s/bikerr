import 'package:bikerr/config/constants.dart';
import 'package:bikerr/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class BackButtonComponent extends StatelessWidget {
  final VoidCallback? onTap;
  const BackButtonComponent({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // Use SizedBox to define the background size
      height: 30,
      width: 30,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color: Colors.transparent,
            ),
          ),
          Align(
            alignment: Alignment.center, // Center the arrow
            child: SizedBox(
              height: 18, // Adjust the desired arrow size
              width: 18,
              child: GestureDetector(
                onTap: onTap,
                child: SvgPicture.asset(AppLogos.arrowBack),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
