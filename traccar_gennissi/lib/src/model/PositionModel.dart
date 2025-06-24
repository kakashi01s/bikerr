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
  final String? accuracy;
  final String? deviceTime;
  final String? serverTime;
  final String? fixTime;
  final dynamic attributes;

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
    this.accuracy,
    this.deviceTime,
    this.serverTime,
    this.fixTime,
    this.attributes,
  });

  factory PositionModel.fromJson(Map<String, dynamic> json) {
    return PositionModel(
      id: json['id'],
      deviceId: json['deviceId'],
      type: json['type'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      altitude: json['altitude'],
      speed: json['speed'],
      course: json['course'],
      address: json['address'],
      accuracy: json['accuracy'],
      deviceTime: json['deviceTime'],
      serverTime: json['serverTime'],
      fixTime: json['fixTime'],
      attributes: json['attributes'],
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