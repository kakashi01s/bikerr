import 'dart:ui';
import 'package:bikerr/config/routes/route_names.dart';
import 'package:bikerr/core/theme.dart';
import 'package:bikerr/features/map/presentation/bloc/map_bloc.dart';
import 'package:bikerr/features/map/presentation/widgets/action_bar.dart';
import 'package:bikerr/features/map/presentation/widgets/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:traccar_gennissi/traccar_gennissi.dart';
import '../../../../utils/di/service_locator.dart';
import '../../../../utils/enums/enums.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapBloc _mapBloc = sl();
  final MapController _mapController = MapController();

  String? _selectedTraccarDevice;

  // Add a flag to ensure the Bloc event is dispatched only once for Traccar devices
  bool _blocEventDispatched = false;

  @override
  void initState() {
    super.initState();
    // Dispatch event to get initial location and start tracking
    _mapBloc.add(GetInitialLocation());
    // New: Start Traccar WebSocket connection
    _mapBloc.add(StartTraccarWebSocket());
  }

  @override
  void dispose() {
    // New: Stop Traccar WebSocket connection
   // _mapBloc.add(StopTraccarWebSocket());
    super.dispose();
  }








  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MapBloc, MapState>(
      builder: (context, state) {
        // New: Print WebSocket data (for debugging/demonstration)
        if (state.webSocketData != null) {
          print("MapScreen received WebSocket Data: ${state.webSocketData.toString()}");
          // Here you would typically parse the webSocketData and update map markers,
          // device positions, etc. based on the type of data received.
          // Example: if (state.webSocketData is PositionModel) { updateMarkerPosition(state.webSocketData); }
        }

        return SafeArea(
          child: Scaffold(
            appBar:const CustomAppBar(),
            body: Column(
              children: [
                ActionBar(onMessageTap: () {
                  Navigator.pushNamed(context, RoutesName.conversationsScreen);
                }),
                Expanded(child: _buildMapContent(state))
          
              ],
            )
          ),
        );
      },
    );
  }



  Widget _buildTraccarDropDown() {
    return BlocBuilder<MapBloc, MapState>(
      builder: (context, state) {
        if (!_blocEventDispatched && state.postApiStatus != PostApiStatus.loading) {
          _blocEventDispatched = true;
          BlocProvider.of<MapBloc>(context).add(GetUserTraccarDevices());
        }
        if (state.postApiStatus == PostApiStatus.loading && state.traccarDevices == null) {
          return CircularProgressIndicator(); // Show loading indicator
        } else if (state.postApiStatus == PostApiStatus.error) {
          return Text('Error: ${state.errorMessage}'); // Show error message
        } else if (state.traccarDevices != null && state.traccarDevices!.isNotEmpty) {
          return DropdownButtonHideUnderline( // Hides the default underline
            child: DropdownButton<String>(
              value: _selectedTraccarDevice,
              isExpanded: true, // Make dropdown take full available width
              dropdownColor: AppColors.markerBg1, // Background color of the dropdown menu
              style: const TextStyle(color: Colors.white, fontSize: 16.0, fontWeight: FontWeight.bold),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white), // Custom icon
              onChanged: (String? newValue) {
                setState(() {
                  _selectedTraccarDevice = newValue;
                });
                // You can dispatch an event here to fetch specific data for the selected device
              },
              items: state.traccarDevices!.map<DropdownMenuItem<String>>((Device device) {
                return DropdownMenuItem<String>(
                  value: device.name.toString(),
                  child: Text(
                    device.name.toString(),
                    style: const TextStyle(color: Colors.white), // Text color for items
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
            ),
          );
        } else {
          return Text('No Traccar devices found.'); // No devices
        }
      },
    );
  }


  _buildMapContent(state ) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: state.position != null
                ? LatLng(state.position!.latitude, state.position!.longitude)
                : LatLng(24.5854, 73.7125), // Default to Udaipur if no position
            initialZoom: 15.0,
            maxZoom: 18.0,
            minZoom: 3.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              // subdomains: ['a', 'b', 'c'],
            ),
            CurrentLocationLayer(
              alignPositionOnUpdate: AlignOnUpdate.always,
              alignDirectionOnUpdate: AlignOnUpdate.always,
              // followOnLocationUpdate: FollowOnLocationUpdate.always,
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
              //  alignPositionOnUpdate: AlignOnUpdate.always,
              alignPositionAnimationDuration:
              const Duration(milliseconds: 500),
              alignPositionAnimationCurve: Curves.easeOutCubic,
              alignDirectionAnimationDuration:
              const Duration(milliseconds: 300),
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



