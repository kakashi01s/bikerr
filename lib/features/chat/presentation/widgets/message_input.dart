// In lib/features/chat/presentation/widgets/message_input.dart

import 'dart:io';
import 'package:bikerr/core/theme.dart'; // Assuming your theme is here
import 'package:bikerr/features/chat/data/models/message_model.dart'; // Import MessageModel
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class MessageInput extends StatefulWidget {
  final TextEditingController messageController;
  final int
  conversationId; // This might not be directly used in MessageInput's logic but kept if needed elsewhere
  final Function(String content, File? imageFile)
  onSendMessage; // Callback to send message

  // Parameters for reply mode
  final MessageModel?
  replyingToMessage; // The message being replied to (from BLoC state via ChatScreen)
  final VoidCallback
  onCancelReply; // Callback to clear reply mode (dispatches SetReplyingToMessageEvent(null) in ChatScreen)

  const MessageInput({
    super.key,
    required this.messageController,
    required this.conversationId, // Kept as per your code
    required this.onSendMessage,
    this.replyingToMessage, // Optional as it can be null
    required this.onCancelReply, // Required callback
  });

  @override
  _MessageInputState createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final ImagePicker _picker = ImagePicker(); // Instance of ImagePicker
  File? _selectedImage; // Stores the selected image file

  // Function to pick an image from the gallery
  void _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        // Update state with the selected image file
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      // Handle potential errors during image picking (e.g., permissions)
      print('MessageInput: Error picking image: $e');
      // Optionally show a SnackBar to the user
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Failed to pick image.")));
      }
    }
  }

  // Function to handle sending the message or reply
  void _send() {
    final text =
        widget.messageController.text.trim(); // Get trimmed text from input

    // Check if currently in reply mode
    final isInReplyMode = widget.replyingToMessage != null;

    // Determine if a message should be sent based on content/image and mode
    bool shouldSend = false;
    if (isInReplyMode) {
      // In reply mode, require text content.
      // If your backend/BLoC supports image replies, modify this condition.
      shouldSend = text.isNotEmpty;
    } else {
      // In normal message mode, require either text or an image.
      shouldSend = text.isNotEmpty || _selectedImage != null;
    }

    // If criteria for sending are met
    if (shouldSend) {
      // Call the provided onSendMessage callback, passing text and selected image
      // The ChatScreen will handle dispatching the correct BLoC event (SendMessage or ReplyToMessage)
      widget.onSendMessage(text, _selectedImage);

      // Clear the input field and selected image immediately for better UX
      widget.messageController.clear();
      setState(() {
        _selectedImage = null; // Clear selected image
      });

      // Important: DO NOT call widget.onCancelReply() here.
      // The BLoC handler (in ChatBloc) is responsible for clearing the
      // replyingToMessage state after the message is successfully sent (or fails).
      // The ChatScreen's BlocBuilder for MessageInput will rebuild when the state changes.
    } else {
      // Provide feedback to the user if trying to send an empty message/reply
      if (isInReplyMode) {
        // Show a snackbar indicating reply cannot be empty
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Reply cannot be empty.")));
      } else if (text.isEmpty && _selectedImage == null) {
        // Show a snackbar indicating a new message needs text or an image
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cannot send an empty message.")),
        );
      }
      // No action needed if neither condition is met (should not happen with the shouldSend logic)
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Adjust padding based on whether a reply is active to make space for the preview
    final double bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 15.0,
        right: 15.0,
        top:
            widget.replyingToMessage != null
                ? 5.0 // Add top padding when showing reply preview
                : 10.0,
        bottom: 10.0 + bottomPadding, // Include keyboard padding
      ),
      decoration: BoxDecoration(
        color:
            Theme.of(
              context,
            ).cardColor, // Use card color or a suitable background
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3), // Shadow at the top
          ),
        ],
      ),
      child: Column(
        // Use a Column to stack the reply preview and the input row
        mainAxisSize: MainAxisSize.min, // Column should take minimum space
        crossAxisAlignment:
            CrossAxisAlignment.start, // Align preview to the start
        children: [
          // Display the reply preview UI if replyingToMessage is not null
          if (widget.replyingToMessage != null)
            Container(
              margin: const EdgeInsets.only(
                bottom: 8.0,
              ), // Space between preview and input
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 12.0,
              ),
              decoration: BoxDecoration(
                color: Colors.grey[200], // Light background for the preview
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  // Optional: Add a small vertical line indicator
                  Container(
                    width: 4.0,
                    color: AppColors.buttonColor, // Or a distinct accent color
                    margin: const EdgeInsets.only(right: 8.0),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Display sender name of the message being replied to
                        Text(
                          'Replying to ${widget.replyingToMessage!.user?.name ?? 'Unknown'}',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color:
                                AppColors
                                    .buttonColor, // Highlight color for sender name
                          ),
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis, // Truncate long names
                        ),
                        const SizedBox(height: 2.0),
                        // Display content snippet of the message being replied to
                        Text(
                          widget.replyingToMessage!.content ??
                              '', // Handle null content
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.black87),
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis, // Truncate long content
                        ),
                      ],
                    ),
                  ),
                  // Button to cancel the reply mode
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 20.0,
                      color: Colors.grey,
                    ),
                    onPressed:
                        widget
                            .onCancelReply, // Use the provided cancel callback
                    padding: EdgeInsets.zero, // Reduce button padding
                    constraints: BoxConstraints(), // Allow button to shrink
                    splashRadius: 20.0, // Control splash radius
                  ),
                ],
              ),
            ),
          // The row containing the input field and send button
          Row(
            crossAxisAlignment:
                _selectedImage != null
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment
                        .end, // Align items based on image presence
            children: [
              // Image picker button (only shown if no image selected and NOT in reply mode)
              if (_selectedImage == null && widget.replyingToMessage == null)
                IconButton(
                  icon: const Icon(Icons.image),
                  color: AppColors.hintColor,
                  onPressed: _pickImage, // Call the image picker function
                ),
              // Display selected image thumbnail (only shown if image selected and NOT in reply mode)
              if (_selectedImage != null && widget.replyingToMessage == null)
                Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 4.0,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          8.0,
                        ), // Rounded corners for thumbnail
                        child: Image.file(
                          _selectedImage!, // Non-null asserted as it's checked
                          height: 40, // Adjust size as needed
                          width: 40,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    // Button to clear the selected image
                    Positioned(
                      right: 0,
                      top: 0,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedImage = null; // Clear selected image
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                Colors
                                    .black54, // Dark background for close button
                            borderRadius: BorderRadius.circular(
                              10,
                            ), // Rounded corners
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              // Expanded TextField for message input
              Expanded(
                child: TextField(
                  controller: widget.messageController, // Assign the controller
                  keyboardType: TextInputType.text, // Allow multiline input
                  maxLines: null, // Allows unlimited lines, scrolls vertically
                  minLines: 1, // Starts with at least one line
                  decoration: InputDecoration(
                    hintText:
                        widget.replyingToMessage != null
                            ? 'Reply...' // Hint text changes based on mode
                            : 'Send a message...',
                    border: InputBorder.none, // Remove default border
                    contentPadding: EdgeInsets.all(8), // Remove default padding
                  ),
                  style: GoogleFonts.poppins(
                    fontSize: FontSizes.standardUp,
                    color: AppColors.bgColor,
                    fontWeight: FontWeight.w300,
                  ),
                  // Apply text style
                  textCapitalization:
                      TextCapitalization.sentences, // Capitalize sentences
                ),
              ),
              // Send button
              IconButton(
                icon: const Icon(Icons.send),
                color: AppColors.buttonColor, // Button color
                onPressed: _send, // Call the send function
              ),
            ],
          ),
        ],
      ),
    );
  }
}
