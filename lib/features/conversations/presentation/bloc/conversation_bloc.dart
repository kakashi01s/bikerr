import 'dart:async';
import 'package:bikerr/features/chat/data/models/chat_room_model.dart';
import 'package:bikerr/features/conversations/domain/entities/conversation_entity.dart';
import 'package:bikerr/features/conversations/data/model/conversation_model.dart';
import 'package:bikerr/features/conversations/domain/usecases/fetch_all_user_conversation_usecase.dart';
import 'package:bikerr/features/conversations/domain/usecases/get_all_chat_rooms_usecase.dart';
import 'package:bikerr/features/conversations/domain/usecases/join_new_chat_group_use_case.dart';
import 'package:bikerr/services/session/session_manager.dart';
import 'package:bikerr/utils/apiResult/api_error.dart';
import 'package:bikerr/utils/enums/enums.dart';
import 'package:bikerr/utils/socket/socket_service.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:dartz/dartz.dart';

part 'conversation_event.dart';
part 'conversation_state.dart';

class ConversationBloc extends Bloc<ConversationEvent, ConversationState> {
  final GetAllChatRoomsUsecase getAllChatRoomsUsecase;
  final FetchAllUserConversationUseCase fetchAllUserConversationUsecase;
  final JoinNewChatGroupUseCase joinNewChatGroupUseCase;
  final SocketService _socketService = SocketService();
  final SessionManager session = SessionManager.instance;

  int _page = 1;
  final int _limit = 10;
  bool _isFetching = false;

  ConversationBloc({
    required this.fetchAllUserConversationUsecase,
    required this.getAllChatRoomsUsecase,
    required this.joinNewChatGroupUseCase,
  }) : super(const ConversationState()) {
    on<FetchAllConversationsEvent>(_onFetchAllUserConversations);
    on<FetchMoreConversationsEvent>(_onFetchMoreConversations);
    on<SearchConversationsEvent>(_onSearchConversations);
    on<ResetConversationsEvent>(_onResetConversations);
    on<ConversationUpdatedEvent>(_onConversationUpdatedEvent);
    on<FetchAllChatRooms>(_onFetchAllChatRooms);
    on<JoinNewChatGroupEvent>(_onJoinNewChatGroup);

    // Listen for socket updates
    _initializeSocketListeners();
  }

  void _initializeSocketListeners() {
    try {
      _socketService.socket.on(
        'conversationUpdated',
        _onConversationUpdatedSocketEvent,
      );
    } catch (e) {
      print('Error Initializing Socket Listeners: $e');
    }
  }

  void _onConversationUpdatedSocketEvent(dynamic data) {
    // Only add event if the bloc is not closed
    if (!isClosed) {
      add(ConversationUpdatedEvent());
    }
  }

  Future<void> _onFetchAllUserConversations(FetchAllConversationsEvent event,
      Emitter<ConversationState> emit,) async {
    if (_isFetching || state.postApiStatus == PostApiStatus.loading) return;

    _isFetching = true;
    emit(
      state.copyWith(
        postApiStatus: PostApiStatus.loading,
        socketUpdateStatus: PostApiStatus.initial,
        hasReachedMax: false,
      ),
    );

    _page = 1;
    final result = await fetchAllUserConversationUsecase.call(
      page: _page,
      limit: _limit,
    );

    result.fold(
          (response) {
        final data = response.data?['data'];
        if (data is Map<String, dynamic> && data.containsKey('data')) {
          final conversationList = data['data'];
          final paginationData = data['pagination'];

          final totalItems =
          paginationData is Map<String, dynamic>
              ? (paginationData['totalItems'] as int? ?? 0)
              : 0;

          if (conversationList is List) {
            final conversations =
            conversationList
                .map(
                  (e) =>
                  ConversationModel.fromJson(e as Map<String, dynamic>),
            )
                .toList()
              ..sort((a, b) {
                // Sort by the last message timestamp
                final dateA =
                a.messages.isNotEmpty
                    ? DateTime.tryParse(
                  '${a.messages.last.createdAt}',
                ) ??
                    DateTime(0)
                    : DateTime.tryParse('${a.updatedAt}') ??
                    DateTime(0);
                final dateB =
                b.messages.isNotEmpty
                    ? DateTime.tryParse(
                  '${b.messages.last.createdAt}',
                ) ??
                    DateTime(0)
                    : DateTime.tryParse('${b.updatedAt}') ??
                    DateTime(0);
                return dateB.compareTo(dateA);
              });

            final isLastPage =
                conversations.length < _limit ||
                    conversations.length == totalItems;

            emit(
              state.copyWith(
                postApiStatus: PostApiStatus.success,
                conversations: conversations,
                filteredConversations: List.from(conversations),
                hasReachedMax: isLastPage,
                socketUpdateStatus: PostApiStatus.success,
              ),
            );
          } else {
            emit(
              state.copyWith(
                postApiStatus: PostApiStatus.error,
                errorMessage: 'Unexpected format in data list.',
                socketUpdateStatus: PostApiStatus.error,
              ),
            );
          }
        } else {
          emit(
            state.copyWith(
              postApiStatus: PostApiStatus.error,
              errorMessage: 'Unexpected API structure.',
              socketUpdateStatus: PostApiStatus.error,
            ),
          );
        }
      },
          (error) {
        emit(
          state.copyWith(
            postApiStatus: PostApiStatus.error,
            errorMessage: error.message,
            socketUpdateStatus: PostApiStatus.error,
          ),
        );
      },
    );

    _isFetching = false;
  }

