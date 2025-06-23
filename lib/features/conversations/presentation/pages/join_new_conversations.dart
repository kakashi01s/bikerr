import 'package:bikerr/features/conversations/presentation/bloc/conversation_bloc.dart';
import 'package:bikerr/features/conversations/presentation/widgets/chat_room_list_item.dart';
import 'package:bikerr/utils/enums/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../services/session/session_manager.dart'; // Import your SessionManager

class JoinNewConversations extends StatefulWidget {
  const JoinNewConversations({super.key});

  @override
  State<JoinNewConversations> createState() => _JoinNewConversationsState();
}

class _JoinNewConversationsState extends State<JoinNewConversations> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  int _currentPage = 1;
  final int _limit = 10;

  @override
  void initState() {
    super.initState();
    // It's crucial that SessionManager.instance.getSession() is called
    // somewhere before this widget initializes, e.g., in your main.dart
    // or an authentication flow, to ensure userId is already loaded.
    _fetchChatRooms();

    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _fetchChatRooms() {
    final state = BlocProvider.of<ConversationBloc>(context).state;
    if (state.postApiStatus == PostApiStatus.loading || state.hasReachedMax) {
      print('[UI Log] Fetch skipped: Loading or Reached Max.');
      return;
    }
    print('[UI Log] Dispatching FetchAllChatRooms for page: $_currentPage');
    BlocProvider.of<ConversationBloc>(context).add(
      FetchAllChatRooms(
        page: _currentPage,
        pageSize: _limit,
      ),
    );
    _currentPage++;
  }

  void _onScroll() {
    final state = BlocProvider.of<ConversationBloc>(context).state;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9 &&
        state.postApiStatus != PostApiStatus.loading &&
        !state.hasReachedMax) {
      print('[UI Log] Scroll threshold reached, attempting to fetch more chat rooms.');
      _fetchChatRooms();
    }
  }

  void _onSearchChanged() {
    if (_searchController.text.length > 2 || _searchController.text.isEmpty) {
      _currentPage = 1;
      print('[UI Log] Search term changed to: "${_searchController.text}", refetching page 1.');
      BlocProvider.of<ConversationBloc>(context).add(
        FetchAllChatRooms(
          page: _currentPage,
          pageSize: _limit,
        ),
      );
      _currentPage++;
    }
  }

  // --- UPDATED METHOD TO GET CURRENT USER ID ---
  String? _getCurrentUserId() {
    return SessionManager.instance.userId;
  }

  @override
  Widget build(BuildContext context) {
    // Get the current user ID from SessionManager
    final String? currentUserId = _getCurrentUserId();

    // Optionally, if userId is critical and might be null, you might show a loading state
    // or navigate back if the user isn't authenticated yet.
    if (currentUserId == null) {
      // You could show a loading indicator, an error message, or navigate away.
      return const Scaffold(
        body: Center(child: Text('User not logged in or session not loaded.')),
      );
    }

    return BlocConsumer<ConversationBloc, ConversationState>(
      listener: (context, state) {
        if (state.postApiStatus == PostApiStatus.error && state.errorMessage != null) {
          if (state.chatRooms.isEmpty || _currentPage > 1) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
        }

      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            title: const Text('Join New'),
            centerTitle: false,
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 16.0,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: state.postApiStatus == PostApiStatus.loading && state.chatRooms.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : state.chatRooms.isEmpty
                    ? Center(
                  child: Text(
                    state.postApiStatus == PostApiStatus.error
                        ? state.errorMessage ?? 'Failed to load groups.'
                        : 'No groups found.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
                    : ListView.builder(
                  controller: _scrollController,
                  itemCount: state.chatRooms.length +
                      (state.postApiStatus == PostApiStatus.loading && !state.hasReachedMax
                          ? 1
                          : 0),
                  itemBuilder: (context, index) {
                    if (index == state.chatRooms.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final chatRoom = state.chatRooms[index];

                    final int id = chatRoom.id;
                    final String? imageUrl = chatRoom.image;
                    final String name = chatRoom.name ?? 'Unnamed Group';
                    final String description = chatRoom.description ?? 'No description';
                    final int memberCount = chatRoom.memberCount;
                    final bool isMember = chatRoom.isMember;
                    final bool isRequested = chatRoom.isRequestedByCurrentUser;

                    final int? totalRides = null;
                    final String? ownerName = null;
                    final String? location = null;
                    final bool isJoiningThisRoom = (state.joiningChatRoomId == id.toString());
                    return ChatRoomListItem(
                      id: id,
                      imageUrl: imageUrl,
                      name: name,
                      ownerName: ownerName,
                      location: location,
                      memberCount: memberCount,
                      totalRides: totalRides,
                      description: description,
                      isMember: isMember,
                      isRequested: isRequested,
                      isJoining: isJoiningThisRoom, // <-- Pass the new flag to the item
                      onJoinTap: () {
                        print('[UI Log] Tapped Join for Group ID: $id');
                        // Dispatch the JoinNewChatGroupEvent
                        context.read<ConversationBloc>().add(
                          JoinNewChatGroupEvent(
                            chatRoomId: id.toString(),
                            userId: currentUserId, // Use the actual current user ID
                          ),
                        );
                      },
                      onRequestTap: () {
                        print('[UI Log] Tapped Requested for Group ID: $id');
                        // TODO: Implement cancel request logic
                      },
                      onViewTap: () {
                        print('[UI Log] Tapped Joined for Group ID: $id');
                        // TODO: Implement navigate to room logic
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              print('FAB tapped: Create New Group');
              // TODO: Navigate to a "Create Group" screen
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}