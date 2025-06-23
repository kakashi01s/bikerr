import 'dart:io';

import 'package:bikerr/features/map/domain/repository/location_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:geolocator/geolocator.dart';

class LocationRepositoryImpl extends LocationRepository {
  @override
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  @override
  Future<Either<String, Position>> getCurrentLocation() async {
    try {
      // Step 1: Try to return cached position
      final cached = await Geolocator.getLastKnownPosition();
      if (cached != null) return Right(cached);

      // Step 2: Get fresh location if no cached one
      LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        timeLimit: const Duration(seconds: 5),
      );

      if (Platform.isAndroid) {
        locationSettings = AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
          intervalDuration: const Duration(milliseconds: 1000),
          timeLimit: const Duration(seconds: 10),
        );
      } else if (Platform.isIOS) {
        locationSettings = AppleSettings(
          accuracy: LocationAccuracy.high,
          activityType: ActivityType.automotiveNavigation,
          distanceFilter: 0,
          pauseLocationUpdatesAutomatically: false,
          showBackgroundLocationIndicator: false,
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );
      return Right(position);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.requestPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }
}
