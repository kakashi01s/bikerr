import 'dart:async';
import 'dart:io';
import 'package:bikerr/features/chat/data/models/message_model.dart';
import 'package:bikerr/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:bikerr/features/chat/presentation/widgets/message_input.dart'; // Assuming MessageInput widget exists
import 'package:bikerr/features/chat/presentation/widgets/received_message.dart'; // Assuming ReceivedMessage widget exists
import 'package:bikerr/features/chat/presentation/widgets/sent_message.dart'; // Assuming SentMessage widget exists
import 'package:bikerr/utils/enums/enums.dart';
import 'package:bikerr/utils/widgets/common/image_viewer.dart'; // Assuming ImageViewerScreen is here
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Typedef for image tap callback
typedef OnImageTapCallback = void Function(String imageUrl, String fileName);

// Typedef for reply icon tap callback
typedef OnReplyTappedCallback = void Function(MessageModel message);

class ChatScreen extends StatefulWidget {
  final int chatRoomId;
  final ScrollPhysics? scrollPhysics; // Added scrollPhysics parameter

  const ChatScreen({
    super.key,
    required this.chatRoomId,
    this.scrollPhysics, // Added to constructor
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  final ScrollController _chatScreenScrollController = ScrollController();
  bool _isFetchingOlderMessages = false;
  late ChatBloc _chatBloc;
  String userId = '';
  int?
  lastFetchedMessageId; // To keep track of the last message ID to fetch from

  @override
  void initState() {
    super.initState();
    _chatBloc = context.read<ChatBloc>();
    _fetchUserId();
    _chatScreenScrollController.addListener(onScroll);
  }

  void onScroll() {
    final position = _chatScreenScrollController.position;

    // Only trigger fetching if the Chat tab is active
    const triggerThreshold = 50; // Threshold for fetching more messages

    if (position.pixels >= position.maxScrollExtent - triggerThreshold &&
        !_isFetchingOlderMessages) {
      _isFetchingOlderMessages = true;
      _chatBloc.add(
        GetOlderMessagesEvent(
          chatRoomId: widget.chatRoomId,
          pageSize: 20,
          cursorMessageId: lastFetchedMessageId,
        ),
      );
    }
  }

  Future<void> _fetchUserId() async {
    final id = await _storage.read(key: 'userId') ?? '';
    if (mounted) {
      setState(() => userId = id);
    }
  }

  void _handleSend(String content, File? imageFile) {
    if (userId.isEmpty) return;

    final replyTo = _chatBloc.state.replyingToMessage;
    if (replyTo != null && content.trim().isNotEmpty) {
      _chatBloc.add(
        ReplyToMessageEvent(
          parentMessageId: replyTo.id,
          content: content.trim(),
        ),
      );
      _cancelReply();
      return;
    }

    if (content.trim().isNotEmpty || imageFile != null) {
      _chatBloc.add(
        SendMessageEvent(
          chatRoomId: widget.chatRoomId,
          content: content.trim(),
          imageFile: imageFile,
        ),
      );
    }
  }

  void _cancelReply() =>
      _chatBloc.add(const SetReplyingToMessageEvent(message: null));

  void _cancelHighlight() =>
      _chatBloc.add(const SetHighlightedMessageEvent(message: null));

  void _onImageTap(String url, String name) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImageViewerScreen(imageUrl: url, fileName: name),
      ),
    );
  }

  // New method to handle the reply icon tap
  void _handleReplyTapped(MessageModel message) {
    _chatBloc.add(EnterReplyModeEvent(highlightedMessageId: message.id));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // REMOVED: The conditional AppBar for highlighted message (as per your original code)
        Expanded(
          child: BlocListener<ChatBloc, ChatState>(
            listener: (context, state) {
              if (state.postApiStatus == PostApiStatus.success) {
                lastFetchedMessageId = state.lastMessageId;
                _isFetchingOlderMessages = false;
              } else if (state.postApiStatus == PostApiStatus.error) {
                _isFetchingOlderMessages = false; // Reset on error too
                if (state.errorMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${state.errorMessage}')),
                  );
                }
              }
            },
            child: BlocBuilder<ChatBloc, ChatState>(
              // Only rebuild the list when messages or highlightedMessage changes
              buildWhen:
                  (p, c) =>
                      p.messages != c.messages ||
                      p.highlightedMessage != c.highlightedMessage,
              builder: (context, state) {
                final messages = state.messages;
                return ListView.builder(
                  controller: _chatScreenScrollController ?? ScrollController(),
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isSender = msg.senderId.toString() == userId;
                    final isHighlighted =
                        msg ==
                        state
                            .highlightedMessage; // Determine if this message is highlighted

                    return GestureDetector(
                      key: ValueKey(msg.id),
                      // On short tap, if highlighted, clear highlight. If not, do nothing (or handle like opening image).
                      onTap: () {
                        if (isHighlighted) {
                          _cancelHighlight(); // Clear highlight on tap if already highlighted
                        }
                        // You might want to add logic here to handle tap on message (e.g., opening image)
                      },
                      onLongPress:
                          () => _chatBloc.add(
                            SetHighlightedMessageEvent(message: msg),
                          ),
                      child:
                          isSender
                              ? SentMessage(
                                message: msg,
                                isHighlighted:
                                    isHighlighted, // Pass highlighted status
                                onImageTap: _onImageTap,
                                onReplyTapped:
                                    _handleReplyTapped, // Pass the new callback
                              )
                              : ReceivedMessage(
                                message: msg,
                                showName: true,
                                isHighlighted:
                                    isHighlighted, // Pass highlighted status
                                onImageTap: _onImageTap,
                                onReplyTapped:
                                    _handleReplyTapped, // Pass the new callback
                              ),
                    );
                  },
                  // Apply the scrollPhysics passed from the parent
                  physics: widget.scrollPhysics,
                );
              },
            ),
          ),
        ),
        BlocBuilder<ChatBloc, ChatState>(
          buildWhen: (p, c) => p.replyingToMessage != c.replyingToMessage,
          builder: (context, state) {
            return MessageInput(
              messageController: _messageController,
              conversationId: widget.chatRoomId,
              replyingToMessage: state.replyingToMessage,
              onCancelReply: _cancelReply,
              onSendMessage: _handleSend,
            );
          },
        ),
      ],
    );
  }
}
