import 'package:traccar_gennissi/traccar_gennissi.dart';

abstract class TraccarRepository {
  Future<List<Device>?> getUserDevices();
}