part of 'chat_bloc.dart';

class ChatState extends Equatable {
  final List<MessageModel> messages;
  final PostApiStatus postApiStatus;
  final bool loadingOlderMessages;
  final bool hasMoreMessages;
  final int? lastMessageId; // Cursor for pagination
  final MessageModel? receivedMessage; // Latest received message (for listener)

  // --- Properties for UI Modes ---
  final MessageModel? highlightedMessage; // The message currently highlighted
  final MessageModel?
  replyingToMessage; // The message currently being replied to
  // -------------------------------

  // --- Field to hold Chat Room details ---
  final ChatRoomModel?
  chatRoomDetails; // The details of the currently viewed chat room
  // ---------------------------------------------

  // --- ADDED: Field to hold the latest error message ---
  final String? errorMessage;
  // ----------------------------------------------------

  const ChatState({
    this.messages = const [],
    this.postApiStatus = PostApiStatus.initial,
    this.loadingOlderMessages = false,
    this.hasMoreMessages = true, // Assume true initially until first load
    this.lastMessageId,
    this.receivedMessage,
    // --- Initial values for UI Modes ---
    this.highlightedMessage,
    this.replyingToMessage,
    // -----------------------------------
    // --- Initial value for chatRoomDetails ---
    this.chatRoomDetails,
    // --------------------------------------------
    // --- ADDED: Initial value for errorMessage ---
    this.errorMessage,
    // -------------------------------------------\
  });

  // copyWith method allows creating a new state by copying existing values
  // and optionally overriding some with new values.
  // Using Function() for nullable fields allows explicitly setting them to null.
  ChatState copyWith({
    List<MessageModel>? messages,
    PostApiStatus? postApiStatus,
    bool? loadingOlderMessages,
    bool? hasMoreMessages,
    int? lastMessageId, // Nullable int doesn't need Function()
    MessageModel?
    receivedMessage, // Nullable MessageModel doesn't need Function()
    // --- copyWith for UI Mode properties (nullable) ---
    Function()? highlightedMessage, // Use Function() to allow setting to null
    Function()? replyingToMessage, // Use Function() to allow setting to null
    // ---------------------------------------------------
    // --- copyWith for chatRoomDetails (nullable) ---
    Function()? chatRoomDetails, // Use Function() to allow setting to null
    // -----------------------------------------------
    // --- ADDED: copyWith for errorMessage (nullable) ---
    Function()? errorMessage, // Use Function() to allow setting to null
    // -------------------------------------------------
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      postApiStatus: postApiStatus ?? this.postApiStatus,
      loadingOlderMessages: loadingOlderMessages ?? this.loadingOlderMessages,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      receivedMessage: receivedMessage ?? this.receivedMessage,

      // --- Assignment logic using the Function() pattern ---
      // If the function parameter was provided (not null), call the function to get the value.
      // If the function parameter was NOT provided (is null), keep the current state's value.
      highlightedMessage:
          highlightedMessage != null
              ? highlightedMessage()
              : this.highlightedMessage,
      replyingToMessage:
          replyingToMessage != null
              ? replyingToMessage()
              : this.replyingToMessage,
      // -----------------------------------------------------
      // --- Assignment logic for chatRoomDetails ---
      chatRoomDetails:
          chatRoomDetails != null ? chatRoomDetails() : this.chatRoomDetails,
      // --------------------------------------------
      // --- ADDED: Assignment logic for errorMessage ---
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      // -----------------------------------------------\
    );
  }

  @override
  List<Object?> get props => [
    messages,
    postApiStatus,
    loadingOlderMessages,
    hasMoreMessages,
    lastMessageId,
    receivedMessage,
    // --- Include UI Mode properties in props ---
    highlightedMessage, // This is critical for Equatable to detect changes to null or different message
    replyingToMessage, // This is critical for Equatable to detect changes to null or different message
    // -------------------------------------------
    // --- Include chatRoomDetails in props ---
    chatRoomDetails, // This is critical for Equatable to detect changes
    // ----------------------------------------
    // --- ADDED: Include errorMessage in props ---
    errorMessage,
    // -------------------------------------------\
  ];

  @override
  bool get stringify => true; // Optional: For better debug output
}
