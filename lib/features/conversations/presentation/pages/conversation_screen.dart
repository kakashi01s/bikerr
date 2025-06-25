import 'package:bikerr/config/routes/route_names.dart';
import 'package:bikerr/core/theme.dart';
import 'package:bikerr/features/auth/data/models/user_model.dart'; // Assuming UserModel is used
import 'package:bikerr/features/chat/data/models/message_model.dart'; // Assuming MessageModel is used
import 'package:bikerr/features/conversations/presentation/bloc/conversation_bloc.dart'; // Assuming ConversationBloc is used
import 'package:bikerr/features/conversations/presentation/widgets/conversation_page_app_bar.dart'; // Assuming this widget exists
import 'package:bikerr/features/conversations/presentation/widgets/message_tile.dart'; // Assuming this widget exists
import 'package:bikerr/features/conversations/presentation/widgets/search_bar.dart'; // Assuming SearchBarComponent exists
import 'package:bikerr/utils/di/service_locator.dart'; // Assuming sl is used
import 'package:bikerr/utils/enums/enums.dart'; // Assuming PostApiStatus is used
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../data/model/conversation_model.dart'; // Import the intl package


class ConversationScreen extends StatefulWidget {
  const ConversationScreen({super.key});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  // Use late final for bloc created in initState
  late final ConversationBloc _conversationBloc;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Create the bloc instance using GetIt (sl)
    _conversationBloc =
        sl<
          ConversationBloc
        >(); // Assuming ConversationBloc is registered in GetIt

    // Dispatch initial fetch conversations event
    // Assuming FetchAllConversationsEvent triggers the first page load
    _conversationBloc.add(FetchAllConversationsEvent());

    _searchController.addListener(() {
      // Dispatch search event on search input change
      _conversationBloc.add(
        SearchConversationsEvent(query: _searchController.text),
      );
    });

