import 'dart:async';
import 'dart:math' as math;
import 'package:bikerr/config/routes/route_names.dart';
import 'package:bikerr/core/theme.dart';
import 'package:bikerr/features/map/presentation/bloc/map_bloc.dart';
import 'package:bikerr/features/map/presentation/widgets/action_bar.dart';
import 'package:bikerr/features/map/presentation/widgets/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:traccar_gennissi/traccar_gennissi.dart';

import '../widgets/heading_cone_painter.dart';

class LatLngTween extends Tween<LatLng> {
  LatLngTween({required super.begin, required super.end});

  @override
  LatLng lerp(double t) {
    final lat = begin!.latitude + (end!.latitude - begin!.latitude) * t;
    final lng = begin!.longitude + (end!.longitude - begin!.longitude) * t;
    return LatLng(lat, lng);
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  bool _isThisDevice = true;
  bool _isMapReady = false;
  final MapController _mapController = MapController();
  late final AnimationController _animationController;
  StreamSubscription<CompassEvent>? _compassSubscription;
  double _heading = 0.0;

  late LatLngTween _latLngTween;
  late Animation<double> _animation;

  MapLoaded? _previousState;
  List<Device> _traccarDevices = [];

  void _onAnimationTick() {
    final newCenter = _latLngTween.evaluate(_animation);
    _mapController.move(newCenter, _mapController.camera.zoom);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _latLngTween = LatLngTween(begin: const LatLng(0, 0), end: const LatLng(0, 0));
    _animationController.addListener(_onAnimationTick);
    _animation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _startListeningToCompass();
    context.read<MapBloc>().add(GetInitialLocation(fetchOnce: true));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<MapBloc>().add(StartTraccarWebSocket());
      _startListeningToCompass();
    } else if (state == AppLifecycleState.paused) {
      context.read<MapBloc>().add(StopTraccarWebSocket());
      _stopListeningToCompass();
    }
  }

  void _startListeningToCompass() {
    if (_compassSubscription == null && mounted) {
      _compassSubscription = FlutterCompass.events?.listen((CompassEvent event) {
        if (mounted) setState(() => _heading = (event.heading ?? 0) * (math.pi / 180));
      });
    }
  }

