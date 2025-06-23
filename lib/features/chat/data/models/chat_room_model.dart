// lib/features/chat/data/models/chat_room_model.dart

import '../../domain/entitiy/chat_room_entity.dart';
import 'chat_room_user_model.dart';
import 'message_model.dart';
class ChatRoomModel extends ChatRoomEntity {
  const ChatRoomModel({
    required super.id,
    super.name,
    super.description,
    super.state,
    super.city,
    required super.isGroup,
    required super.createdAt,
    required super.updatedAt,
    required super.isInviteOnly,
    super.image,
    required super.isPublic,
    required super.users,
    required super.messages,
    required super.unreadMessages,
    required super.memberCount,
    required super.isMember, // This flag indicates if the user is a member
    required super.isRequestedByCurrentUser, // This flag indicates if a request is pending
  });

  // --- copyWith Method ---
  // This method is essential for BLoC/state management to update specific fields immutably.
  @override // Make sure to use @override if ChatRoomEntity defines copyWith
  ChatRoomModel copyWith({
    int? id,
    String? name,
    String? description,
    String? state,
    String? city,
    bool? isGroup,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isInviteOnly,
    String? image,
    bool? isPublic,
    List<ChatRoomUserModel>? users,
    List<MessageModel>? messages,
    int? unreadMessages,
    int? memberCount,
    bool? isMember,
    bool? isRequestedByCurrentUser,
  }) {
    return ChatRoomModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      state: state ?? this.state,
      city: city ?? this.city,
      isGroup: isGroup ?? this.isGroup,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isInviteOnly: isInviteOnly ?? this.isInviteOnly,
      image: image ?? this.image,
      isPublic: isPublic ?? this.isPublic,
      users: users ?? this.users,
      messages: messages ?? this.messages,
      unreadMessages: unreadMessages ?? this.unreadMessages,
      memberCount: memberCount ?? this.memberCount,
      isMember: isMember ?? this.isMember,
      isRequestedByCurrentUser: isRequestedByCurrentUser ?? this.isRequestedByCurrentUser,
    );
  }
  // --- END copyWith Method ---

  // --- fromJson Factory Constructor ---
  // This correctly parses the JSON into your ChatRoomModel.
  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic>? usersJson = json['users'];
    final List<ChatRoomUserModel> usersList =
    usersJson != null && usersJson is List
        ? usersJson.map((userJson) => ChatRoomUserModel.fromJson(userJson)).toList()
        : [];

    final List<dynamic>? messagesJson = json['messages'];
    final List<MessageModel> messagesList =
    messagesJson != null && messagesJson is List
        ? messagesJson.map((messageJson) => MessageModel.fromJson(messageJson)).toList()
        : [];

    return ChatRoomModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      state: json['state'],
      city: json['city'],
      isGroup: json['isGroup'] ?? false,
      isInviteOnly: json['isInviteOnly'] ?? false,
      image: json['image'] ?? "https://images.pexels.com/photos/2549941/pexels-photo-2549941.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2", // Ensure this default is correct or from kDefaultGroupImage
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isPublic: json['isPublic'] ?? false,
      users: usersList,
      messages: messagesList,
      unreadMessages: json['unreadMessages'] ?? 0,
      memberCount: json['memberCount'] ?? 0,
      isMember: json['isMember'] ?? false, // Parsed directly from backend
      isRequestedByCurrentUser: json['isRequestedByCurrentUser'] ?? false, // Parsed directly from backend
    );
  }
}