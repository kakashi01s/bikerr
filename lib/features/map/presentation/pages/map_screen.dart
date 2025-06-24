import 'dart:async';
import 'dart:ui';

import 'package:bikerr/config/constants.dart';
import 'package:bikerr/config/routes/route_names.dart';
import 'package:bikerr/core/theme.dart';
import 'package:bikerr/features/map/presentation/bloc/map_bloc.dart';
import 'package:bikerr/features/map/presentation/widgets/action_bar.dart';
import 'package:bikerr/features/map/presentation/widgets/app_bar.dart';
import 'package:bikerr/services/session/session_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:traccar_gennissi/traccar_gennissi.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../utils/di/service_locator.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final SessionManager sessionManager = SessionManager.instance;
  final MapBloc _mapBloc = MapBloc(getCurrentLocationUsecase: sl());
  final MapController _mapController = MapController();

  LatLng _currentMapCenter = const LatLng(24.5854, 73.7125); // Udaipur
  String _locationText = "Fetching location...";

  StreamSubscription<Position>? _positionStreamSubscription;

  // --- New: Dropdown related state ---
  final List<String> _traccarDevices = ['This Device', 'Bike Alpha', 'Car Beta', 'Truck Gamma'];
  String? _selectedTraccarDevice;

  @override
  void initState() {
    super.initState();
    _selectedTraccarDevice = _traccarDevices[0]; // Initialize with "This Device"
    _checkAndGetLocation();
    Traccar.getDevices();
  }

  Future<void> _checkAndGetLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled. Please enable them.')),
        );
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied. Map may not show your location.')),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permissions are permanently denied. Please enable them from app settings.'),
            duration: Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    Position initialPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    _updateLocation(initialPosition);

    _startLocationStream();
  }

  void _startLocationStream() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
          (Position position) {
        _updateLocation(position);
      },
      onError: (e) {
        print("Location stream error: $e");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error getting location updates: $e')),
          );
        }
      },
      onDone: () {
        print("Location stream done.");
      },
      cancelOnError: true,
    );
  }

  void _updateLocation(Position position) {
    if (mounted) {
      setState(() {
        _currentMapCenter = LatLng(position.latitude, position.longitude);
        _locationText = 'Lat: ${position.latitude.toStringAsFixed(6)}, Lon: ${position.longitude.toStringAsFixed(6)}';
        print('Current Location: Latitude: ${position.latitude}, Longitude: ${position.longitude}');
      });
    }
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _mapBloc.close();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MapBloc>.value(
      value: _mapBloc,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: AppColors.bikerrbgColor,
          appBar: const CustomAppBar(),
          body: Column(
            children: [
              ActionBar(
                onMessageTap: () {
                  Navigator.pushNamed(context, RoutesName.conversationsScreen);
                },
              ),
              Expanded(
                child: _buildMapContent(),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              if (mounted) {
                _mapController.move(_currentMapCenter, 15.0);
              }
            },
            child: const Icon(Icons.my_location),
          ),
        ),
      ),
    );
  }

  // Updated _buildTraccarDropDown to be a functional dropdown
  Widget _buildTraccarDropDown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: AppColors.markerBg1.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8.0),
      ),
      width: MediaQuery.of(context).size.width * 0.45,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // BlocBuilder for dropdown if items come from Bloc, otherwise setState is fine
          // For now, we'll use setState and assume items are local or fetched once.
          // If _traccarDevices were to be fetched from BLoC, this is where BlocBuilder would wrap the DropdownButton.
          DropdownButtonHideUnderline( // Hides the default underline
            child: DropdownButton<String>(
              value: _selectedTraccarDevice,
              isExpanded: true, // Make dropdown take full available width
              dropdownColor: AppColors.markerBg1, // Background color of the dropdown menu
              style: const TextStyle(color: Colors.white, fontSize: 16.0, fontWeight: FontWeight.bold),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white), // Custom icon
              onChanged: (String? newValue) {
                setState(() {
                  _selectedTraccarDevice = newValue;
                  // Handle selection change: e.g., if "This Device" is selected, follow current location.
                  // If another device is selected, you might fetch its last known location via BLoC.
                  print("Selected device: $_selectedTraccarDevice");
                });
                // If you need to trigger a BLoC event based on selection:
                // _mapBloc.add(LoadDeviceLocation(newValue));
              },
              items: _traccarDevices.map<DropdownMenuItem<String>>((String device) {
                return DropdownMenuItem<String>(
                  value: device,
                  child: Text(
                    device,
                    style: const TextStyle(color: Colors.white), // Text color for items
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            _locationText,
            style: const TextStyle(color: Colors.white70, fontSize: 12.0),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMapContent() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentMapCenter,
            initialZoom: 15.0,
            maxZoom: 18.0,
            minZoom: 3.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.starust.bikerr',
            ),
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution(
                  'OpenStreetMap contributors',
                  onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
                ),
              ],
              alignment: AttributionAlignment.bottomRight,
            ),
            CurrentLocationLayer(
              key: const ValueKey("CurrentLocationMarker"),
              positionStream: Geolocator.getPositionStream(
                locationSettings: const LocationSettings(
                  accuracy: LocationAccuracy.high,
                  distanceFilter: 0,
                ),
              ).map((position) => LocationMarkerPosition(
                latitude: position.latitude,
                longitude: position.longitude,
                accuracy: position.accuracy,
              )),
              style: LocationMarkerStyle(
                showAccuracyCircle: true,
                marker: Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.navigation,
                      color: AppColors.bikerrRedFill,
                      size: 24.0,
                    ),
                  ),
                ),
                markerSize: const Size(40, 40),
                markerDirection: MarkerDirection.heading,
                accuracyCircleColor: AppColors.markerBg1.withOpacity(0.3),
                headingSectorColor: AppColors.markerBg1.withOpacity(0.7),
                headingSectorRadius: 60,
              ),
              alignPositionOnUpdate: AlignOnUpdate.always,
              alignPositionAnimationDuration: const Duration(milliseconds: 500),
              alignPositionAnimationCurve: Curves.easeOutCubic,
              alignDirectionAnimationDuration: const Duration(milliseconds: 300),
              alignDirectionAnimationCurve: Curves.easeOut,
            ),
          ],
        ),
        Positioned(
          top: 10.0,
          left: 10.0,
          child: _buildTraccarDropDown(),
        ),
      ],
    );
  }
}