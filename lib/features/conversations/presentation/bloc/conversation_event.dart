part of 'conversation_bloc.dart';

abstract class ConversationEvent extends Equatable {
  const ConversationEvent();

  @override
  List<Object> get props => [];
}

class FetchAllConversationsEvent extends ConversationEvent {}

class SearchConversationsEvent extends ConversationEvent {
  final String query;

  const SearchConversationsEvent({required this.query});

  @override
  List<Object> get props => [query];
}

class FetchMoreConversationsEvent extends ConversationEvent {}

class ResetConversationsEvent extends ConversationEvent {}

class JoinNewChatGroupEvent extends ConversationEvent {
  final String chatRoomId;
  final String userId;

  const JoinNewChatGroupEvent({required this.chatRoomId, required this.userId});

  @override
  List<Object> get props => [chatRoomId, userId];
}

class ConversationUpdatedEvent extends ConversationEvent {} // Add this event

class FetchAllChatRooms extends ConversationEvent {
  final int page;
  final int pageSize;

  FetchAllChatRooms({required this.page, required this.pageSize});

  @override
  // TODO: implement props
  List<Object> get props => [page, pageSize];
}
