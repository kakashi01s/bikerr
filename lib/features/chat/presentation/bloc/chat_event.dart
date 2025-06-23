part of 'chat_bloc.dart';

sealed class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => []; // Changed to Object? for potential nullable fields in subclasses
}

class GetAllMessagesEvent extends ChatEvent {
  final int chatRoomId;
  final int page;
  final int pageSize;

  const GetAllMessagesEvent({
    required this.chatRoomId,
    required this.page,
    required this.pageSize,
  });

  @override
  List<Object> get props => [chatRoomId, page, pageSize];
}

class GetOlderMessagesEvent extends ChatEvent {
  final int chatRoomId;
  final int pageSize;
  final int? cursorMessageId; // This should be nullable

  const GetOlderMessagesEvent({
    required this.chatRoomId,
    required this.pageSize,
    this.cursorMessageId, // Make optional
  });

  @override
  List<Object?> get props => [chatRoomId, pageSize, cursorMessageId]; // Use Object? for nullable cursor
}

class ReceivedMessageEvent extends ChatEvent {
  // Keeping dynamic as it comes from the socket, cast inside the bloc handler
  final dynamic message;
  final int chatRoomId; // Added chatRoomId based on previous step

  const ReceivedMessageEvent({required this.message, required this.chatRoomId});

  @override
  List<Object> get props => [message, chatRoomId];
}

class SendMessageEvent extends ChatEvent {
  final int chatRoomId;
  final String content;
  final File? imageFile;

  const SendMessageEvent({
    required this.chatRoomId,
    required this.content,
    this.imageFile, // Make imageFile optional
  });

  @override
  List<Object?> get props => [chatRoomId, content, imageFile?.path]; // Use Object? for nullable File
}

class LeaveChatRoomEvent extends ChatEvent {
  final int chatRoomId;

  const LeaveChatRoomEvent({required this.chatRoomId});

  @override
  List<Object> get props => [chatRoomId];
}

class UpdateLastReadEvent extends ChatEvent {
  final int chatRoomId;

  const UpdateLastReadEvent({required this.chatRoomId});

  @override
  List<Object> get props => [chatRoomId];
}

// --- NEW EVENTS FOR HIGHLIGHT/REPLY FLOW ---

// Event to set or clear the message highlighted by long-press
class SetHighlightedMessageEvent extends ChatEvent {
  final MessageModel? message; // The message to highlight (null to clear)

  const SetHighlightedMessageEvent({this.message});

  @override
  List<Object?> get props => [message]; // message can be null
}

// Event to transition from highlighted state to active reply input state
class EnterReplyModeEvent extends ChatEvent {
  final int
  highlightedMessageId; // The ID of the message that is currently highlighted

  const EnterReplyModeEvent({required this.highlightedMessageId});

  @override
  List<Object> get props => [highlightedMessageId];
}

// Explicit event to set or clear the *reply input* state (the preview above the text field)
// This is dispatched by the UI (ChatScreen) to control the MessageInput preview.
// While EnterReplyModeEvent sets this, this event allows for explicit clearing (e.g., a cancel button).
class SetReplyingToMessageEvent extends ChatEvent {
  final MessageModel?
  message; // The message to reply to (null to clear the preview)

  const SetReplyingToMessageEvent({this.message});

  @override
  List<Object?> get props => [message]; // message can be null
}

// Event to send a reply to an existing message
class ReplyToMessageEvent extends ChatEvent {
  final int parentMessageId; // The ID of the message being replied to
  final String content;
  // final File? imageFile; // Uncomment if replies can have attachments

  const ReplyToMessageEvent({
    required this.parentMessageId,
    required this.content,
    // this.imageFile, // Uncomment if attachments are supported
  });

  @override
  List<Object> get props => [
    parentMessageId,
    content /*, imageFile?.path ?? '' */,
  ];
}

class GetChatRoomDetail extends ChatEvent {
  final int chatRoomId;

  const GetChatRoomDetail({required this.chatRoomId});

  @override
  // TODO: implement props
  List<Object?> get props => [chatRoomId];
}

class RemoveUserEvent extends ChatEvent {
  final String chatRoomId;
  final String memberId;

  RemoveUserEvent({required this.chatRoomId, required this.memberId});

  @override
  // TODO: implement props
  List<Object?> get props => [memberId, chatRoomId];
}
