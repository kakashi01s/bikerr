import 'package:dartz/dartz.dart';
import 'package:geolocator/geolocator.dart';

abstract class LocationRepository {
  Future<Either<String, Position>> getCurrentLocation();
  Future<bool> requestLocationPermission();
  Future<LocationPermission> checkPermission();
}
