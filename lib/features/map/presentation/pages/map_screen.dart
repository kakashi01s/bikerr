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
import '../../../../utils/di/service_locator.dart';
import '../../../../utils/enums/enums.dart';
import '../widgets/marker_animation.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with WidgetsBindingObserver{

  final MapBloc _mapBloc = sl();
  final MapController _mapController = MapController();

  String? _selectedTraccarDevice;

  // Add a flag to ensure the Bloc event is dispatched only once for Traccar devices
  bool _blocEventDispatched = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedTraccarDevice = 'This Device';
    // Dispatch event to get initial location and start tracking
    _mapBloc.add(GetInitialLocation(fetchOnce: true));
    // New: Start Traccar WebSocket connection
    _mapBloc.add(StartTraccarWebSocket());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reconnect WebSocket when app is brought back to foreground
      _mapBloc.add(StartTraccarWebSocket());
    }
  }

  @override
  void dispose() {
    // New: Stop Traccar WebSocket connection
    WidgetsBinding.instance.removeObserver(this);
   _mapBloc.add(StopTraccarWebSocket());
    super.dispose();
  }







  @override
  Widget build(BuildContext context) {
    return BlocListener<MapBloc, MapState>(
      listenWhen: (previous, current) {
        final positionChanged =
            previous.position != current.position && current.position != null;

        final selectedDevicePositionChanged = current.selectedDeviceId != null &&
            previous.traccarDeviceLocations[current.selectedDeviceId] !=
                current.traccarDeviceLocations[current.selectedDeviceId];

        return positionChanged || selectedDevicePositionChanged;
      },
      listener: (context, state) {
        if (state.selectedDeviceId != null &&
            state.traccarDeviceLocations[state.selectedDeviceId] != null) {
          final devicePosition = state.traccarDeviceLocations[state.selectedDeviceId]!;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _mapController.move(devicePosition, 15.0);
          });
        } else if (state.position != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _mapController.move(
              LatLng(state.position!.latitude, state.position!.longitude),
              15.0,
            );
          });
        }
      },
      child: BlocBuilder<MapBloc, MapState>(
        builder: (context, state) {
          if (state.webSocketData != null) {
            print("MapScreen received WebSocket Data: ${state.webSocketData}");
          }

          return SafeArea(
            child: Scaffold(
              appBar: const CustomAppBar(),
              body: Column(
                children: [
                  ActionBar(
                    onMessageTap: () {
                      Navigator.pushNamed(context, RoutesName.conversationsScreen);
                    },
                  ),
                  Expanded(child: _buildMapContent(state)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }







  Widget _buildMapContent(MapState state) {
    if (state.selectedDeviceId != null) {
      print("UI LatLng for ${state.selectedDeviceId}: ${state.traccarDeviceLocations[state.selectedDeviceId]}");
    }
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(24.5854, 73.7125), // Default to Udaipur
            initialZoom: 15.0,
            maxZoom: 18.0,
            minZoom: 3.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            ),

            // Optional: Device-based tracking (can be removed if you prefer only BLoC-based location)
            CurrentLocationLayer(
              alignPositionOnUpdate: AlignOnUpdate.always,
              alignDirectionOnUpdate: AlignOnUpdate.always,
              style: LocationMarkerStyle(
                showAccuracyCircle: true,
                marker: Container(
                  decoration: const BoxDecoration(
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
              alignPositionAnimationDuration: const Duration(milliseconds: 500),
              alignPositionAnimationCurve: Curves.easeOutCubic,
              alignDirectionAnimationDuration: const Duration(milliseconds: 300),
              alignDirectionAnimationCurve: Curves.easeOut,
            ),

            // BLoC-driven marker (updates after permission is granted and position is fetched)
            if (state.position != null)
              MarkerLayer(
                markers: [
                  if (state.selectedDeviceId == null && state.position != null)
                    Marker(
                      point: LatLng(
                        state.position!.latitude,
                        state.position!.longitude,
                      ),
                      width: 40,
                      height: 40,
                      child: AnimatedRotatingMarker(
                        targetPosition: LatLng(
                          state.position!.latitude,
                          state.position!.longitude,
                        ),
                        heading: state.position!.heading,
                      ),
                    ),

                  if (state.selectedDeviceId != null &&
                      state.traccarDeviceLocations.containsKey(state.selectedDeviceId))
                    Marker(
                      point: state.traccarDeviceLocations[state.selectedDeviceId]!,
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.location_on,
                        color: state.selectedDeviceId != null ? Colors.green : Colors.blueAccent,
                        size: 32,
                      ),
                    ),
                ],
              ),
          ],
        ),

        // Dropdown
        Positioned(
          top: 10.0,
          left: 10.0,
          child: Container(
            color: Colors.yellow.withOpacity(0.5),
            child: _buildTraccarDropDown(),
          ),
        ),
      ],
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
      child: BlocBuilder<MapBloc, MapState>(
        builder: (context, state) {
          if (!_blocEventDispatched && state.postApiStatus != PostApiStatus.loading) {
            _blocEventDispatched = true;
            BlocProvider.of<MapBloc>(context).add(GetUserTraccarDevices());
          }

          // Store a mapping from device name to ID
          final Map<String, int?> deviceNameToId = {
            'This Device': null,
          };

          // Create the dropdown items
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
            for (var device in state.traccarDevices!) {
              final name = device.name.toString();
              deviceNameToId[name] = device.id;
              dropdownItems.add(
                DropdownMenuItem<String>(
                  value: name,
                  child: Text(
                    "$name  ${device.status}",
                    style: const TextStyle(color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            }
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
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedTraccarDevice = newValue;
                });
                print("Selected device: $_selectedTraccarDevice");

                final selectedDeviceId = deviceNameToId[newValue];
                context.read<MapBloc>().add(TraccarDeviceSelected(selectedDeviceId));

                if (selectedDeviceId != null &&
                    !state.traccarDeviceLocations.containsKey(selectedDeviceId)) {
                  context.read<MapBloc>().add(GetLastKnownLocationForDevice(selectedDeviceId));
                }
              },
              items: dropdownItems,
            ),
          );

          List<Widget> columnChildren = [
            if (state.postApiStatus == PostApiStatus.loading)
              Row(
                children: [
                  Expanded(child: dropdownContent),
                  const SizedBox(width: 8),
                  const CircularProgressIndicator(
                    strokeWidth: 1,
                    color: Colors.white,
                    constraints: BoxConstraints(maxWidth: 2, maxHeight: 2),
                  ),
                ],
              )
            else if (state.postApiStatus == PostApiStatus.error)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  dropdownContent,
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Error: ${state.errorMessage ?? "Unknown error"}',
                      style: const TextStyle(color: Colors.red, fontSize: 12.0),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )
            else
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

}



