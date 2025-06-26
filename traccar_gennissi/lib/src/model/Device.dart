// model/Device.dart
class Device {
  final int? id;
  final String? name;
  final String? uniqueId;
  final String? status;
  final bool? disabled;
  final int? lastPositionId;
  final int? groupId;
  final List<dynamic>? calendarsId;
  final String? phone;
  final String? model;
  final String? contact;
  final String? category;
  final double? geofenceIds;
  final String? manufacturer;
  final String? plate;
  final String? imei;
  final dynamic attributes;

  Device({
    this.id,
    this.name,
    this.uniqueId,
    this.status,
    this.disabled,
    this.lastPositionId,
    this.groupId,
    this.calendarsId,
    this.phone,
    this.model,
    this.contact,
    this.category,
    this.geofenceIds,
    this.manufacturer,
    this.plate,
    this.imei,
    this.attributes,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'],
      name: json['name'],
      uniqueId: json['uniqueId'],
      status: json['status'],
      disabled: json['disabled'],
      lastPositionId: json['positionId'],
      groupId: json['groupId'],
      calendarsId: json['calendarsId'],
      phone: json['phone'],
      model: json['model'],
      contact: json['contact'],
      category: json['category'],
      geofenceIds: json['geofenceIds'] is int ? json['geofenceIds'].toDouble() : json['geofenceIds'],
      manufacturer: json['manufacturer'],
      plate: json['plate'],
      imei: json['imei'],
      attributes: json['attributes'],
    );
  }


  static List<Device> fromList(List<dynamic> jsonList) {
    return jsonList.map((json) => Device.fromJson(json as Map<String, dynamic>)).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'uniqueId': uniqueId,
      'status': status,
      'disabled': disabled,
      'lastPositionId': lastPositionId,
      'groupId': groupId,
      'calendarsId': calendarsId,
      'phone': phone,
      'model': model,
      'contact': contact,
      'category': category,
      'geofenceIds': geofenceIds,
      'manufacturer': manufacturer,
      'plate': plate,
      'imei': imei,
      'attributes': attributes,
    };
  }
}