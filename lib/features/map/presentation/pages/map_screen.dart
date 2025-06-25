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
    _selectedTraccarDevice = 'This Device';
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
    print("Building dropdown (updated)");
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0.0),
      decoration: BoxDecoration(
        color: AppColors.markerBg1.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8.0),
      ),
      width: MediaQuery.of(context).size.width * 0.45,
      child: BlocBuilder<MapBloc, MapState>( // <--- BlocBuilder added here
        builder: (context, state) {
          // Dispatch event only if not already dispatched AND not currently loading
          if (!_blocEventDispatched && state.postApiStatus != PostApiStatus.loading) {
            _blocEventDispatched = true; // Set the flag to true to prevent continuous dispatch
            BlocProvider.of<MapBloc>(context).add(GetUserTraccarDevices());
          }

          List<DropdownMenuItem<String>> dropdownItems = [
            const DropdownMenuItem<String>(
              value: 'This Device',
              child: Text(
                'This Device',
                style: TextStyle(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ];

          if (state.postApiStatus == PostApiStatus.success &&
              state.traccarDevices != null &&
              state.traccarDevices!.isNotEmpty) {
            dropdownItems.addAll(
              state.traccarDevices!.map<DropdownMenuItem<String>>((Device device) {
                return DropdownMenuItem<String>(
                  value: device.name.toString(),
                  child: Text(
                    "${device.name.toString()}  ${device.status} ",
                    style: const TextStyle(color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
            );
          }

          String? currentSelection = _selectedTraccarDevice;
          if (currentSelection == null || !dropdownItems.any((item) => item.value == currentSelection)) {
            currentSelection = 'This Device';
          }

          Widget dropdownContent = DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentSelection,
              isExpanded: true,
              dropdownColor: AppColors.markerBg1,
              style: const TextStyle(color: Colors.white, fontSize: 16.0, fontWeight: FontWeight.bold),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedTraccarDevice = newValue;
                });
                print("Selected device: $_selectedTraccarDevice");
              },
              items: dropdownItems,
            ),
          );

          // Conditional rendering for loading/error
          List<Widget> columnChildren = [
            if (state.postApiStatus == PostApiStatus.loading)
              Row(
                children: [
                  Expanded(child: dropdownContent),
                  const SizedBox(width: 8),
                  const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ],
              )
            else if (state.postApiStatus == PostApiStatus.error)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  dropdownContent,
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0), // Smaller padding
                    child: Text(
                      'Error: ${state.errorMessage ?? "Unknown error"}',
                      style: const TextStyle(color: Colors.red, fontSize: 12.0),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )
            else // success or initial state
              dropdownContent,

          ];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: columnChildren,
          );
        },
      ),
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
          // Wrap _buildTraccarDropDown() with a colored container for debugging
          child: Container(
            color: Colors.yellow.withOpacity(0.5), // A highly visible color
            // You might need to give it a size here if the dropdown still doesn't show
            // width: 200, // Example size
            // height: 50, // Example size
            child: _buildTraccarDropDown(),
          ),
        ),
      ],
    );
  }
}