  void _stopListeningToCompass() {
    _compassSubscription?.cancel();
    _compassSubscription = null;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopListeningToCompass();
    _animationController.removeListener(_onAnimationTick);
    _animationController.dispose();
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
              onMessageTap: () => Navigator.pushNamed(context, RoutesName.conversationsScreen),
              isThisDevice: _isThisDevice,
            ),
            Expanded(
              child: BlocConsumer<MapBloc, MapState>(
                buildWhen: (previous, current) =>
                current is MapLoaded || current is MapInitial || current is MapLoading || current is MapError,
                listenWhen: (previous, current) => true,
                listener: (context, state) {
                  if (state is TraccarDevicesLoaded) {
                    setState(() => _traccarDevices = state.traccarDevices);
                  }

                  if (state is MapLoaded) {
                    final position = _getTargetPosition(state);
                    if (position == null || !_isMapReady) return;

                    if (_previousState == null) {
                      _latLngTween = LatLngTween(begin: position, end: position);
                      _mapController.move(position, 15.0);
                    } else {
                      _animateMapAndMarker(position);
                    }
                    _previousState = state;
                  }
                },
                builder: (context, state) {
                  switch (state) {
                    case MapInitial():
                      return const Center(child: Text('Initializing Map...'));
                    case MapLoading():
                      return const Center(child: CircularProgressIndicator());
                    case MapError(message: final msg):
                      return Center(child: Text('Error: $msg'));
                    case MapLoaded():
                      return _buildMapContent(context, state);
                    case LoadingDevices(previousState: final prevState):
                      return _buildMapContent(context, prevState ?? const MapLoaded());
                    case TraccarDevicesLoaded():
                      final currentState = context.read<MapBloc>().state;
                      return _buildMapContent(context, currentState is MapLoaded ? currentState : const MapLoaded());
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  LatLng? _getTargetPosition(MapLoaded state) {
    if (state.selectedDeviceId == null) {
      final pos = state.currentDevicePosition;
      if (pos != null) {
        if (!_isThisDevice) setState(() => _isThisDevice = true);
        return LatLng(pos.latitude, pos.longitude);
      }
    } else {
      final pos = state.traccarDeviceLastPosition;
      if (pos != null && pos.latitude != null && pos.longitude != null) {
        if (_isThisDevice) setState(() => _isThisDevice = false);
        return LatLng(pos.latitude!, pos.longitude!);
      }
    }
    return null;
  }

  void _animateMapAndMarker(LatLng newPosition) {
    _latLngTween.begin = _latLngTween.evaluate(_animation);
    _latLngTween.end = newPosition;
    _animationController.reset();
    _animationController.forward();
  }

  Widget _buildMapContent(BuildContext context, MapLoaded state) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _getTargetPosition(state) ?? const LatLng(24.5854, 73.7125),
            initialZoom: 15.0,
            maxZoom: 18.0,
            minZoom: 3.0,
            onPositionChanged: (camera, hasGesture) {
              if (hasGesture && _animationController.isAnimating) _animationController.stop();
            },
            onMapReady: () {
              if (!_isMapReady) setState(() => _isMapReady = true);
            },
          ),
          children: [
            TileLayer(urlTemplate: 'http://mt0.google.com/vt/lyrs=m&hl=en&x={x}&y={y}&z={z}'),
            _buildAnimatedMarker(),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: _buildTraccarDropDown(state),
        ),
        if (!_isThisDevice)
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: AppColors.markerBg1,
              child: const Icon(Icons.arrow_upward_sharp, color: Colors.red),
              onPressed: () => _showDeviceDetailsSheet(context, state),
            ),
          ),
      ],
    );
  }

  Widget _buildAnimatedMarker() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final currentLatLng = _latLngTween.evaluate(_animation);
        if (currentLatLng.latitude == 0 && currentLatLng.longitude == 0) return const SizedBox.shrink();
        return MarkerLayer(
          markers: [
            Marker(
              width: 80,
              height: 80,
              point: currentLatLng,
              child: MapHeadingMarker(
                heading: _heading,
                color: _isThisDevice ? Colors.red : Colors.green,
                isThisDevice: _isThisDevice,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTraccarDropDown(MapLoaded mapState) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dropdownWidth = screenWidth * 0.5;

    return Align(
      alignment: Alignment.topLeft,
      child: Container(
        width: dropdownWidth,
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: BlocBuilder<MapBloc, MapState>(
          buildWhen: (previous, current) =>
          current is LoadingDevices || current is TraccarDevicesLoaded || current is MapLoaded,
          builder: (context, state) {
            if (state is LoadingDevices) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text('Loading...', style: TextStyle(color: Colors.white70)),
                  SizedBox(width: 10),
                  SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                ],
              );
            }

            final selectedDeviceId = (state is MapLoaded) ? state.selectedDeviceId : mapState.selectedDeviceId;
            final deviceIdToName = {
              null: 'This Device',
              for (var device in _traccarDevices)
                if (device.id != null && device.name != null) device.id!: "${device.name} ${device.status}",
            };

            return DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                value: selectedDeviceId,
                isExpanded: true,
                menuWidth: dropdownWidth,
                dropdownColor: Colors.black.withOpacity(0.85),
                style: const TextStyle(color: Colors.white, fontSize: 16.0),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                onChanged: (id) => context.read<MapBloc>().add(TraccarDeviceSelected(id)),
                items: deviceIdToName.entries.map((entry) {
                  return DropdownMenuItem<int?>(
                    value: entry.key,
                    child: Row(
                      children: [
                        Expanded(child: Text(entry.value, overflow: TextOverflow.ellipsis)),
                        if (entry.key != null)
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                            onPressed: () => showDialog(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: Text("Delete '${entry.value}'?"),
                                content: const Text("This action cannot be undone."),
                                actions: [
                                  TextButton(
                                    child: const Text("Cancel"),
                                    onPressed: () => Navigator.of(dialogContext).pop(),
                                  ),
                                  TextButton(
                                    child: const Text("Delete", style: TextStyle(color: Colors.red)),
                                    onPressed: () {
                                      context.read<MapBloc>().add(DeleteDevice(entry.key!));
                                      Navigator.of(dialogContext).pop();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showDeviceDetailsSheet(BuildContext context, MapLoaded state) {
    final pos = state.traccarDeviceLastPosition;
    final totalDistance = (pos?.attributes?['totalDistance'] as num? ?? 0.0) / 1000; // Convert to km
    final topSpeed = (pos?.attributes?['topSpeed'] as num? ?? 0.0) / 1000; // Convert to km
    final deviceName = _traccarDevices.firstWhere((d) => d.id == state.selectedDeviceId, orElse: () => Device()).name;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
          decoration: const BoxDecoration(
            color: Color(0xFF2E2E32),
            borderRadius: BorderRadius.only(topLeft: Radius.circular(24.0), topRight: Radius.circular(24.0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 5,
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(10)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(deviceName ?? "More Details", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                  const Icon(Icons.precision_manufacturing_rounded, color: Colors.blueAccent, size: 28),
                ],
              ),
              const Divider(color: Colors.white24, height: 30),
              _buildDetailRow(context, icon: Icons.route, label: "Total Km", value: "${totalDistance.toStringAsFixed(2)} km"),
              _buildDetailRow(context, icon: Icons.speed_rounded, label: "Top Speed", value: "${topSpeed.toStringAsFixed(2)} km/h}"), // Placeholder
              _buildDetailRow(context, icon: Icons.av_timer_rounded, label: "Avg Speed", value: "48 km/h"), // Placeholder
              const Divider(color: Colors.white24, height: 30),
              _buildActionRow(context, icon: Icons.history_rounded, label: "Ride History", onTap: () {}),
              _buildActionRow(context, icon: Icons.fence_rounded, label: "Geofences", onTap: () {
                Navigator.of(context).pushNamed(RoutesName.geoFenceScreen, arguments: {
                 "position": state.currentDevicePosition
                });
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(BuildContext context, {required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 22),
          const SizedBox(width: 15),
          Text(label, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70)),
          const Spacer(),
          Text(value, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActionRow(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 15),
              Text(label, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white)),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}