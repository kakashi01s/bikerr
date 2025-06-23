// In lib/features/chat/presentation/widgets/received_message.dart

import 'package:bikerr/core/theme.dart';
import 'package:bikerr/config/constants.dart';
import 'package:bikerr/features/chat/data/models/message_model.dart';
import 'package:bikerr/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as path;

// Define the callback type for image taps (should match the one in chat_screen.dart)
typedef OnImageTapCallback = void Function(String imageUrl, String fileName);

// Define the callback type for reply icon tap (should match the one in chat_screen.dart)
typedef OnReplyTappedCallback = void Function(MessageModel message);

class ReceivedMessage extends StatelessWidget {
  final MessageModel message; // The message data model

  final bool showName; // Whether to display the sender's name above the bubble
  final VoidCallback? onLongPress; // Callback for long press gesture
  final bool isHighlighted; // Flag to indicate if message is highlighted

  // --- ADDED: Callback for tapping on an image attachment ---
  final OnImageTapCallback? onImageTap;
  // --------------------------------------------------------

  // --- ADDED: Callback for tapping the reply icon ---
  final OnReplyTappedCallback? onReplyTapped;
  // -------------------------------------------------

  const ReceivedMessage({
    super.key,
    required this.message, // Require the full MessageModel
    required this.showName,
    this.onLongPress,
    this.isHighlighted = false,
    this.onImageTap, // Include onImageTap in constructor
    this.onReplyTapped, // Include onReplyTapped in constructor
  });

  // Widget to build and display message attachments
  Widget _buildAttachments(BuildContext context) {
    if (message.attachments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start, // Align attachments to the start
      children:
          message.attachments.map((attachment) {
            final attachmentUrl = path.join(AppUrl.S3_BASE_URL, attachment.key);
            final fileName = path.basename(attachment.key);

            if (attachment.fileType.startsWith('image/') ||
                [
                  'jpg',
                  'jpeg',
                  'png',
                  'gif',
                ].contains(attachment.fileType.toLowerCase())) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: GestureDetector(
                  onTap: () {
                    // Call the provided onImageTap callback
                    onImageTap?.call(attachmentUrl, fileName);
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      attachmentUrl,
                      fit: BoxFit.cover,
                      width: 150, // Adjust size as needed
                      height: 150, // Adjust size as needed
                      loadingBuilder: (
                        BuildContext context,
                        Widget child,
                        ImageChunkEvent? loadingProgress,
                      ) {
                        if (loadingProgress == null) {
                          return child;
                        }
                        return Center(
                          child: SizedBox(
                            width: 20.0,
                            height: 20.0,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.secondary,
                              ),
                              value:
                                  loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (
                        BuildContext context,
                        Object exception,
                        StackTrace? stackTrace,
                      ) {
                        print(
                          'ReceivedMessage: Failed to load image from URL: $attachmentUrl, Exception: $exception',
                        );
                        return Container(
                          color: Colors.grey[700],
                          width: 150,
                          height: 150,
                          child: const Icon(
                            Icons.error_outline,
                            color: Colors.redAccent,
                            size: 30.0,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            } else {
              // Handle non-image attachments (e.g., display filename)
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Container(
                  padding: EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: AppColors.receiverMessage.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.attach_file,
                        color: Colors.black54,
                        size: 16,
                      ), // File icon
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Attachment: ${fileName}', // Display filename
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.black54),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          }).toList(),
    );
  }

  // Widget to build and display the quoted parent message
  Widget _buildQuote(BuildContext context) {
    if (message.parentMessage == null) {
      return const SizedBox.shrink();
    }

    final parentMessage = message.parentMessage!;
    final parentSenderName = parentMessage.user.name ?? 'Unknown';
    final parentContent = parentMessage.content ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Colors.blueAccent, width: 4.0)),
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            parentSenderName,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2.0),
          Text(
            parentContent,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.black87),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Derive sender name, time, and parent message from the MessageModel
    final String senderName = message.user?.name ?? 'Unknown';
    final DateTime? createdAt = message.createdAt;
    final String formattedTime =
        (createdAt != null)
            ? TimeOfDay.fromDateTime(createdAt.toLocal()).format(context)
            : '—';

    return GestureDetector(
      onLongPress: onLongPress,
      onTap: () {
        if (isHighlighted) {
          context.read<ChatBloc>().add(
            const SetHighlightedMessageEvent(message: null),
          );
        }
      },
      child: Container(
        // Applied highlight color to the outer container
        color:
            isHighlighted
                ? AppColors.receiverMessage.withOpacity(0.5)
                : Colors.transparent,
        padding: const EdgeInsets.symmetric(
          horizontal: 4.0,
        ), // Keep padding for highlight visual
        child: Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showName)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, bottom: 2.0),
                  child: Text(
                    senderName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              // --- MODIFIED: Wrap the message bubble and reply icon in a Row ---
              Row(
                mainAxisSize: MainAxisSize.min, // Row takes minimum space
                crossAxisAlignment:
                    CrossAxisAlignment.center, // Vertically align items
                children: [
                  // --- Existing Message Bubble Container ---
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 8.0,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.receiverMessage,
                      borderRadius: BorderRadius.circular(
                        8.0,
                      ).copyWith(bottomLeft: Radius.zero),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildQuote(context),
                        _buildAttachments(context),

                        if (message.content != null &&
                            message.content!.isNotEmpty)
                          Text(
                            message.content!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),

                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            formattedTime,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // --------------------------------------

                  // --- Conditionally display the Reply Icon ---
                  if (isHighlighted)
                    IconButton(
                      icon: Icon(
                        Icons.reply,
                        color: Colors.black54,
                        size: 20,
                      ), // Reply icon
                      tooltip: 'Reply', // Tooltip for accessibility
                      // Call the onReplyTapped callback when the icon is pressed
                      onPressed: () {
                        print("ReceivedMessage: Reply icon tapped."); // PRINT
                        onReplyTapped?.call(message);
                      },
                      padding: EdgeInsets.zero, // Remove default button padding
                      constraints:
                          BoxConstraints(), // Remove default button constraints
                    ),
                  // ----------------------------------------
                ],
              ),
              // ---------------------------------------------------------------
            ],
          ),
        ),
      ),
    );
  }
}