  Future<void> _onFetchMoreConversations(FetchMoreConversationsEvent event,
      Emitter<ConversationState> emit,) async {
    if (state.hasReachedMax ||
        state.fetchMoreStatus == PostApiStatus.loading ||
        _isFetching)
      return;

    _isFetching = true;
    emit(state.copyWith(fetchMoreStatus: PostApiStatus.loading));
    _page++;

    final result = await fetchAllUserConversationUsecase.call(
      page: _page,
      limit: _limit,
    );

    result.fold(
          (response) {
        final data = response.data?['data'];
        if (data is Map<String, dynamic> && data.containsKey('data')) {
          final conversationList = data['data'];
          final paginationData = data['pagination'];

          final totalItems =
          paginationData is Map<String, dynamic>
              ? (paginationData['totalItems'] as int? ?? 0)
              : 0;

          if (conversationList is List) {
            final newConversations =
            conversationList
                .map(
                  (e) =>
                  ConversationModel.fromJson(e as Map<String, dynamic>),
            )
                .toList();

            final updatedList =
            [...state.conversations, ...newConversations]
                .fold<Map<String, ConversationEntity>>(
              {},
                  (map, convo) => map..[convo.id.toString()] = convo,
            )
                .values
                .toList()
              ..sort((a, b) {
                // Sort by the last message timestamp
                final dateA =
                a.messages.isNotEmpty
                    ? DateTime.tryParse(
                  '${a.messages.last.createdAt}',
                ) ??
                    DateTime(0)
                    : DateTime.tryParse('${a.updatedAt}') ??
                    DateTime(0);
                final dateB =
                b.messages.isNotEmpty
                    ? DateTime.tryParse(
                  '${b.messages.last.createdAt}',
                ) ??
                    DateTime(0)
                    : DateTime.tryParse('${b.updatedAt}') ??
                    DateTime(0);
                return dateB.compareTo(dateA);
              });

            final isLastPage = updatedList.length >= totalItems;

            emit(
              state.copyWith(
                conversations: updatedList,
                filteredConversations: List.from(updatedList),
                hasReachedMax: isLastPage,
                fetchMoreStatus: PostApiStatus.success,
              ),
            );
          } else {
            emit(
              state.copyWith(
                fetchMoreStatus: PostApiStatus.error,
                errorMessage: 'Unexpected format in fetched data.',
              ),
            );
          }
        } else {
          emit(
            state.copyWith(
              fetchMoreStatus: PostApiStatus.error,
              errorMessage: 'Unexpected API structure.',
            ),
          );
        }
      },
          (error) {
        emit(
          state.copyWith(
            fetchMoreStatus: PostApiStatus.error,
            errorMessage: error.message,
          ),
        );
      },
    );

    _isFetching = false;
  }