    _scrollController.addListener(() {
      final state = _conversationBloc.state;
      // Check if user is at the bottom, not loading, not reached max
      if (_scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent &&
          state.postApiStatus ==
              PostApiStatus.success && // Check successful initial load status
          !state.hasReachedMax && // Assuming hasReachedMax flag for pagination
          state.fetchMoreStatus != PostApiStatus.loading) {
        // Check status of fetch more
        // Dispatch fetch more conversations event
        _conversationBloc.add(
          FetchMoreConversationsEvent(),
        ); // Assuming this event exists
      }
    });
  }

  @override
  void dispose() {
    // Dispose controllers
    _searchController.dispose();
    _scrollController.dispose();
    // Dispose the bloc if its lifecycle is managed here (created in initState)
    _conversationBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 600;

    return BlocProvider.value(
      value: _conversationBloc,
      child: Scaffold(
        backgroundColor: AppColors.bgColor,
        body: SafeArea(
          child: Column(
            children: [
              const ConversationPageAppBar(),
              SearchBarComponent(
                searchController: _searchController,
              ),
              Expanded(
                child: BlocBuilder<ConversationBloc, ConversationState>(
                  builder: (context, state) {
                    if (state.postApiStatus == PostApiStatus.loading &&
                        state.conversations.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.bikerrRedFill,
                        ),
                      );
                    }

                    if (state.postApiStatus == PostApiStatus.error &&
                        state.conversations.isEmpty) {
                      return Center(
                        child: Text(
                          state.errorMessage ?? "Failed to load conversations",
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: Colors.red),
                        ),
                      );
                    }

                    final List<ConversationModel> sortedConversations =
                    List.from(state.filteredConversations)
                      ..sort((a, b) {
                        DateTime getLatestActivityTimestamp(
                            ConversationModel convo) {
                          DateTime latestKnownTime = convo.createdAt ??
                              DateTime.fromMillisecondsSinceEpoch(0);
                          bool messageTimeFound = false;
                          for (final msg in convo.messages) {
                            if (msg.createdAt != null) {
                              if (!messageTimeFound ||
                                  msg.createdAt!.isAfter(latestKnownTime)) {
                                latestKnownTime = msg.createdAt!;
                                messageTimeFound = true;
                              }
                            }
                          }
                          return latestKnownTime;
                        }

                        final DateTime aLatest =
                        getLatestActivityTimestamp(a);
                        final DateTime bLatest =
                        getLatestActivityTimestamp(b);
                        return bLatest.compareTo(aLatest);
                      });

                    if (sortedConversations.isEmpty &&
                        state.postApiStatus != PostApiStatus.loading) {
                      return const Center(
                        child: Text("No conversations found"),
                      );
                    }

                    return Stack(
                      children: [
                        ListView.builder(
                          controller: _scrollController,
                          itemCount: sortedConversations.length +
                              (state.hasReachedMax ? 0 : 1),
                          itemBuilder: (context, index) {
                            if (index == sortedConversations.length &&
                                !state.hasReachedMax) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(
                                    color: AppColors.bikerrRedFill,
                                  ),
                                ),
                              );
                            }

                            if (index >= sortedConversations.length) {
                              return const SizedBox.shrink();
                            }

                            final convo = sortedConversations[index];

                            if (convo.id == null) {
                              print(
                                  "Warning: Skipping conversation tile with null ID.");
                              return const SizedBox.shrink();
                            }

                            MessageModel latestMessage;

                            final relevantMessages = convo.messages
                                .where((msg) => msg.createdAt != null)
                                .cast<MessageModel>()
                                .toList();

                            if (relevantMessages.isNotEmpty) {
                              relevantMessages.sort((m1, m2) =>
                                  m2.createdAt!.compareTo(m1.createdAt!));
                              latestMessage = relevantMessages.first;
                            } else {
                              latestMessage = MessageModel(
                                id: 0,
                                content: 'No messages yet',
                                createdAt: convo.createdAt ?? DateTime.now(),
                                updatedAt: convo.createdAt ?? DateTime.now(),
                                isEdited: false,
                                parentMessageId: null,
                                senderId: 0,
                                chatRoomId: convo.id,
                                user: UserModel(
                                  id: 0,
                                  name: 'System',
                                  email: 'system@example.com',
                                  traccarId: null,
                                  created_at:
                                  DateTime.fromMillisecondsSinceEpoch(0),
                                  updated_at:
                                  DateTime.fromMillisecondsSinceEpoch(0),
                                  isVerified: true,
                                  jwtRefreshToken: '',
                                  jwtAccessToken: '',
                                  traccarToken: '',
                                  profileImageKey: '',
                                  sessionCookie: ''
                                ),
                                timestamp: (convo.createdAt ?? DateTime.now())
                                    .toIso8601String(),
                                parentMessage: null,
                                attachments: [],
                              );
                            }

                            final bool isLatestMessageImage = latestMessage
                                .attachments
                                .any((attachment) => attachment.fileType
                                .startsWith('image/'));

                            return GestureDetector(
                              onTap: () {
                                final int chatRoomIdToNavigate = convo.id!;
                                final String chatRoomNameToNavigate =
                                    convo.name ?? 'Unnamed Conversation';

                                Navigator.pushNamed(
                                  context,
                                  RoutesName.baseChatScreen,
                                  arguments: {
                                    'chatRoomId': chatRoomIdToNavigate,
                                    'chatRoomName': chatRoomNameToNavigate,
                                  },
                                );
                              },
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isLargeScreen ? 20 : 10,
                                  vertical: 5,
                                ),
                                child: MessageTile(
                                  senderName: latestMessage.user.name ?? 'Unknown Sender',
                                  name: convo.name ?? 'Unnamed Conversation',
                                  message: latestMessage!.content ?? "",
                                  time: latestMessage.createdAt ?? convo.createdAt ?? DateTime.now(),
                                  unreadCount: convo.unreadCount ?? 0,
                                  isImageMessage: isLatestMessageImage,
                                ),
                              ),
                            );
                          },
                        ),
                        if (state.fetchMoreStatus == PostApiStatus.error)
                          const Positioned(
                            bottom: 10,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Text(
                                "Failed to load more conversations",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ),
                        if (state.fetchMoreStatus == PostApiStatus.loading)
                          const Positioned(
                            bottom: 10,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.bikerrRedFill,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}