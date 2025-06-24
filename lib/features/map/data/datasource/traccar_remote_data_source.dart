import 'package:bikerr/config/constants.dart';
import 'package:bikerr/services/session/session_manager.dart';
import 'package:traccar_gennissi/traccar_gennissi.dart';

import '../../../../utils/network/network_api_services.dart';
abstract class TraccarDataSource {
 // Future<Either<Result<String>,ApiError>>getTraccarSessionCookie();
  Future<List<Device>?>getUserDevices();


}


class TraccarRemoteDataSource extends TraccarDataSource {
  final SessionManager sessionManager = SessionManager.instance;
  final _api = NetworkServicesApi();
  
  @override
  Future<List<Device>?> getUserDevices() async {
    final devicesList = await Traccar.getDevices();
    return devicesList;
  }



}