  void _onSearchConversations(SearchConversationsEvent event,
      Emitter<ConversationState> emit,) {
    final query = event.query.toLowerCase();
    final filtered =
    state.conversations.where((convo) {
      final nameMatch =
          convo.name?.toLowerCase().contains(query) ?? false;
      final userMatch =
          convo.users?.any(
                (user) => user.name?.toLowerCase().contains(query) ?? false,
          ) ??
              false;
      return nameMatch || userMatch;
    }).toList()
      ..sort((a, b) {
        // Sort by the last message timestamp
        final dateA =
        a.messages.isNotEmpty
            ? DateTime.tryParse('${a.messages.last.createdAt}') ??
            DateTime(0)
            : DateTime.tryParse('${a.updatedAt}') ?? DateTime(0);
        final dateB =
        b.messages.isNotEmpty
            ? DateTime.tryParse('${b.messages.last.createdAt}') ??
            DateTime(0)
            : DateTime.tryParse('${b.updatedAt}') ?? DateTime(0);
        return dateB.compareTo(dateA);
      });

    emit(state.copyWith(filteredConversations: filtered, hasReachedMax: true));
  }

  void _onResetConversations(ResetConversationsEvent event,
      Emitter<ConversationState> emit,) {
    //emit(const ConversationState());
    add(FetchAllConversationsEvent());
  }

  void _onConversationUpdatedEvent(ConversationUpdatedEvent event,
      Emitter<ConversationState> emit,) {
    emit(state.copyWith(socketUpdateStatus: PostApiStatus.loading));
    add(FetchAllConversationsEvent());
  }

