part of 'conversation_bloc.dart';

class ConversationState extends Equatable {
  final PostApiStatus postApiStatus;
  final List<ConversationEntity> conversations;
  final List<ConversationEntity> filteredConversations;
  final List<ChatRoomModel> chatRooms; // Changed from dynamic to ChatRoomModel
  final String? errorMessage;
  final bool hasReachedMax;
  final PostApiStatus fetchMoreStatus;
  final PostApiStatus socketUpdateStatus;
  final String? joiningChatRoomId; // <-- Add this new property

  const ConversationState({
    this.chatRooms = const [],
    this.postApiStatus = PostApiStatus.initial,
    this.conversations = const [],
    this.filteredConversations = const [],
    this.errorMessage,
    this.hasReachedMax = false,
    this.fetchMoreStatus = PostApiStatus.initial,
    this.socketUpdateStatus = PostApiStatus.initial,
    this.joiningChatRoomId, // <-- Initialize it here (nullable)
  });

  ConversationState copyWith({
    List<ChatRoomModel>? chatRooms, // Changed type in copyWith as well
    PostApiStatus? postApiStatus,
    List<ConversationEntity>? conversations,
    List<ConversationEntity>? filteredConversations,
    String? errorMessage,
    bool? hasReachedMax,
    PostApiStatus? fetchMoreStatus,
    PostApiStatus? socketUpdateStatus,
    String? joiningChatRoomId, // <-- Add to copyWith
  }) {
    return ConversationState(
      chatRooms: chatRooms ?? this.chatRooms,
      postApiStatus: postApiStatus ?? this.postApiStatus,
      conversations: conversations ?? this.conversations,
      filteredConversations:
      filteredConversations ?? this.filteredConversations,
      errorMessage: errorMessage ?? this.errorMessage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      fetchMoreStatus: fetchMoreStatus ?? this.fetchMoreStatus,
      socketUpdateStatus: socketUpdateStatus ?? this.socketUpdateStatus,
      joiningChatRoomId: joiningChatRoomId, // <-- Assign in copyWith (allows setting to null)
    );
  }

  @override
  List<Object?> get props => [
    chatRooms,
    postApiStatus,
    conversations,
    filteredConversations,
    errorMessage,
    hasReachedMax,
    fetchMoreStatus,
    socketUpdateStatus,
    joiningChatRoomId, // <-- Add to props
  ];
}
