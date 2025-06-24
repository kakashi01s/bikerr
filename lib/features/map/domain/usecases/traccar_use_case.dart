

import 'package:bikerr/features/map/data/repository/traccar_repository.impl.dart';
import 'package:traccar_gennissi/traccar_gennissi.dart';

class TraccarUseCase{
  final TraccarRepositoryImpl traccarRepositoryImpl;

  TraccarUseCase({required this.traccarRepositoryImpl});

  Future<List<Device>?>getUserDevices() async {
    return await traccarRepositoryImpl.getUserDevices();
  }


}