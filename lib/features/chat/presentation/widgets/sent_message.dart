// In lib/features/chat/presentation/widgets/sent_message.dart

import 'package:bikerr/core/theme.dart'; // Assuming your theme is here
import 'package:bikerr/config/constants.dart'; // Import constants for S3_BASE_URL
import 'package:bikerr/features/chat/data/models/message_model.dart'; // Import MessageModel
import 'package:bikerr/services/session/session_manager.dart'; // Import SessionManager
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Import BlocProvider/BlocContext
import 'package:bikerr/features/chat/presentation/bloc/chat_bloc.dart'; // Import ChatBloc and Event
import 'package:bikerr/utils/enums/enums.dart'; // Assuming PostApiStatus enum exists
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart'
    as path; // Import the path package for joining URLs
// Keep download related imports for now, as the viewer will need them
import 'package:permission_handler/permission_handler.dart'; // Import for permissions
import 'package:path_provider/path_provider.dart'; // Import for getting directory paths
import 'package:dio/dio.dart'; // Import Dio for downloading (or http)

// Define the callback type for image taps
typedef OnImageTapCallback = void Function(String imageUrl, String fileName);

// Define the callback type for reply icon tap
typedef OnReplyTappedCallback = void Function(MessageModel message);

class SentMessage extends StatelessWidget {
  final MessageModel message; // The message data model
  final VoidCallback? onLongPress; // Callback for long press
  final bool isHighlighted; // Flag to indicate if message is highlighted

  // --- ADDED: Callback for tapping on an image attachment ---
  final OnImageTapCallback? onImageTap;
  // --------------------------------------------------------

  // --- ADDED: Callback for tapping the reply icon ---
  final OnReplyTappedCallback? onReplyTapped;
  // -------------------------------------------------

  // Consider making sendingStatus part of the MessageModel itself if possible,
  // managed by the BLoC to reflect the message's state (sending, sent, failed).
  // For now, kept as a separate parameter.
  final PostApiStatus? sendingStatus;

  const SentMessage({
    super.key,
    required this.message,
    this.onLongPress,
    this.isHighlighted = false,
    this.onImageTap, // <-- Include in constructor
    this.onReplyTapped, // <-- Include in constructor
    this.sendingStatus, // Optional sending status
  });

