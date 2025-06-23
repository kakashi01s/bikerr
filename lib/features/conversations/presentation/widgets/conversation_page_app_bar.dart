import 'package:bikerr/config/constants.dart';
import 'package:bikerr/config/routes/route_names.dart';
import 'package:bikerr/core/theme.dart';
import 'package:bikerr/utils/widgets/buttons/back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ConversationPageAppBar extends StatelessWidget {
  const ConversationPageAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.all(8.0),
      color: AppColors.bgColor,

      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left side: Back button and Chat text
                Flexible(
                  child: Row(
                    children: [
                      BackButtonComponent(onTap: () {
                        Navigator.pushNamedAndRemoveUntil(context, "base_page", (route) => false);
                      }),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          "Chat",
                          style: textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Right side: Join New button
                Container(
                  constraints: BoxConstraints(maxWidth: 160),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.buttonbgColor,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, RoutesName.joinChatScreen);
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(AppLogos.joinGroup, height: 20),
                        SizedBox(width: 8),
                        Text(
                          "Join New",
                          style: textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 15),
            SizedBox(
              height: 0.5,
              child: Container(color: AppColors.bikerrRedFill.withOpacity(.6)),
            ),
          ],
        ),
      ),
    );
  }
}