  Future<void> _onFetchAllChatRooms(
      FetchAllChatRooms event,
      Emitter<ConversationState> emit,
      ) async {
    print('[Bloc Log] _onFetchAllChatRooms event received: page=${event.page}, limit=${event.pageSize}');

    // Prevent duplicate fetches if one is already in progress
    if (_isFetching || state.postApiStatus == PostApiStatus.loading) {
      print('[Bloc Log] _onFetchAllChatRooms: Fetch skipped (isFetching: $_isFetching, status: ${state.postApiStatus})');
      return;
    }

    _isFetching = true; // Set fetching flag
    print('[Bloc Log] _onFetchAllChatRooms: Starting fetch, setting _isFetching to true.');

    // Emit loading state
    emit(
      state.copyWith(
        postApiStatus: PostApiStatus.loading,
        socketUpdateStatus: PostApiStatus.initial,
        hasReachedMax: false, // Reset for new fetch
      ),
    );

    // WARNING: This handler always fetches page 1. For true pagination
    // (loading next pages), you'd typically increment _page here
    // or pass `event.page` directly if the event holds the next page number.
    // Sticking to your current logic for this fix:
    _page = 1;
    print('[Bloc Log] _onFetchAllChatRooms: Calling usecase with page=$_page, limit=${_limit}');

    // 2. Call the Usecase
    final result = await getAllChatRoomsUsecase.call(
      page: _page,
      limit: _limit,
    );

    print('[Bloc Log] _onFetchAllChatRooms: Usecase call finished. Handling result... ${result}');

    // 3. Handle the result using fold (Either pattern)
    result.fold(
      // --- Success Case ---
          (response) {
        print('[Bloc Log] _onFetchAllChatRooms: Usecase returned success. ${response}');

        // 'response.data' is the full top-level response map (e.g., {statusCode: 200, data: {...}, message: "..."})
        final Map<String, dynamic>? fullResponseMap = response.data;

        print('[Bloc Log] _onFetchAllChatRooms: Accessed fullResponseMap. Type: ${fullResponseMap.runtimeType}');

        // Now, extract the actual 'data' payload from within the full response map
        final Map<String, dynamic>? innerDataPayload = fullResponseMap?['data'];

        print('[Bloc Log] _onFetchAllChatRooms: Accessed innerDataPayload. Type: ${innerDataPayload.runtimeType}');


        // Check if the inner data payload is a valid Map and contains the expected keys
        if (innerDataPayload is Map<String, dynamic> &&
            innerDataPayload.containsKey('chatRooms') &&
            innerDataPayload.containsKey('pagination')) {

          final conversationListJson = innerDataPayload['chatRooms']; // List of raw chat room maps
          final paginationData = innerDataPayload['pagination'];     // Pagination info map

          print('[Bloc Log] _onFetchAllChatRooms: Data structure seems correct. List type: ${conversationListJson.runtimeType}, Pagination type: ${paginationData.runtimeType}');

          // Safely parse totalRooms (from backend) and handle potential null
          final totalRooms = paginationData is Map<String, dynamic>
              ? (paginationData['totalRooms'] as int? ?? 0)
              : 0;
          print('[Bloc Log] _onFetchAllChatRooms: Parsed totalRooms: $totalRooms');

          // Ensure conversationListJson is actually a List before mapping
          if (conversationListJson is List) {
            print('[Bloc Log] _onFetchAllChatRooms: Received list is valid. Length: ${conversationListJson.length}');

            // Map JSON items to ChatRoomModel, filtering out any parsing errors
            final conversations = conversationListJson.map((e) {
              if (e == null || e is! Map<String, dynamic>) {
                print('[Bloc Log] Skipping invalid item in conversationList. Item: $e');
                return null;
              }
              try {
                // Ensure ChatRoomModel and ChatRoomEntity have 'isPublic' defined
                // Ensure other fields like 'memberCount', 'isMember' are handled
                // Ensure 'messages' list is correctly handled (e.g., nullable if not always present)
                return ChatRoomModel.fromJson(e);
              } catch (parseError, st) {
                print('[Bloc Log] Error parsing item to ChatRoomModel: $parseError\nItem Data: $e\n$st');
                return null;
              }
            }).whereType<ChatRoomModel>().toList(); // Filter out nulls from failed parses

            print('[Bloc Log] _onFetchAllChatRooms: Finished mapping ${conversations.length} items to ChatRoomModel.');

            // Sort the mapped list by last message/updated date
            print('[Bloc Log] _onFetchAllChatRooms: Starting sort by last message/updated date.');
            conversations.sort((a, b) {
              // Be cautious here: your backend `formattedChatRooms` doesn't include 'messages'.
              // If `a.messages` or `b.messages` is empty, or if your ChatRoomModel.fromJson
              // sets an empty list for messages because the backend doesn't send it,
              // then `a.messages.last` will throw an error.
              // Consider sorting purely by `updatedAt` if `messages` aren't reliable here.
              final dateA = a.messages.isNotEmpty
                  ? DateTime.tryParse('${a.messages.last.createdAt}') ?? DateTime(0)
                  : DateTime.tryParse('${a.updatedAt}') ?? DateTime(0);

              final dateB = b.messages.isNotEmpty
                  ? DateTime.tryParse('${b.messages.last.createdAt}') ?? DateTime(0)
                  : DateTime.tryParse('${b.updatedAt}') ?? DateTime(0);
              return dateB.compareTo(dateA); // Sort descending (newest first)
            });
            print('[Bloc Log] _onFetchAllChatRooms: Finished sorting ${conversations.length} items.');


            // Calculate if this is the last page
            final isLastPage = conversations.length < _limit || conversations.length == totalRooms;
            print('[Bloc Log] _onFetchAllChatRooms: Calculated isLastPage: $isLastPage (Fetched: ${conversations.length}, Limit: ${_limit}, Total Items: $totalRooms)');

            // Emit the success state
            emit(
              state.copyWith(
                postApiStatus: PostApiStatus.success,
                chatRooms: conversations,
                hasReachedMax: isLastPage,
                socketUpdateStatus: PostApiStatus.success,
                errorMessage: null, // Clear any previous error
              ),
            );
            print('[Bloc Log] _onFetchAllChatRooms: Success state emitted.');
          } else {
            // Error if 'chatRooms' key does not contain a List
            print('[Bloc Log] _onFetchAllChatRooms: Error: Received "chatRooms" is not a List. Type: ${conversationListJson.runtimeType}');
            emit(
              state.copyWith(
                postApiStatus: PostApiStatus.error,
                errorMessage: 'Unexpected format: chatRooms data is not a list.',
                socketUpdateStatus: PostApiStatus.error,
                hasReachedMax: state.hasReachedMax,
              ),
            );
          }
        } else {
          // Error if the inner data payload doesn't have expected keys
          print('[Bloc Log] _onFetchAllChatRooms: Error: Unexpected API payload structure. Expected "chatRooms" and "pagination" keys inside "data". Payload: $fullResponseMap');
          emit(
            state.copyWith(
              postApiStatus: PostApiStatus.error,
              errorMessage: 'Unexpected API structure: missing chatRooms or pagination.',
              socketUpdateStatus: PostApiStatus.error,
              hasReachedMax: state.hasReachedMax,
            ),
          );
        }
      },
      // --- Error Case ---
          (error) {
        print('[Bloc Log] _onFetchAllChatRooms: Usecase returned error (ApiError).');
        print('[Bloc Log] API Error Message: ${error.message}');
        emit(
          state.copyWith(
            postApiStatus: PostApiStatus.error,
            errorMessage: error.message,
            socketUpdateStatus: PostApiStatus.error,
            hasReachedMax: state.hasReachedMax,
          ),
        );
        print('[Bloc Log] _onFetchAllChatRooms: Error state emitted.');
      },
    );

    _isFetching = false; // Reset fetching flag
    print('[Bloc Log] _onFetchAllChatRooms: Fetch process finished, _isFetching set to false.');
  }



