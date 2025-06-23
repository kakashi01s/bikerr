import 'package:bikerr/config/constants.dart';
import 'package:bikerr/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart'; // Import the intl package for date formatting

// Assume AppColors and AppLogos are defined and imported correctly

class MessageTile extends StatelessWidget {
  final String name; // Conversation name
  final String? senderName; // Sender name of the last message (optional)
  final String message; // This can be the text content or a caption
  final DateTime time;
  final int unreadCount;
  final bool
  isImageMessage; // New flag to indicate if the last message is an image

  const MessageTile({
    super.key,
    required this.name,
    this.senderName, // Accept the optional senderName
    required this.message,
    required this.time,
    this.unreadCount = 0,
    this.isImageMessage = false, // Default to false
  });

  @override
  Widget build(BuildContext context) {
    // Debugging prints inside MessageTile
    print('--- Building MessageTile for: $name ---');
    print('  Received senderName: "$senderName"'); // Print senderName
    print('  Received message content (string): "$message"');
    print('  Received isImageMessage flag: $isImageMessage');
    // --- End Debugging Prints ---

    final localTime = time.toLocal();
    final formattedTime = DateFormat(
      'hh:mm a',
    ).format(localTime); // Format time as hh:mm AM/PM
    final textTheme = Theme.of(context).textTheme;

    // Determine the content widget based on isImageMessage
    Widget messageContentWidget;
    if (isImageMessage) {
      // If it's an image message, show the image placeholder
      messageContentWidget = Row(
        mainAxisSize: MainAxisSize.min, // Wrap content
        children: [
          Icon(
            Icons.image_outlined,
            size: 18,
            color: Colors.grey,
          ), // Image icon
          SizedBox(width: 4), // Spacing between icon and text
          Text(
            "Image", // Placeholder text for image
            style: textTheme.bodySmall?.copyWith(
              color: Colors.grey, // Muted color for placeholder
              fontStyle: FontStyle.italic, // Italicize placeholder
            ),
          ),
          // Optional: Add a small preview thumbnail here if available
        ],
      );
    } else {
      // If it's NOT an image message, show the text content.
      // Also handle the case where the string message is "null" or empty.
      final String displayMessage =
          (message == "null" || message.isEmpty)
              ? 'No messages yet' // Show 'No messages yet' if the string is "null" or empty
              : message; // Otherwise, show the actual message string

      messageContentWidget = Text(
        displayMessage,
        style: textTheme.bodySmall?.copyWith(
          color: AppColors.whiteText.withOpacity(
            0.8,
          ), // Muted color for message text
        ),
        overflow: TextOverflow.ellipsis, // Prevent message text overflow
        maxLines: 1, // Show only one line
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          Stack(
            clipBehavior:
                Clip.none, // Allow bubble to go outside stack bounds if needed
            children: [
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start, // Align items to the top
                children: [
                  // User Avatar
                  // Using a single CircleAvatar for consistency.
                  // Replace the hardcoded NetworkImage with actual user profile image logic.
                  CircleAvatar(
                    radius: 24, // Standard avatar size
                    // Example: Use NetworkImage if user has a photoUrl, otherwise use a placeholder
                    backgroundImage: NetworkImage(
                      'https://neweralive.na/wp-content/uploads/2024/06/lloyd-sikeba.jpg',
                    ), // Replace with dynamic user.photoUrl
                    backgroundColor: AppColors.whiteText.withOpacity(
                      0.5,
                    ), // Placeholder background color
                    child: // Add a placeholder icon if backgroundImage is null or fails to load
                        null, // Or Icon(Icons.person, color: AppColors.buttonColor) if no image URL
                  ),
                  const SizedBox(
                    width: 12,
                  ), // Spacing between avatar and message content
                  // Message details (Name, Sender Name, Content, Time)
                  Expanded(
                    // Allow message details to take available space
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start, // Align text content to the start
                      children: [
                        // Conversation Name
                        Text(
                          name,
                          style: textTheme.titleMedium?.copyWith(
                            color: AppColors.whiteText,
                          ), // Apply text style and color
                          overflow:
                              TextOverflow.ellipsis, // Prevent name overflow
                        ),
                        const SizedBox(
                          height: 4,
                        ), // Spacing between name and message content
                        // Sender Name + Message Content Row (Text or Image Placeholder + Time)
                        Row(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .end, // Align time to the bottom of the message content
                          children: [
                            // Sender Name (if provided)
                            if (senderName != null && senderName!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(
                                  right: 4.0,
                                ), // Space between sender name and message
                                child: Text(
                                  "$senderName:", // Display sender name with a colon
                                  style: textTheme.bodySmall?.copyWith(
                                    color: AppColors.whiteText.withOpacity(
                                      0.6,
                                    ), // Muted color for sender name
                                    fontWeight:
                                        FontWeight
                                            .bold, // Make sender name bold
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),

                            Expanded(
                              // Allow message content to take available space
                              child:
                                  messageContentWidget, // Use the determined content widget
                            ),
                            const SizedBox(
                              width: 8,
                            ), // Spacing between message content and time
                            // Time Text
                            Text(
                              formattedTime, // Display the formatted time
                              style: textTheme.bodySmall?.copyWith(
                                color: Colors.grey, // Muted color for time
                                fontSize:
                                    10, // Slightly smaller font size for time
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Unread message count bubble positioned at right center
              if (unreadCount > 0)
                Positioned(
                  right: 0,
                  // Adjust top to vertically center the bubble relative to the tile height
                  // This might need fine-tuning based on your exact row height.
                  // A value around half the height of the row content is a good start.
                  top: 12, // Example value, adjust as needed
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6, // Horizontal padding
                      vertical: 2, // Vertical padding
                    ),
                    decoration: BoxDecoration(
                      color:
                          AppColors
                              .bikerrRedFill, // Background color for the bubble
                      borderRadius: BorderRadius.circular(
                        12,
                      ), // Rounded corners
                    ),
                    child: Text(
                      unreadCount.toString(), // Display the unread count
                      style: const TextStyle(
                        fontSize: 12, // Font size for the count
                        color: Colors.white, // Text color
                        fontWeight: FontWeight.bold, // Bold text
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Divider line below the message tile
          const SizedBox(height: 15), // Spacing before the divider
          Container(
            height: 0.5, // Thickness of the divider
            color: AppColors.whiteText.withOpacity(
              0.6,
            ), // Color of the divider (using borderColor for consistency)
          ),
        ],
      ),
    );
  }
}
