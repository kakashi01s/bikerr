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
import 'package:traccar_gennissi/traccar_gennissi.dart';
import 'package:tuple/tuple.dart';
import '../../../../utils/enums/enums.dart';
import '../widgets/marker_animation.dart';
import 'package:geolocator/geolocator.dart'; // Assuming this is the Position source

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with WidgetsBindingObserver {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Dispatch initial event to get location and start the socket
    context.read<MapBloc>().add(GetInitialLocation(fetchOnce: true));
    context.read<MapBloc>().add(StartTraccarWebSocket());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<MapBloc>().add(StartTraccarWebSocket());
    } else if (state == AppLifecycleState.paused) {
      context.read<MapBloc>().add(StopTraccarWebSocket());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            Expanded(
              child: BlocConsumer<MapBloc, MapState>(
                listenWhen: (previous, current) => _shouldMoveMap(previous, current),
                listener: (context, state) {
                  if (state is MapLoaded) {
                    _moveMapToSelectedDevice(state);
                  }
                },
                builder: (context, state) {
                  return switch (state) {
                    MapInitial() => const Center(child: Text('Initializing Map...')),
                    MapLoading() => const Center(child: CircularProgressIndicator()),
                    MapError(message: final msg) => Center(child: Text('Error: $msg')),
                    MapLoaded() => _buildMapContent(context, state),
                  };
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _shouldMoveMap(MapState previous, MapState current) {
    if (current is! MapLoaded) return false;
    // If the previous state wasn't loaded, we definitely want to move
    if (previous is! MapLoaded) return true;

    // Move if the selected device ID changes
    if (previous.selectedDeviceId != current.selectedDeviceId) {
      return true;
    }

    // Move if 'This Device' is selected and its position has updated
    if (current.selectedDeviceId == null && previous.currentDevicePosition != current.currentDevicePosition) {
      return true;
    }

    // Move if a Traccar device is selected and its location has updated
    if (current.selectedDeviceId != null &&
        previous.traccarDeviceLocations[current.selectedDeviceId] != current.traccarDeviceLocations[current.selectedDeviceId]) {
      return true;
    }

    return false;
  }

  void _moveMapToSelectedDevice(MapLoaded state) {
    LatLng? targetLatLng;

    if (state.selectedDeviceId == null) {
      // 'This Device' is selected
      final pos = state.currentDevicePosition;
      if (pos != null) {
        targetLatLng = LatLng(pos.latitude, pos.longitude);
      }
    } else {
      // A Traccar device is selected
      targetLatLng = state.traccarDeviceLocations[state.selectedDeviceId!];
    }

    if (targetLatLng != null) {
      _mapController.move(targetLatLng, _mapController.camera.zoom);
    }
  }

  Widget _buildMapContent(BuildContext context, MapLoaded state) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(
              state.currentDevicePosition?.latitude ?? 24.5854,
              state.currentDevicePosition?.longitude ?? 73.7125,
            ),
            initialZoom: 15.0,
            maxZoom: 18.0,
            minZoom: 3.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            ),
            MarkerLayer(
              markers: _buildMarkers(state),
            ),
          ],
        ),
        Positioned(
          top: 10.0,
          left: 10.0,
          right: 10.0,
          child: _buildTraccarDropDown(),
        ),
      ],
    );
  }

  List<Marker> _buildMarkers(MapLoaded state) {
    final List<Marker> markers = [];
    LatLng? positionToShow;

    if (state.selectedDeviceId == null) {
      // Show 'This Device' location
      final pos = state.currentDevicePosition;
      if (pos != null) {
        positionToShow = LatLng(pos.latitude, pos.longitude);
        markers.add(
          Marker(
            width: 50,
            height: 50,
            point: positionToShow,
            child: const Icon(Icons.my_location, color: Colors.blue, size: 35),
          ),
        );
      }
    } else {
      // Show selected Traccar device location
      positionToShow = state.traccarDeviceLocations[state.selectedDeviceId!];
      if (positionToShow != null) {
        markers.add(
          Marker(
            width: 80,
            height: 80,
            point: positionToShow,
            // Consider using a different marker for Traccar devices
            child: const Icon(Icons.location_on, color: Colors.red, size: 40),
          ),
        );
      }
    }
    return markers;
  }

  Widget _buildTraccarDropDown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: BlocBuilder<MapBloc, MapState>(
        // Use a builder as we only need to rebuild the dropdown UI
        builder: (context, state) {
          if (state is! MapLoaded) {
            // Show a disabled or loading state for the dropdown
            return const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Loading Devices...', style: TextStyle(color: Colors.white)),
                SizedBox(width: 10),
                SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
              ],
            );
          }

          final devices = state.traccarDevices;
          final selectedDeviceId = state.selectedDeviceId;

          final Map<int?, String> deviceIdToName = {
            null: 'This Device',
            for (var device in devices) device.id!: device.name!,
          };

          return DropdownButtonHideUnderline(
            child: DropdownButton<int?>(
              value: selectedDeviceId,
              isExpanded: true,
              dropdownColor: Colors.black.withOpacity(0.85),
              style: const TextStyle(color: Colors.white, fontSize: 16.0),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              onChanged: (int? newSelectedDeviceId) {
                if (newSelectedDeviceId == selectedDeviceId) return;

                context.read<MapBloc>().add(TraccarDeviceSelected(newSelectedDeviceId));

                // If a traccar device is selected, ensure we have its location
                if (newSelectedDeviceId != null && !state.traccarDeviceLocations.containsKey(newSelectedDeviceId)) {
                  context.read<MapBloc>().add(GetLastKnownLocationForDevice(newSelectedDeviceId));
                }
              },
              items: deviceIdToName.entries.map((entry) {
                return DropdownMenuItem<int?>(
                  value: entry.key,
                  child: Text(
                    entry.value,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}