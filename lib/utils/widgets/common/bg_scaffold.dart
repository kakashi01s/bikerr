import 'package:bikerr/config/constants.dart';
import 'package:bikerr/core/theme.dart';
import 'package:bikerr/utils/widgets/buttons/back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BackgroundScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget child;
  final bool isBackBtn;
  const BackgroundScaffold({
    required this.child,
    this.appBar,
    this.isBackBtn = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: true,
      left: false,
      right: false,
      bottom: false,
      child: Stack(
        children: [
          Positioned(
            top: 1,
            child: SizedBox(
              child: SvgPicture.asset(
                AppLogos.autBgDots,

                width: MediaQuery.of(context).size.width,
              ),
            ),
          ),
          Scaffold(
            backgroundColor: AppColors.bikerrbgColor,
            appBar: appBar,
            body: child,
          ),
          isBackBtn
              ? Positioned(
                top: 20,
                left: 20,
                child: const BackButtonComponent(),
              )
              : const SizedBox(),
        ],
      ),
    );
  }
}