  // --- New function to handle file download ---
  // This function will likely be moved to the Image Viewer widget later.
  // Keeping it here for now but it's no longer called by tapping the image directly.
  Future<void> _downloadAttachment(
    BuildContext context,
    String url,
    String fileName,
  ) async {
    // Request storage permission
    var status = await Permission.storage.request();
    if (status.isGranted) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final savePath = path.join(directory.path, fileName);

        final dio = Dio();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Downloading $fileName...')));

        await dio.download(
          url,
          savePath,
          onReceiveProgress: (received, total) {
            if (total != -1) {
              print(
                'Download progress: ${(received / total * 100).toStringAsFixed(0)}%',
              );
            }
          },
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloaded $fileName to $savePath'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () {
                OpenFilex.open(savePath);
              },
            ),
          ),
        );
      } catch (e) {
        print('Error downloading file: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to download $fileName')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage permission denied')),
      );
    }
  }
  // -------------------------------------------

  // Widget to build and display message attachments
  Widget _buildAttachments(BuildContext context) {
    // Check if there are any attachments to display
    if (message.attachments.isEmpty) {
      return const SizedBox.shrink(); // Return empty box if no attachments
    }

    // Build a column of attachment widgets
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.end, // Align attachments to the end
      children:
          message.attachments.map((attachment) {
            // Construct the full attachment URL safely
            final attachmentUrl = path.join(AppUrl.S3_BASE_URL, attachment.key);
            // Determine the filename from the key
            final fileName = path.basename(attachment.key);

            // Check if the attachment is an image based on file type
            if (attachment.fileType.startsWith('image/') ||
                [
                  'jpg',
                  'jpeg',
                  'png',
                  'gif',
                ].contains(attachment.fileType.toLowerCase())) {
              // Display the image using Image.network with loading and error builders
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: GestureDetector(
                  onTap: () {
                    print(
                      "SentMessage: Tap detected on image attachment. Calling onImageTap.",
                    );
                    onImageTap?.call(attachmentUrl, fileName);
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      attachmentUrl,
                      fit: BoxFit.cover,
                      width: 150,
                      height: 150,
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
                          'SentMessage: Failed to load image from URL: $attachmentUrl, Exception: $exception',
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
              // Handle non-image attachments (e.g., display filename, provide download option)
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: GestureDetector(
                  onTap: () {
                    print(
                      "SentMessage: Tap detected on file attachment. Calling _downloadAttachment.",
                    );
                    _downloadAttachment(context, attachmentUrl, fileName);
                  },
                  child: Container(
                    padding: EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: AppColors.senderMessage.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.attach_file,
                          color: Colors.white70,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Attachment: ${fileName}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.white70),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.download, color: Colors.white70, size: 16),
                      ],
                    ),
                  ),
                ),
              );
            }
          }).toList(),
    );
  }

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
        border: Border(left: BorderSide(color: Colors.white70, width: 4.0)),
        color: AppColors.senderMessage.withOpacity(0.8),
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
              color: Colors.white70,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2.0),
          Text(
            parentContent,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int? currentUserId = int.tryParse(
      SessionManager.instance.userId ?? '',
    );
    final bool isSent =
        currentUserId != null && message.senderId == currentUserId;

    if (!isSent) {
      return const SizedBox.shrink();
    }

    final DateTime? createdAt = message.createdAt;
    final time =
        (createdAt != null)
            ? TimeOfDay.fromDateTime(createdAt.toLocal()).format(context)
            : '—';

    final bool isSending = sendingStatus == PostApiStatus.loading;

    // Wrap with GestureDetector for long press detection and apply highlight color
    return GestureDetector(
      onLongPress: onLongPress,
      // onTap is handled in ChatScreen's GestureDetector to clear highlight
      child: Container(
        // Moved highlight color application outside the inner Row for better visual area
        color:
            isHighlighted
                ? AppColors.senderMessage.withOpacity(0.3)
                : Colors.transparent,
        padding: const EdgeInsets.symmetric(
          horizontal: 4.0,
        ), // Keep padding for highlight visual
        child: Align(
          alignment: Alignment.centerRight,
          // --- MODIFIED: Wrap the message bubble and reply icon in a Row ---
          child: Row(
            mainAxisSize: MainAxisSize.min, // Row takes minimum space
            crossAxisAlignment:
                CrossAxisAlignment.center, // Vertically align items
            children: [
              // --- Conditionally display the Reply Icon ---
              if (isHighlighted)
                IconButton(
                  icon: Icon(
                    Icons.reply,
                    color: Colors.white70,
                    size: 20,
                  ), // Reply icon
                  tooltip: 'Reply', // Tooltip for accessibility
                  // Call the onReplyTapped callback when the icon is pressed
                  onPressed: () {
                    print("SentMessage: Reply icon tapped."); // PRINT
                    onReplyTapped?.call(message);
                  },
                  padding: EdgeInsets.zero, // Remove default button padding
                  constraints:
                      BoxConstraints(), // Remove default button constraints
                ),
              // ----------------------------------------

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
                  color: AppColors.senderMessage,
                  borderRadius: BorderRadius.circular(
                    8.0,
                  ).copyWith(bottomRight: Radius.zero),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildQuote(context),
                    _buildAttachments(context),

                    if (message.content != null && message.content!.isNotEmpty)
                      Text(
                        message.content!,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                      ),

                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSending)
                          const Padding(
                            padding: EdgeInsets.only(right: 4.0),
                            child: SizedBox(
                              width: 12.0,
                              height: 12.0,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white70,
                                ),
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            time,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // --------------------------------------
            ],
          ),
          // ---------------------------------------------------------------
        ),
      ),
    );
  }
}
