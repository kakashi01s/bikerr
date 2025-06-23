// In lib/features/chat/presentation/bloc/chat_bloc.dart

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:bikerr/features/chat/data/models/chat_room_model.dart'; // Import ChatRoomModel
import 'package:bikerr/features/chat/data/models/chat_room_user_model.dart';
import 'package:bikerr/features/chat/data/models/message_model.dart'; // Assuming you have this model
import 'package:bikerr/features/chat/domain/usecases/get_all_messages_in_chatroom_usecase.dart';
import 'package:bikerr/features/chat/domain/usecases/get_chatroomDetails_usecase.dart';
import 'package:bikerr/features/chat/domain/usecases/get_older_messages_in_chat_room_usecase.dart';
import 'package:bikerr/features/chat/domain/usecases/remove_user_from_chat_usecase.dart';
import 'package:bikerr/features/chat/domain/usecases/send_message_usecase.dart';
import 'package:bikerr/features/chat/domain/usecases/update_last_read_usecase.dart';
import 'package:bikerr/features/chat/domain/usecases/reply_to_message_usecase.dart';
import 'package:bikerr/services/session/session_manager.dart';
import 'package:bikerr/utils/apiResult/result.dart';
import 'package:bikerr/utils/apiResult/api_error.dart'; // Corrected import
import 'package:bikerr/utils/enums/enums.dart';
import 'package:bikerr/utils/socket/socket_service.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:dartz/dartz.dart';
import 'package:collection/collection.dart'; // For firstWhereOrNull

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final RemoveUserFromChatUsecase removeUserFromChatUsecase;
  final GetAllMessagesInChatroomUsecase getAllMessagesInChatroomUsecase;
  final GetOlderMessagesInChatroomUsecase getOlderMessagesInChatroomUsecase;
  final SendMessageUseCase sendMessageUsecase;
  final UpdateLastReadUsecase updateLastReadUsecase;
  final GetChatroomdetailsUsecase getChatroomdetailsUsecase;
  final ReplyToMessageUsecase replyToMessageUseCase;
  final SocketService _socketService = SocketService();
  final SessionManager session = SessionManager.instance;

  bool _isSocketListening = false;

  ChatBloc(
    this.getChatroomdetailsUsecase,
    this.removeUserFromChatUsecase, {
    required this.updateLastReadUsecase,
    required this.getAllMessagesInChatroomUsecase,
    required this.getOlderMessagesInChatroomUsecase,
    required this.sendMessageUsecase,
    required this.replyToMessageUseCase,
  }) : super(const ChatState()) {
    on<GetAllMessagesEvent>(_onGetAllMessagesEvent);
    on<GetOlderMessagesEvent>(_onGetOlderMessagesEvent);
    on<ReceivedMessageEvent>(_onReceivedMessageEvent);
    on<SendMessageEvent>(_onSendMessageEvent);
    on<LeaveChatRoomEvent>(_onLeaveChatRoomEvent);
    on<UpdateLastReadEvent>(_onUpdateLastReadEvent);
    on<ReplyToMessageEvent>(_onReplyToMessageEvent);
    on<SetHighlightedMessageEvent>(_onSetHighlightedMessageEvent);
    on<EnterReplyModeEvent>(_onEnterReplyModeEvent);
    on<SetReplyingToMessageEvent>(_onSetReplyingToMessageEvent);
    on<GetChatRoomDetail>(_onGetChatRoomDetail);
    on<RemoveUserEvent>(_onRemoveUserFromChatGroup);

    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    print("ChatBloc: Setting up socket listeners");
    if (_isSocketListening) {
      print("ChatBloc: Socket listeners already set up");
      return;
    }
    _isSocketListening = true;

    _socketService.socket.on('newMessage', (data) {
      print('ChatBloc: STEP 1 ---------> RECEIVE (newMessage): $data');
      try {
        if (data is Map<String, dynamic>) {
          final int? receivedChatRoomId = data['chatRoomId'];

          // IMPORTANT: Check if the received message is for the currently viewed chat room
          if (receivedChatRoomId != null &&
              state.chatRoomDetails != null &&
              receivedChatRoomId == state.chatRoomDetails!.id) {
            print(
              "ChatBloc: Received message for current room ${receivedChatRoomId}. Dispatching ReceivedMessageEvent.",
            );
            add(
              ReceivedMessageEvent(
                message: data,
                chatRoomId: receivedChatRoomId,
              ),
            );
          } else if (receivedChatRoomId != null) {
            print(
              "ChatBloc: Received message for room $receivedChatRoomId, not the current room ${state.chatRoomDetails?.id}. Skipping.",
            );
            // You might want to handle notifications for messages in other rooms here
          } else {
            print("ChatBloc: Received socket data missing chatRoomId key.");
          }
        } else {
          print("ChatBloc: Received socket data is not a Map: $data");
        }
      } catch (e, stackTrace) {
        print(
          "ChatBloc: Error processing socket message ('newMessage'): $e\n$stackTrace",
        );
      }
    });

    _socketService.socket.on('messageEdited', (data) {
      print('ChatBloc: Received (messageEdited): $data');
      if (data is Map<String, dynamic>) {
        final int? editedMessageId = data['id'];
        final int? chatRoomId = data['chatRoomId'];
        // IMPORTANT: Check if the edited message is for the currently viewed chat room
        if (editedMessageId != null &&
            chatRoomId != null &&
            state.chatRoomDetails != null &&
            chatRoomId == state.chatRoomDetails!.id) {
          try {
            final updatedMessage = MessageModel.fromJson(data);
            final updatedMessages =
                state.messages.map((msg) {
                  if (msg.id == editedMessageId) {
                    return updatedMessage;
                  }
                  return msg;
                }).toList();

            emit(state.copyWith(messages: updatedMessages));
            print('ChatBloc: Updated message $editedMessageId in state.');
          } catch (e, stackTrace) {
            print(
              'ChatBloc: Error processing edited message data: $e\n$stackTrace',
            );
          }
        } else if (chatRoomId != null) {
          print(
            "ChatBloc: Received edited message for room $chatRoomId, not the current room ${state.chatRoomDetails?.id}. Skipping.",
          );
        } else {
          print(
            'ChatBloc: Received edited message data missing id or chatRoomId.',
          );
        }
      } else {
        print('ChatBloc: Received edited message data is not a Map: $data');
      }
    });

    _socketService.socket.on('messageDeleted', (data) {
      print('ChatBloc: Received (messageDeleted): $data');
      if (data is Map<String, dynamic>) {
        final int? deletedMessageId = data['messageId'];
        final int? chatRoomId = data['chatRoomId'];
        // IMPORTANT: Check if the deleted message is for the currently viewed chat room
        if (deletedMessageId != null &&
            chatRoomId != null &&
            state.chatRoomDetails != null &&
            chatRoomId == state.chatRoomDetails!.id) {
          final updatedMessages =
              state.messages
                  .where((msg) => msg.id != deletedMessageId)
                  .toList();

          emit(state.copyWith(messages: updatedMessages));
          print('ChatBloc: Removed message $deletedMessageId from state.');
        } else if (chatRoomId != null) {
          print(
            "ChatBloc: Received deleted message for room $chatRoomId, not the current room ${state.chatRoomDetails?.id}. Skipping.",
          );
        } else {
          print(
            'ChatBloc: Received deleted message data missing messageId or chatRoomId.',
          );
        }
      } else {
        print('ChatBloc: Received deleted message data is not a Map: $data');
      }
    });
  }

  Future<void> _onUpdateLastReadEvent(
    UpdateLastReadEvent event,
    Emitter<ChatState> emit,
  ) async {
    print(
      "ChatBloc: Handling UpdateLastReadEvent for chatRoom ${event.chatRoomId}",
    );

    // Only update last read if we have chat room details and the user is in this room
    if (state.chatRoomDetails != null &&
        state.chatRoomDetails!.id == event.chatRoomId) {
      final result = await updateLastReadUsecase.call(
        chatRoomId: event.chatRoomId,
      );

      result.fold(
        (_) => print(
          'ChatBloc: Successfully updated lastReadAt for chatRoom ${event.chatRoomId}',
        ),
        (err) => print('ChatBloc: Failed to update lastReadAt: ${err.message}'),
      );
    } else {
      print(
        "ChatBloc: Skipping UpdateLastReadEvent - Not in chatRoom ${event.chatRoomId}",
      );
    }
  }

  Future<void> _onGetAllMessagesEvent(
    GetAllMessagesEvent event,
    Emitter<ChatState> emit,
  ) async {
    print(
      "ChatBloc: Handling GetAllMessagesEvent for chatRoom ${event.chatRoomId}, page: ${event.page}, pageSize: ${event.pageSize}",
    );

    if (state.messages.isEmpty) {
      emit(
        state.copyWith(
          postApiStatus: PostApiStatus.loading,
          errorMessage: () => null,
          messages: [],
        ),
      );
      print("ChatBloc: Emitting loading state for initial load.");
    } else {
      print(
        "ChatBloc: Messages not empty, not emitting initial loading state.",
      );
    }

    final result = await getAllMessagesInChatroomUsecase.call(
      chatRoomId: event.chatRoomId,
      page: event.page,
      pageSize: event.pageSize,
    );

    result.fold(
      (dataResult) {
        print(
          "ChatBloc: GetAllMessagesEvent success, received data map result.",
        );
        print("ChatBloc: Raw success data: ${dataResult.data}");

        final Map<String, dynamic>? data = dataResult.data;

        final Map<String, dynamic>? chatRoomJson = data?['chatRoom'];
        ChatRoomModel? fetchedChatRoomDetails;
        if (chatRoomJson != null) {
          try {
            fetchedChatRoomDetails = ChatRoomModel.fromJson(chatRoomJson);
            print("ChatBloc: Successfully parsed ChatRoomModel.");
          } catch (e, stackTrace) {
            print(
              "ChatBloc: Error parsing ChatRoomModel from response: $e\n$stackTrace",
            );
          }
        } else {
          print("ChatBloc: ChatRoom details not found in the response.");
        }

        final List<dynamic> messagesData = data?['messages'] ?? [];
        final Map<String, dynamic>? paginationData = data?['pagination'];
        final int? nextCursor = paginationData?['nextCursor'];
        final bool? backendHasMore = paginationData?['hasMore'];

        final List<MessageModel> messages =
            messagesData
                .map(
                  (json) => MessageModel.fromJson(json as Map<String, dynamic>),
                )
                .toList();

        print("ChatBloc: Parsed ${messages.length} raw messages.");

        // Backend sends OLDEST to NEWEST. Reverse to process from NEWEST to OLDEST.
        final List<MessageModel> reversedMessages = messages.reversed.toList();

        // Deduplicate while maintaining NEWEST to OLDEST order from the reversed list.
        final Set<int> seenMessageIds = {};
        final List<MessageModel> uniqueOrderedMessages = [];

        for (final msg in reversedMessages) {
          if (!seenMessageIds.contains(msg.id)) {
            seenMessageIds.add(msg.id);
            uniqueOrderedMessages.add(msg);
          }
        }

        final List<MessageModel> finalMessagesState = uniqueOrderedMessages;

        print(
          "ChatBloc: Resulted in ${finalMessagesState.length} unique messages after deduplication.",
        );
        // Added debug print for length and IDs before the loop
        print(
          'ChatBloc: finalMessagesState length before print loop: ${finalMessagesState.length}',
        );
        print(
          'ChatBloc: finalMessagesState IDs before print loop: ${finalMessagesState.map((msg) => msg.id).toList()}',
        );

        print(
          '--- Messages in State BEFORE Emit (GetAllMessagesEvent) (Order: NEWEST to OLDEST) ---',
        );
        for (var i = 0; i < finalMessagesState.length; i++) {
          // Simplified print within the loop
          print('Index $i: Message ID: ${finalMessagesState[i].id}');
        }
        print('---------------------------------------------------------');

        final bool hasMore =
            backendHasMore ?? (messages.length >= event.pageSize);

        emit(
          state.copyWith(
            postApiStatus: PostApiStatus.success,
            messages: finalMessagesState,
            hasMoreMessages: hasMore,
            lastMessageId: nextCursor,
            receivedMessage: null,
            highlightedMessage: () => null,
            replyingToMessage: () => null,
            chatRoomDetails:
                () => fetchedChatRoomDetails ?? state.chatRoomDetails,
            errorMessage: () => null,
          ),
        );
        print("ChatBloc: State emitted after GetAllMessagesEvent success.");
        print(
          "ChatBloc: State messages count after emit: ${state.messages.length}",
        );

        print("ChatBloc: Emitting 'joinChat' for chatRoom ${event.chatRoomId}");
        _socketService.socket.emit('joinChat', event.chatRoomId);
      },
      (apiError) {
        print("ChatBloc: GetAllMessagesEvent failed: ${apiError.message}");
        emit(
          state.copyWith(
            postApiStatus: PostApiStatus.error,
            chatRoomDetails: () => null,
            errorMessage: () => apiError.message,
            messages: [],
            loadingOlderMessages: false,
          ),
        );
        print("ChatBloc: State emitted after GetAllMessagesEvent error.");
        print(
          "ChatBloc: State messages count after error emit: ${state.messages.length}",
        );
      },
    );
  }

  Future<void> _onGetOlderMessagesEvent(
    GetOlderMessagesEvent event,
    Emitter<ChatState> emit,
  ) async {
    print(
      "ChatBloc: Handling GetOlderMessagesEvent for chatRoom ${event.chatRoomId}, pageSize: ${event.pageSize}, cursor: ${event.cursorMessageId}",
    );

    if (state.loadingOlderMessages ||
        !state.hasMoreMessages ||
        event.cursorMessageId == null) {
      print(
        "ChatBloc: GetOlderMessagesEvent skipped (loading: ${state.loadingOlderMessages}, hasMore: ${state.hasMoreMessages}, cursor in event: ${event.cursorMessageId})",
      );
      return;
    }

    emit(state.copyWith(loadingOlderMessages: true, errorMessage: () => null));
    print("ChatBloc: Emitting loadingOlderMessages: true state.");

    final result = await getOlderMessagesInChatroomUsecase.call(
      chatRoomId: event.chatRoomId,
      pageSize: event.pageSize,
      cursor: event.cursorMessageId!,
    );

    result.fold(
      (dataResult) {
        print(
          "ChatBloc: GetOlderMessagesEvent success, received data map result.",
        );
        print("ChatBloc: Raw older messages success data: ${dataResult.data}");

        final Map<String, dynamic>? data = dataResult.data;

        final Map<String, dynamic>? chatRoomJson = data?['chatRoom'];
        ChatRoomModel? fetchedChatRoomDetails;
        if (chatRoomJson != null) {
          try {
            fetchedChatRoomDetails = ChatRoomModel.fromJson(chatRoomJson);
            print(
              "ChatBloc: Successfully parsed ChatRoomModel from older messages response.",
            );
          } catch (e, stackTrace) {
            print(
              "ChatBloc: Error parsing ChatRoomModel from older messages response: $e\n$stackTrace",
            );
          }
        } else {
          print(
            "ChatBloc: ChatRoom details not found in the older messages response.",
          );
        }

        final List<dynamic> olderMessagesData = data?['messages'] ?? [];
        final Map<String, dynamic>? paginationData = data?['pagination'];
        final int? nextCursor = paginationData?['nextCursor'];
        final bool? backendHasMore = paginationData?['hasMore'];

        final List<MessageModel> olderMessages =
            olderMessagesData
                .map(
                  (json) => MessageModel.fromJson(json as Map<String, dynamic>),
                )
                .toList();

        print(
          "ChatBloc: Parsed ${olderMessages.length} raw older messages from response.",
        );

        if (olderMessages.isEmpty) {
          print("ChatBloc: No older messages fetched.");
          emit(
            state.copyWith(hasMoreMessages: false, loadingOlderMessages: false),
          );
          print("ChatBloc: Emitting no more older messages state.");
          print(
            "ChatBloc: State messages count after emit (no older): ${state.messages.length}",
          );
          return;
        }

        // state.messages is already NEWEST to OLDEST.
        // olderMessages from backend is OLDEST to NEWEST.
        // We need to append the older messages batch to the existing state list
        // to maintain the overall NEWEST to OLDEST order.

        // Use a Set to efficiently track existing message IDs in the current state
        final Set<int> existingMessageIds =
            state.messages.map((msg) => msg.id).toSet();
        // Use a Set for the current batch to handle potential duplicates within the batch
        final Set<int> seenInBatchIds = {};

        // Filter out older messages that are already in the state AND deduplicate within the batch, maintaining their original OLDEST to NEWEST order from the backend.
        final List<MessageModel> uniqueOlderMessagesToAppend = [];
        // Iterate over the olderMessages in their original backend order (OLDEST to NEWEST)
        for (final msg in olderMessages) {
          if (!existingMessageIds.contains(msg.id) &&
              !seenInBatchIds.contains(msg.id)) {
            seenInBatchIds.add(msg.id);
            uniqueOlderMessagesToAppend.add(
              msg,
            ); // Add in OLDEST to NEWEST order relative to the batch
          }
        }

        if (uniqueOlderMessagesToAppend.isEmpty) {
          print(
            "ChatBloc: Fetched older messages but all were duplicates already in state.",
          );
          emit(
            state.copyWith(
              loadingOlderMessages: false,
              hasMoreMessages: backendHasMore ?? false,
            ),
          );
          print(
            "ChatBloc: Emitting state after finding only duplicates in older messages.",
          );
          print(
            "ChatBloc: State messages count after emit: ${state.messages.length}",
          );
          return;
        }

        // Append the unique older messages batch (which is OLDEST to NEWEST relative to the batch)
        // to the existing state messages list (which is NEWEST to OLDEST overall).
        // This maintains the overall NEWEST to OLDEST order.
        final List<MessageModel> combinedMessages = [
          ...state.messages, // Existing messages (NEWEST to OLDEST)
          ...uniqueOlderMessagesToAppend, // Append the new unique batch (OLDEST to NEWEST relative to the batch)
        ];

        print(
          "ChatBloc: Fetched ${olderMessages.length} older messages, added ${uniqueOlderMessagesToAppend.length} unique messages to state.",
        );
        // Added debug print for length and IDs before the loop
        print(
          'ChatBloc: combinedMessages length before print loop: ${combinedMessages.length}',
        );
        print(
          'ChatBloc: combinedMessages IDs before print loop: ${combinedMessages.map((msg) => msg.id).toList()}',
        );

        print(
          '--- Messages in State BEFORE Emit (GetOlderMessagesEvent) (Order: NEWEST at Index 0) ---', // Updated label
        );
        for (var i = 0; i < combinedMessages.length; i++) {
          // Simplified print within the loop
          print('Index $i: Message ID: ${combinedMessages[i].id}');
        }
        print('---------------------------------------------------------');

        final bool hasMore =
            backendHasMore ?? (olderMessages.length >= event.pageSize);

        emit(
          state.copyWith(
            messages: combinedMessages,
            hasMoreMessages: hasMore,
            loadingOlderMessages: false,
            lastMessageId: nextCursor,
            receivedMessage: null,
            chatRoomDetails:
                () => fetchedChatRoomDetails ?? state.chatRoomDetails,
            errorMessage: () => null,
          ),
        );
        print(
          "ChatBloc: State emitted after GetOlderMessagesEvent success with ${state.messages.length} total messages.",
        );
        print(
          'ChatBloc: New lastMessageId in state after GetOlderMessagesEvent: ${state.lastMessageId}',
        );
      },
      (apiError) {
        print("ChatBloc: GetOlderMessagesEvent failed: ${apiError.message}");
        emit(
          state.copyWith(
            loadingOlderMessages: false,
            errorMessage: () => apiError.message,
          ),
        );
        print("ChatBloc: State emitted after GetOlderMessagesEvent error.");
        print(
          "ChatBloc: State messages count after error emit: ${state.messages.length}",
        );
      },
    );
  }

  Future<void> _onReceivedMessageEvent(
    ReceivedMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    print(
      "ChatBloc: Handling ReceivedMessageEvent for room ${event.chatRoomId}",
    );

    try {
      final Map<String, dynamic> messageData =
          event.message as Map<String, dynamic>;
      final newMsg = MessageModel.fromJson(messageData);
      print("ChatBloc: Parsed received message: ${newMsg.id}");

      // Only add the message if it's for the current chat room
      if (state.chatRoomDetails != null &&
          newMsg.chatRoomId == state.chatRoomDetails!.id) {
        final alreadyExists = state.messages.any((msg) => msg.id == newMsg.id);

        if (!alreadyExists) {
          print("ChatBloc: Adding new message ${newMsg.id} to list");
          // --- CORRECTED: Insert new message at the BEGINNING of the list ---
          // Insert at index 0 to maintain NEWEST to OLDEST order in state
          final updatedMessages = [newMsg, ...state.messages];
          // -----------------------------------------------------------------

          // --- ADDED DEBUG PRINT FOR MESSAGE ORDER IN STATE BEFORE EMIT ---
          print(
            '--- Messages in State BEFORE Emit (ReceivedMessageEvent) (Order: NEWEST to OLDEST) ---',
          ); // Corrected label
          for (var i = 0; i < updatedMessages.length; i++) {
            print(
              'Index $i: Message ID: ${updatedMessages[i].id}, Content: ${updatedMessages[i].content?.substring(0, min(20, updatedMessages[i].content?.length ?? 0))}..., CreatedAt: ${updatedMessages[i].createdAt}',
            ); // Print snippet of content
          }
          print('---------------------------------------------------------');
          // ---------------------------------------------------------------

          emit(
            state.copyWith(
              receivedMessage: newMsg,
              messages: updatedMessages, // Emit the new list
              errorMessage: () => null,
            ),
          );
          print("ChatBloc: State emitted with new message ${newMsg.id}.");
          print(
            "ChatBloc: State messages count after emit: ${state.messages.length}",
          ); // Verify state after emit

          print(
            "ChatBloc: Dispatching UpdateLastReadEvent after receiving new message",
          );
          add(UpdateLastReadEvent(chatRoomId: event.chatRoomId));
        } else {
          print(
            "ChatBloc: Received message ${newMsg.id} already exists in state, skipping add.",
          );
        }
      } else {
        print(
          "ChatBloc: Received message ${newMsg.id} is not for the current chat room ${state.chatRoomDetails?.id}. Skipping.",
        );
      }
    } catch (e, stackTrace) {
      print("ChatBloc: Error processing received message: $e\n$stackTrace");
    }
  }

  Future<void> _onSendMessageEvent(
    SendMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    print("ChatBloc: Handling SendMessageEvent");

    // Optional: Optimistically add a pending message to the state here
    // This requires a MessageModel with a temporary ID or status
    // emit(state.copyWith(postApiStatus: PostApiStatus.loading, ...));

    emit(
      state.copyWith(
        postApiStatus: PostApiStatus.loading,
        errorMessage: () => null,
      ),
    );
    print("ChatBloc: Emitting loading state for sending message.");

    final result = await sendMessageUsecase.call(
      chatRoomId: event.chatRoomId,
      content: event.content,
      imageFile: event.imageFile,
    );

    result.fold(
      (successResult) {
        print("ChatBloc: SendMessageEvent success");
        // The new message will arrive via the socket ('newMessage' event)
        // and be handled by _onReceivedMessageEvent to update the state.
        // We just need to reset the sending status here.
        emit(
          state.copyWith(
            postApiStatus: PostApiStatus.success,
            errorMessage: () => null,
          ),
        );
        print(
          "ChatBloc: State emitted after SendMessageEvent success (status reset).",
        );
        print(
          "ChatBloc: State messages count after emit: ${state.messages.length}",
        ); // Verify state after emit
      },
      (error) {
        print("ChatBloc: SendMessageEvent failed: ${error.message}");
        // Optional: Update the status of the pending message to error if optimistic update was used
        emit(
          state.copyWith(
            postApiStatus: PostApiStatus.error,
            errorMessage: () => error.message,
          ),
        );
        print("ChatBloc: State emitted after SendMessageEvent error.");
        print(
          "ChatBloc: State messages count after error emit: ${state.messages.length}",
        ); // Verify state after emit
      },
    );
  }

  Future<void> _onReplyToMessageEvent(
    ReplyToMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    print(
      "ChatBloc: Handling ReplyToMessageEvent for parent ${event.parentMessageId} with content: ${event.content}",
    );

    // Optional: Optimistically add a pending reply message
    // emit(state.copyWith(postApiStatus: PostApiStatus.loading, ...));

    emit(
      state.copyWith(
        postApiStatus: PostApiStatus.loading,
        errorMessage: () => null,
      ),
    );
    print("ChatBloc: Emitting loading state for sending reply.");

    final result = await replyToMessageUseCase.call(
      parentMessageId: event.parentMessageId,
      content: event.content,
    );

    result.fold(
      (successResult) {
        print("ChatBloc: ReplyToMessageEvent success");
        // The new reply message will arrive via the socket ('newMessage' event)
        // and be handled by _onReceivedMessageEvent.
        // We just need to reset the sending status and clear modes here.
        emit(
          state.copyWith(
            postApiStatus: PostApiStatus.success,
            highlightedMessage: () => null,
            replyingToMessage: () => null,
            errorMessage: () => null,
          ),
        );
        print(
          "ChatBloc: State emitted after ReplyToMessageEvent success (status reset, clearing modes).",
        );
        print(
          "ChatBloc: State messages count after emit: ${state.messages.length}",
        ); // Verify state after emit
      },
      (error) {
        print("ChatBloc: ReplyToMessageEvent failed: ${error.message}");
        // Optional: Update the status of the pending reply message to error
        emit(
          state.copyWith(
            postApiStatus: PostApiStatus.error,
            highlightedMessage: () => null,
            replyingToMessage: () => null,
            errorMessage: () => error.message,
          ),
        );
        print(
          "ChatBloc: State emitted after ReplyToMessageEvent error (clearing modes).",
        );
        print(
          "ChatBloc: State messages count after error emit: ${state.messages.length}",
        ); // Verify state after emit
      },
    );
  }

  Future<void> _onSetHighlightedMessageEvent(
    SetHighlightedMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    print(
      "ChatBloc: Handling SetHighlightedMessageEvent: ${event.message?.id ?? 'Clearing'}",
    );

    emit(
      state.copyWith(
        highlightedMessage: () => event.message,
        replyingToMessage: () => null, // Clear replyingTo when highlighting
        errorMessage: () => null,
      ),
    );

    print(
      "ChatBloc: State emitted after SetHighlightedMessageEvent. Highlighted: ${state.highlightedMessage?.id ?? 'null'}, Replying: ${state.replyingToMessage?.id ?? 'null'}",
    );
    print(
      "ChatBloc: State messages count after emit: ${state.messages.length}",
    ); // Verify state after emit
  }

  Future<void> _onEnterReplyModeEvent(
    EnterReplyModeEvent event,
    Emitter<ChatState> emit,
  ) async {
    print(
      "ChatBloc: Handling EnterReplyModeEvent for highlighted message ${event.highlightedMessageId}",
    );

    final messageToReplyTo = state.messages.firstWhereOrNull(
      (msg) => msg.id == event.highlightedMessageId,
    );

    if (messageToReplyTo != null) {
      print(
        "ChatBloc: Found highlighted message ${messageToReplyTo.id}. Transitioning to reply mode.",
      );
      emit(
        state.copyWith(
          replyingToMessage: () => messageToReplyTo,
          highlightedMessage:
              () => null, // Clear highlighted when entering reply mode
          errorMessage: () => null,
        ),
      );
      print(
        "ChatBloc: State emitted with replyingToMessage: ${state.replyingToMessage?.id ?? 'null'} and highlightedMessage: ${state.highlightedMessage?.id ?? 'null'}.",
      );
      print(
        "ChatBloc: State messages count after emit: ${state.messages.length}",
      ); // Verify state after emit
    } else {
      print(
        "ChatBloc: Highlighted message ${event.highlightedMessageId} not found in state. Cannot enter reply mode.",
      );
      emit(
        state.copyWith(
          highlightedMessage: () => null, // Ensure highlighted is cleared
          errorMessage: () => 'Failed to find message to reply to.',
        ),
      );
      print(
        "ChatBloc: Highlighted message not found, clearing highlight mode and setting error.",
      );
      print(
        "ChatBloc: State messages count after emit: ${state.messages.length}",
      ); // Verify state after emit
    }
  }

  Future<void> _onSetReplyingToMessageEvent(
    SetReplyingToMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    print(
      "ChatBloc: Handling SetReplyingToMessageEvent: ${event.message?.id ?? 'Clearing'}",
    );
    emit(
      state.copyWith(
        replyingToMessage: () => event.message,
        errorMessage: () => null,
      ),
    );
    print(
      "ChatBloc: State emitted with replyingToMessage: ${state.replyingToMessage?.id ?? 'null'}. Highlighted state remains: ${state.highlightedMessage?.id ?? 'null'}.",
    );
    print(
      "ChatBloc: State messages count after emit: ${state.messages.length}",
    ); // Verify state after emit
  }

  Future<void> _onLeaveChatRoomEvent(
    LeaveChatRoomEvent event,
    Emitter<ChatState> emit,
  ) async {
    print(
      "ChatBloc: Handling LeaveChatRoomEvent for chatRoom ${event.chatRoomId}",
    );
    _socketService.socket.emit('leaveChat', event.chatRoomId);
    // Optionally reset the state if needed when leaving a room
    // emit(const ChatState()); // Uncomment if you want to clear state on leaving
    emit(state.copyWith(errorMessage: () => null));
    print(
      "ChatBloc: State emitted after LeaveChatRoomEvent. Messages count: ${state.messages.length}",
    ); // Verify state after emit
  }

  Future<void> _onGetChatRoomDetail(
    GetChatRoomDetail event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(postApiStatus: PostApiStatus.loading));

    final result = await getChatroomdetailsUsecase.call(
      chatRoomId: event.chatRoomId,
    );

    result.fold(
      (success) {
        emit(
          state.copyWith(
            postApiStatus: PostApiStatus.success,
            chatRoomDetails: () => success.data,
          ),
        );
      },
      (error) {
        emit(
          state.copyWith(
            postApiStatus: PostApiStatus.error,
            highlightedMessage: () => null,
            replyingToMessage: () => null,
            errorMessage: () => error.message,
          ),
        );
      },
    );
  }

  FutureOr<void> _onRemoveUserFromChatGroup(
    RemoveUserEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(postApiStatus: PostApiStatus.loading));

    final result = await removeUserFromChatUsecase.call(
      chatRoomId: event.chatRoomId,
      memberId: event.memberId,
    );

    result.fold(
      (success) {
        emit(state.copyWith(postApiStatus: PostApiStatus.success));
        add(GetChatRoomDetail(chatRoomId: int.parse(event.chatRoomId)));
      },
      (error) {
        emit(state.copyWith(postApiStatus: PostApiStatus.error));
      },
    );
  }
}
