import 'package:bikerr/features/auth/data/models/user_model.dart';
import 'package:bikerr/features/chat/data/models/message_model.dart';
import 'package:bikerr/features/conversations/domain/entities/conversation_entity.dart';


class ConversationModel extends ConversationEntity {
  ConversationModel({
    required super.id,
    required super.name,
    required super.isGroup,
    required super.createdAt,
    required super.updatedAt,
    required super.isInviteOnly,
    required List<ConversationUserModel>? users, // <-- CHANGED to ConversationUserModel
    required super.messages, // Assuming messages still uses MessageModel directly
    required super.unreadCount,
  }) : super(users: users); // Pass the users to the super constructor

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    var usersList = <ConversationUserModel>[];
    if (json['users'] != null) {
      usersList = (json['users'] as List)
          .map((userJson) => ConversationUserModel.fromJson(userJson as Map<String, dynamic>))
          .toList();
    }

    var messagesList = <MessageModel>[];
    if (json['messages'] != null) {
      messagesList = (json['messages'] as List)
          .map((msgJson) => MessageModel.fromJson(msgJson as Map<String, dynamic>))
          .toList();
    }

    return ConversationModel(
      id: json['id'] as int,
      name: json['name'] as String,
      isGroup: json['isGroup'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isInviteOnly: json['isInviteOnly'] as bool,
      users: usersList.isNotEmpty ? usersList : null, // Handle if users can be null
      messages: messagesList, // Assuming messages is not nullable in entity
      unreadCount: json['unreadCount'] as int,
    );
  }

}

class ConversationUserModel extends ConversationUser {
  ConversationUserModel({
    super.id, // No longer 'required' if nullable and super allows it
    super.name, // No longer 'required' if nullable and super allows it
    super.profileImageKey,
  });

  factory ConversationUserModel.fromJson(Map<String, dynamic> json) {
    return ConversationUserModel(
      id: json['id'] as int?, // Allow null
      name: json['name'] as String?, // Allow null
      profileImageKey: json['profileImageKey'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'profileImageKey': profileImageKey,
    };
    // Consider how to handle nulls in toJson, e.g., omitting them:
    // final map = <String, dynamic>{};
    // if (id != null) map['id'] = id;
    // if (name != null) map['name'] = name;
    // if (profileImageKey != null) map['profileImageKey'] = profileImageKey;
    // return map;
  }
}