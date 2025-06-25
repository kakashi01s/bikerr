// model/PositionModel.dart
class PositionModel {
  final int? id;
  final int? deviceId;
  final int? type;
  final double? latitude;
  final double? longitude;
  final double? altitude;
  final double? speed;
  final double? course;
  final String? address;
  final double? accuracy; // <--- CHANGE THIS FROM String? TO double?
  final String? deviceTime;
  final String? serverTime;
  final String? fixTime;
  final dynamic attributes; // This can remain dynamic if you're not strictly typing it yet

  PositionModel({
    this.id,
    this.deviceId,
    this.type,
    this.latitude,
    this.longitude,
    this.altitude,
    this.speed,
    this.course,
    this.address,
    this.accuracy, // <--- Now it matches double?
    this.deviceTime,
    this.serverTime,
    this.fixTime,
    this.attributes,
  });

  factory PositionModel.fromJson(Map<String, dynamic> json) {
    return PositionModel(
      id: json['id'] as int?, // Explicitly cast with 'as Type?' for safety
      deviceId: json['deviceId'] as int?,
      type: json['type'] as int?, // Traccar's 'type' is usually int or null
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      altitude: json['altitude'] as double?,
      speed: json['speed'] as double?,
      course: json['course'] as double?,
      address: json['address'] as String?, // Keep as String? as it's null in your sample
      accuracy: json['accuracy'] as double?, // <--- Cast as double?
      deviceTime: json['deviceTime'] as String?,
      serverTime: json['serverTime'] as String?,
      fixTime: json['fixTime'] as String?,
      attributes: json['attributes'], // Keep as dynamic if not creating a separate model
    );
  }

  // Add the static fromList method
  static List<PositionModel> fromList(List<dynamic> jsonList) {
    return jsonList.map((json) => PositionModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceId': deviceId,
      'type': type,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'speed': speed,
      'course': course,
      'address': address,
      'accuracy': accuracy,
      'deviceTime': deviceTime,
      'serverTime': serverTime,
      'fixTime': fixTime,
      'attributes': attributes,
    };
  }
}