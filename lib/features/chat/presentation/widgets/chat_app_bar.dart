// In lib/features/chat/presentation/widgets/chat_app_bar.dart
// (Renamed from ChatAppBarComponent.dart based on typical Flutter structure)

import 'package:bikerr/config/constants.dart'; // Assuming AppUrl and AppLogos are here
import 'package:bikerr/config/routes/route_names.dart';
import 'package:bikerr/core/theme.dart';
import 'package:bikerr/utils/widgets/buttons/back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Import SvgPicture

class ChatAppBar
    extends
        StatelessWidget // Renamed from ChatAppBarComponent for clarity
    implements PreferredSizeWidget {
  final String chatRoomName;
  // Assuming networkImageUrl is the full URL (e.g., S3 URL)
  final String? networkImageUrl; // Declared as nullable

  const ChatAppBar({
    // Renamed constructor
    super.key,
    required this.chatRoomName,
    this.networkImageUrl, // *** CORRECTED: Removed 'required' here ***
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight); // Define the preferred height

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Helper to build the avatar widget (handles network or local SVG)
    Widget _buildAvatar() {
      // If a network URL is provided, try loading it
      if (networkImageUrl != null && networkImageUrl!.isNotEmpty) {
        return CircleAvatar(
          radius: 20.0,
          // Use FadeInImage for a smooth transition and placeholder
          backgroundImage:
              FadeInImage.assetNetwork(
                // Use a local asset for the placeholder while loading
                placeholder:
                    AppLogos
                        .user, // <--- Use your local placeholder asset path here
                image: networkImageUrl!, // The network image URL
                fit: BoxFit.cover, // Ensure the image covers the circle
                // --- ADDED: Error builder to show a local placeholder if network image fails ---
                imageErrorBuilder: (context, error, stackTrace) {
                  print(
                    'ChatAppBar: Failed to load network image: $error',
                  ); // Log the error
                  // Return the same local asset placeholder on error
                  return CircleAvatar(
                    radius: 20.0,
                    backgroundImage: AssetImage(
                      AppLogos.user,
                    ), // <--- Use your local placeholder asset path here
                    backgroundColor: Colors.grey, // Optional background
                  );
                },
                // -----------------------------------------------------------------------------
              ).image,
          backgroundColor: Colors.grey, // Optional background while loading
        );
      } else {
        // If no network URL is provided, show the default local SVG placeholder
        print(
          'ChatAppBar: Network image URL is null or empty, showing local SVG placeholder.',
        );
        // Assuming AppLogos.user is the path to your default local user SVG asset
        return CircleAvatar(
          // Wrap SVG in CircleAvatar for consistent sizing/clipping
          radius: 20.0,
          backgroundColor: Colors.grey, // Optional background
          child: SvgPicture.asset(
            AppLogos
                .user, // <--- Use your local default user SVG asset path here
            width: 40, // Match CircleAvatar diameter
            height: 40, // Match CircleAvatar diameter
            fit: BoxFit.cover, // Cover the area
            // SvgPicture doesn't have an explicit errorBuilder for asset not found.
            // Ensure AppLogos.user path is correct and asset exists.
          ),
        );
      }
    }

    // Wrap the AppBar content in a PreferredSize widget
    return PreferredSize(
      preferredSize: preferredSize,
      child: AppBar(
        leading: BackButtonComponent(
          onTap: () {
            // Assuming RoutesName and Navigator are correctly set up
            Navigator.pushNamedAndRemoveUntil(
              context,
              RoutesName.conversationsScreen,
              (predicate) => false,
            );
          },
        ),
        backgroundColor: AppColors.buttonbgColor, // Use your theme color
        title: Row(
          children: [
            // Use the helper function to build the avatar
            _buildAvatar(),
            Padding(
              padding: const EdgeInsets.only(left: 15),
              child: Text(
                chatRoomName,
                style: textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                ), // Ensure text color is visible on AppBar
              ),
            ),
          ],
        ),
        elevation: 0, // Remove shadow
        actions: const [
          // Add any actions here if needed, e.g., search, menu
        ],
      ),
    );
  }
}
