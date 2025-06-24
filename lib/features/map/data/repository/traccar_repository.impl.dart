import 'package:bikerr/features/map/data/datasource/traccar_remote_data_source.dart';
import 'package:bikerr/features/map/domain/repository/traccar_repository.dart';
import 'package:traccar_gennissi/src/model/Device.dart';

class TraccarRepositoryImpl extends TraccarRepository {
  final  TraccarRemoteDataSource traccarRemoteDataSource;

  TraccarRepositoryImpl({required this.traccarRemoteDataSource});


  @override
  Future<List<Device>?> getUserDevices() async{
    return await traccarRemoteDataSource.getUserDevices();
  }

}