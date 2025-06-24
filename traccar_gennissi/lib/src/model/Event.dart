// model/Event.dart
class Event {
  final int? id;
  final String? type;
  final String? serverTime;
  final int? deviceId;
  final int? positionId;
  final int? geofenceId;
  final int? maintenanceId;
  final dynamic attributes;

  Event({
    this.id,
    this.type,
    this.serverTime,
    this.deviceId,
    this.positionId,
    this.geofenceId,
    this.maintenanceId,
    this.attributes,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      type: json['type'],
      serverTime: json['serverTime'],
      deviceId: json['deviceId'],
      positionId: json['positionId'],
      geofenceId: json['geofenceId'],
      maintenanceId: json['maintenanceId'],
      attributes: json['attributes'],
    );
  }

  // Add the static fromList method
  static List<Event> fromList(List<dynamic> jsonList) {
    return jsonList.map((json) => Event.fromJson(json as Map<String, dynamic>)).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'serverTime': serverTime,
      'deviceId': deviceId,
      'positionId': positionId,
      'geofenceId': geofenceId,
      'maintenanceId': maintenanceId,
      'attributes': attributes,
    };
  }
}