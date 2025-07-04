class Device {
  int? id;
  String? name;
  String? uniqueId;
  String? status;
  bool? disabled;
  DateTime? lastUpdate;
  int? positionId;
  int? groupId;
  String? phone;
  String? model;
  String? contact;
  String? category;
  dynamic attributes;

  Device({
    this.id,
    this.name,
    this.uniqueId,
    this.status,
    this.disabled,
    this.lastUpdate,
    this.positionId,
    this.groupId,
    this.phone,
    this.model,
    this.contact,
    this.category,
    this.attributes,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'],
      name: json['name'],
      uniqueId: json['uniqueId'],
      status: json['status'],
      disabled: json['disabled'],
      lastUpdate: json['lastUpdate'] != null
          ? DateTime.tryParse(json['lastUpdate'])
          : null,
      positionId: json['positionId'],
      groupId: json['groupId'],
      phone: json['phone'],
      model: json['model'],
      contact: json['contact'],
      category: json['category'],
      attributes: json['attributes'],
    );
  }

  static List<Device> fromList(List<dynamic> jsonList) {
    return jsonList
        .map((json) => Device.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'uniqueId': uniqueId,
      'status': status,
      'disabled': disabled,
      'lastUpdate': lastUpdate?.toIso8601String(),
      'positionId': positionId,
      'groupId': groupId,
      'phone': phone,
      'model': model,
      'contact': contact,
      'category': category,
      'attributes': attributes,
    };
  }

  /// For creating a new device (minimal POST payload)
  Map<String, dynamic> toCreateJson() {
    return {
      'name': name,
      'uniqueId': uniqueId,
      'status': status,
      'disabled': disabled,
      'groupId': groupId,
      'phone': phone,
      'model': model,
      'contact': contact,
      'category': category,
      'attributes': attributes,
    };
  }
}
