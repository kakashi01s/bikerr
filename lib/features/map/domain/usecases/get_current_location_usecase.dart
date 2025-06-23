import 'package:bikerr/features/map/data/repository/location_repository_impl.dart';
import 'package:dartz/dartz.dart';
import 'package:geolocator/geolocator.dart';

class GetCurrentLocationUsecase {
  final LocationRepositoryImpl locationRepositoryImpl;

  GetCurrentLocationUsecase({required this.locationRepositoryImpl});

  Future<Either<String, Position>> getLocation() async {
    return await locationRepositoryImpl.getCurrentLocation();
  }

  Future<bool> requestPermission() async {
    return await locationRepositoryImpl.requestLocationPermission();
  }

  Future<LocationPermission> checkPermission() async {
    return await locationRepositoryImpl.checkPermission();
  }
}