  FutureOr<void> _onJoinNewChatGroup(
      JoinNewChatGroupEvent event,
      Emitter<ConversationState> emit,
      ) async {
    print('[Bloc Log] _onJoinNewChatGroup event received for chatRoomId: ${event.chatRoomId}, userId: ${event.userId}');

    emit(state.copyWith(
      postApiStatus: PostApiStatus.loading,
      socketUpdateStatus: PostApiStatus.loading,
      errorMessage: null,
      joiningChatRoomId: event.chatRoomId, // Still set loading for this specific item
    ));

    final result = await joinNewChatGroupUseCase.call(
      chatRoomId: event.chatRoomId,
      userId: event.userId,
    );

    result.fold(
          (response) {
        print('[Bloc Log] _onJoinNewChatGroup: Join successful. Response: $response');

        final updatedChatRooms = state.chatRooms.map((room) {
          if (room.id.toString() == event.chatRoomId) {
            return room.copyWith(
              isMember: true, // User is now a member
              isRequestedByCurrentUser: false, // Request is fulfilled
              memberCount: (room.memberCount ?? 0) + 1, // Increment member count
            );
          }
          return room;
        }).toList();

        emit(state.copyWith(
          postApiStatus: PostApiStatus.success,
          socketUpdateStatus: PostApiStatus.success,
          errorMessage: null,
          chatRooms: updatedChatRooms,
          joiningChatRoomId: null, // Clear loading
        ));
        print('[Bloc Log] _onJoinNewChatGroup: Success state emitted.');
      },
          (error) {
        print('[Bloc Log] _onJoinNewChatGroup: Join failed. Error: ${error.message}');

        List<ChatRoomModel> updatedChatRooms = List.from(state.chatRooms); // Create a mutable copy

        // --- NEW LOGIC TO HANDLE 409 CONFLICT ---
        // You need to know how your NetworkServicesApi packages errors.
        // If it returns a custom exception with a statusCode property:
        // if (error is NetworkError && error.statusCode == 409 && error.message?.contains("Join request already sent") == true) {
        // If error.message is the full JSON string and you need to parse it:
        if (error.message != null && error.message!.contains('"statusCode":409') && error.message!.contains('"message":"Join request already sent"')) {
          // Find the chat room and update its 'isRequestedByCurrentUser' status
          updatedChatRooms = updatedChatRooms.map((room) {
            if (room.id.toString() == event.chatRoomId) {
              return room.copyWith(isRequestedByCurrentUser: true);
            }
            return room;
          }).toList();
          // Emit a success for the UI change, but acknowledge the error via snackbar
          emit(state.copyWith(
            postApiStatus: PostApiStatus.success, // UI updated for "Requested"
            socketUpdateStatus: PostApiStatus.error, // Still an error from API perspective
            errorMessage: "You have already sent a join request to this group.", // User-friendly message
            joiningChatRoomId: null, // Clear loading
            chatRooms: updatedChatRooms, // Update chatRooms with the new status
          ));
        } else {
          // Handle other errors (e.g., 400, 500, network offline)
          emit(state.copyWith(
            postApiStatus: PostApiStatus.error,
            socketUpdateStatus: PostApiStatus.error,
            errorMessage: error.message, // Use the original error message
            joiningChatRoomId: null, // Clear loading
            chatRooms: updatedChatRooms, // No change to chatRooms for other errors
          ));
        }
        // --- END NEW LOGIC ---

        print('[Bloc Log] _onJoinNewChatGroup: Error state emitted.');
      },
    );
  }

}
