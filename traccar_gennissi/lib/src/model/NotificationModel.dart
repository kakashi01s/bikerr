
class NotificationModel extends Object {
  int? id;
  Map<String, dynamic>? attributes;
  String? description;
  int? calendarId;
  bool? always;
  String? type;
  String? notificators;

  NotificationModel({
    id,
    attributes,
    calendarId,
    always,
    type,
    notificators,
    description,
  });

  NotificationModel.fromJson(Map<String, dynamic> json) {
    id = json["id"];
    attributes = json["attributes"];
    calendarId = json["calendarId"];
    always = json["always"];
    type = json["type"];
    notificators = json["notificators"];
    description = json["description"];
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'attributes':attributes,
    'calendarId':calendarId,
    'always':always,
    'type': type,
    'notificators': notificators,
    'description':description
  };
}
