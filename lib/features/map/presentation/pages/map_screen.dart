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
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';
import 'package:traccar_gennissi/traccar_gennissi.dart';

import '../../../../services/session/session_manager.dart';
import '../widgets/heading_cone_painter.dart';

// LatLngTween class remains the same for smooth animations.
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

  List<Device> _cachedDevices = [];

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
    _animation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _animationController.addListener(_onAnimationTick);
    _startListeningToCompass();
    context.read<MapBloc>().add(const GetInitialLocation(fetchOnce: true));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<MapBloc>().add(StartTraccarWebSocket());
      context.read<MapBloc>().add(const StartLocationTracking());
      _startListeningToCompass();
    } else if (state == AppLifecycleState.paused) {
      context.read<MapBloc>().add(StopTraccarWebSocket());
      context.read<MapBloc>().add(const StopLocationTracking());
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

  MapLoaded _getLoadedState(MapState state) {
    if (state is MapLoaded) return state;
    if (state is MapError && state.previousState != null) return state.previousState!;
    if (state is TraccarDevicesLoading) return state.previousState;
    if (state is TraccarDevicesLoaded) return state.previousState;
    if (state is ReportLoading) return state.previousState;
    if (state is RouteReportLoaded) return state.previousState;
    if (state is DeleteTraccarDeviceLoading) return state.previousState;
    if (state is DeleteTraccarDeviceLoaded) return state.previousState;
    if (state is GeofencesLoading) return state.previousState;
    if (state is GeofencesLoaded) return state.previousState;
    if (state is TraccarEventsLoaded) return state.previousState;
    if (state is UpdateTraccarDeviceLoading) return state.previousState;
    if (state is AddTraccarDeviceLoading) return state.previousState;
    if (state is PositionByIdLoading) return state.previousState;
    if (state is PositionByIdLoaded) return state.previousState;
    if (state is NotificationTypesLoading) return state.previousState;
    if (state is NotificationTypesLoaded) return state.previousState;
    if (state is NotificationsLoading) return state.previousState;
    if (state is NotificationsLoaded) return state.previousState;
    if (state is DeleteTraccarGeofenceLoading) return state.previousState;
    if (state is DeleteTraccarGeofenceLoaded) return state.previousState;
    if (state is AddTraccarNotificationLoaded) return state.previousState;
    if (state is AddTraccarNotificationLoading) return state.previousState;
    if (state is DeleteTraccarNotificationLoading) return state.previousState;
    if (state is DeleteTraccarNotificationLoaded) return state.previousState;
    if (state is SendCommandsLoaded) return state.previousState;
    return const MapLoaded();
  }

  bool _isLoading(MapState state) {
    return state is ReportLoading ||
        state is TraccarDevicesLoading ||
        state is DeleteTraccarDeviceLoading ||
        state is GeofencesLoading ||
        state is UpdateTraccarDeviceLoading ||
        state is AddTraccarDeviceLoading;
  }
// NOTE: This logic is used in multiple places
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: CustomAppBar(),
        drawer: Drawer(
          clipBehavior: Clip.hardEdge,
          backgroundColor: AppColors.bikerrbgColor,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              SizedBox(height: 80,),
              drawerHeader(),
              SizedBox(height: 20,),
              drawerContent()

            ])),
        body: Column(
          children: [
            // **MODIFIED**: ActionBar is now wrapped in a BlocBuilder here
            BlocBuilder<MapBloc, MapState>(
              builder: (context, state) {
                final loadedState = _getLoadedState(state);
                String? speedText;
                final bool isThisDeviceSelected = loadedState.selectedDeviceId == null;

                if (isThisDeviceSelected) {
                  // Geolocator speed is in meters/second. Convert to km/h.
                  final speedInMps = loadedState.currentDevicePosition?.speed;
                  if (speedInMps != null && speedInMps > 0) {
                    final speedInKmh = speedInMps * 3.6;
                    speedText = '${speedInKmh.toStringAsFixed(1)} km/h';
                  }
                } else {
                  // Traccar speed is in knots. Convert to km/h.
                  final speedInKnots = loadedState.traccarDevicePositions[loadedState.selectedDeviceId]?.speed;
                  if (speedInKnots != null && speedInKnots > 0) {
                    final speedInKmh = speedInKnots * 1.852;
                    speedText = '${speedInKmh.toStringAsFixed(1)} km/h';
                  }
                }

                return ActionBar(
                    onDrawerTap: () => Scaffold.of(context).openDrawer(),
                  onMessageTap: () => Navigator.pushNamed(context, RoutesName.conversationsScreen),
                  speedText: speedText,
                );
              },
            ),
            Expanded(
              child: BlocConsumer<MapBloc, MapState>(
                listener: (context, state) {
                  if (state is MapError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('An error occurred: ${state.message}'), backgroundColor: Colors.red),
                    );
                  } else if (state is TraccarDevicesLoaded) {
                    setState(() => _cachedDevices = state.devices);
                  } else if (state is DeleteTraccarDeviceLoaded) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.success ? 'Device deleted successfully.' : 'Failed to delete device.'),
                        backgroundColor: state.success ? Colors.green : Colors.red,
                      ),
                    );
                    if (state.success) {
                      context.read<MapBloc>().add(GetUserTraccarDevices());
                      context.read<MapBloc>().add(const TraccarDeviceSelected(null));
                    }
                  } else if (state is RouteReportLoaded) {
                    if (state.reports.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No ride history found for the selected period.')),
                      );
                    } else {
                      final points = state.reports.map((p) => LatLng(p.latitude!, p.longitude!)).toList();
                      _mapController.fitCamera(CameraFit.bounds(
                        bounds: LatLngBounds.fromPoints(points),
                        padding: const EdgeInsets.all(50),
                      ));
                    }
                  } else if (state is TraccarLogoutLoaded) {
                    if (state.success && mounted) {
                      Navigator.pushNamedAndRemoveUntil(context, RoutesName.loginScreen, (route) => false);
                    }
                  } else if (state is MapLoaded) {
                    final position = _getTargetPosition(state);
                    if (position != null && _isMapReady) {
                      _animateMapAndMarker(position);
                    }
                  }
                },
                builder: (context, state) {
                  if (state is MapInitial || state is MapLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is MapError && state.previousState == null) {
                    return Center(child: Text('Error: ${state.message}'));
                  }
                  return _buildMapContent(context, state);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapContent(BuildContext context, MapState state) {
    final loadedState = _getLoadedState(state);

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _getTargetPosition(loadedState) ?? const LatLng(24.5854, 73.7125),
            initialZoom: 15.0,
            maxZoom: 18.0,
            minZoom: 3.0,
            onPositionChanged: (camera, hasGesture) {
              if (hasGesture && _animationController.isAnimating) {
                _animationController.stop();
              }
            },
            onMapReady: () {
              if (mounted) {
                setState(() => _isMapReady = true);
                final initialPos = _getTargetPosition(loadedState);
                if (initialPos != null) {
                  _latLngTween = LatLngTween(begin: initialPos, end: initialPos);
                  _mapController.move(initialPos, 15.0);
                }
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png",
              retinaMode: RetinaMode.isHighDensity(context),
            ),
            if (state is RouteReportLoaded)
              _buildRoutePolyline(state.reports),
            _buildAnimatedMarker(loadedState),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: _buildTraccarDropDown(context, loadedState),
        ),
        if (!_isThisDevice)
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: AppColors.markerBg1,
              heroTag: 'details_fab',
              child: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => _showDeviceDetailsSheet(context, loadedState),
            ),
          ),
        if (state is RouteReportLoaded)
          Positioned(
            bottom: 90,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.redAccent,
              heroTag: 'clear_route_fab',
              child: const Icon(Icons.clear, color: Colors.white),
              onPressed: () {
                context.read<MapBloc>().add(TraccarDeviceSelected(loadedState.selectedDeviceId));
              },
            ),
          ),
        if (_isLoading(state))
          Container(
            color: Colors.black26,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  LatLng? _getTargetPosition(MapLoaded state) {
    if (state.selectedDeviceId == null) {
      final pos = state.currentDevicePosition;
      if (pos != null) {
        if (!_isThisDevice && mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) => setState(() => _isThisDevice = true));
        }
        return LatLng(pos.latitude, pos.longitude);
      }
    } else {
      final pos = state.traccarDevicePositions[state.selectedDeviceId] ?? state.traccarDeviceLastPosition;
      if (pos != null && pos.latitude != null && pos.longitude != null) {
        if (_isThisDevice && mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) => setState(() => _isThisDevice = false));
        }
        return LatLng(pos.latitude!, pos.longitude!);
      }
    }
    return null;
  }

  void _animateMapAndMarker(LatLng newPosition) {
    if (_latLngTween.end == newPosition) return;
    _latLngTween.begin = _latLngTween.evaluate(_animation);
    _latLngTween.end = newPosition;
    _animationController.reset();
    _animationController.forward();
  }

  Widget _buildAnimatedMarker(MapLoaded state) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final currentLatLng = _latLngTween.evaluate(_animation);
        if (currentLatLng.latitude == 0 && currentLatLng.longitude == 0) {
          return const SizedBox.shrink();
        }
        return MarkerLayer(
          markers: [
            Marker(
              width: 80,
              height: 80,
              point: currentLatLng,
              child: MapHeadingMarker(
                heading: _heading,
                color: _isThisDevice ? AppColors.markerBg1 : Colors.green,
                isThisDevice: _isThisDevice,
              ),
            ),
          ],
        );
      },
    );
  }

  PolylineLayer _buildRoutePolyline(List<RouteReport> reports) {
    final points = reports
        .where((p) => p.latitude != null && p.longitude != null)
        .map((p) => LatLng(p.latitude!, p.longitude!))
        .toList();
    return PolylineLayer(
      polylines: [
        Polyline(points: points, strokeWidth: 4.0, color: Colors.blue),
      ],
    );
  }

  Widget _buildTraccarDropDown(BuildContext context, MapLoaded loadedState) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dropdownWidth = screenWidth * 0.5;
    final devices = _cachedDevices;
    final selectedDeviceId = loadedState.selectedDeviceId;
    final deviceIdToName = {
      null: 'This Device',
      for (var device in devices)
        if (device.id != null && device.name != null) device.id!: "${device.name} (${device.status ?? '...'})",
    };
    final availableDeviceIds = deviceIdToName.keys.toList();
    final finalSelectedDeviceId = availableDeviceIds.contains(selectedDeviceId) ? selectedDeviceId : null;
    return Align(
      alignment: Alignment.topLeft,
      child: Container(
        width: dropdownWidth,
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int?>(
            value: finalSelectedDeviceId,
            isExpanded: true,
            menuWidth: dropdownWidth,
            dropdownColor: Colors.black.withOpacity(0.85),
            style: const TextStyle(color: Colors.white, fontSize: 16.0),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            onChanged: (id) {
              context.read<MapBloc>().add(TraccarDeviceSelected(id));

            },
            items: deviceIdToName.entries.map((entry) {
              return DropdownMenuItem<int?>(
                value: entry.key,
                child: Row(
                  children: [
                    Expanded(child: Text(entry.value, overflow: TextOverflow.ellipsis)),
                    if (entry.key != null)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                        onPressed: () {
                          Navigator.pop(context);
                          showDialog(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: Text("Delete '${entry.value}'?"),
                              content: const Text("This action cannot be undone."),
                              actions: [
                                TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text("Cancel")),
                                TextButton(
                                  child: const Text("Delete", style: TextStyle(color: Colors.red)),
                                  onPressed: () {
                                    context.read<MapBloc>().add(DeleteTraccarDevice(entry.key!));
                                    Navigator.of(dialogContext).pop();
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Future<void> _showRideHistoryPicker(BuildContext context, MapLoaded state) async {
    final now = DateTime.now();
    final dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: DateTimeRange(start: now.subtract(const Duration(days: 1)), end: now),
    );
    if (dateRange != null && state.selectedDeviceId != null && mounted) {
      Navigator.of(context).pop();
      context.read<MapBloc>().add(GetTraccarRouteReport(
        state.selectedDeviceId!,
        dateRange.start.toUtc().toIso8601String(),
        dateRange.end.toUtc().toIso8601String(),
      ));
    }
  }

  void _showDeviceDetailsSheet(BuildContext context, MapLoaded state) {
    final pos = state.traccarDevicePositions[state.selectedDeviceId] ?? state.traccarDeviceLastPosition;
    final totalDistance = (pos?.attributes?['totalDistance'] as num? ?? 0.0) / 1000;
    final topSpeed = (pos?.attributes?['topSpeed'] as num? ?? 0.0);
    final deviceName = _cachedDevices.firstWhere((d) => d.id == state.selectedDeviceId, orElse: () => Device()).name;
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
                  IconButton(icon: const Icon(Icons.precision_manufacturing_rounded, color: Colors.blueAccent, size: 28), onPressed: () {}),
                ],
              ),
              const Divider(color: Colors.white24, height: 30),
              _buildDetailRow(context, icon: Icons.route, label: "Total Km", value: "${totalDistance.toStringAsFixed(2)} km"),
              _buildDetailRow(context, icon: Icons.speed_rounded, label: "Top Speed", value: "${topSpeed.toStringAsFixed(2)} km/h"),
              _buildDetailRow(context, icon: Icons.av_timer_rounded, label: "Avg Speed", value: "N/A"),
              const Divider(color: Colors.white24, height: 30),
              _buildActionRow(context, icon: Icons.history_rounded, label: "Ride History", onTap: () {
                Navigator.of(context).popAndPushNamed(RoutesName.traccarDevicesSummaryScreen, arguments: {
                  "deviceId":state.selectedDeviceId.toString()
                });
              }),
              _buildActionRow(context, icon: Icons.fence_rounded, label: "Geofences", onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(RoutesName.geoFenceScreen, arguments: {
                  "position": state.currentDevicePosition,
                  "deviceId": state.selectedDeviceId,
                    }
                  );
                }
              ),
              _buildActionRow(context, icon: Icons.notification_add, label: "Notification Settings", onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(RoutesName.traccarNotificationSettingsScreen);
              }
              ),
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

  drawerHeader() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // User logo
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SvgPicture.asset(
              "assets/images/logo_user.svg",
              height: 60,
              width: 60,
            ),
          ),

          // Spacer between logo and details
          const SizedBox(width: 20),

          // User details and edit icon
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row for edit icon on the right
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top:1.0),
                      child: const SizedBox(width: 1),
                    ), // just for spacing on left if needed
                    Padding(
                      padding: const EdgeInsets.only(right: 10.0),
                      child: SvgPicture.asset(
                        "assets/images/logo_edit.svg",
                        height: 25,
                        width: 25,
                      ),
                    ),
                  ],
                ),

                // User name
                Text(
                  "demo",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                // Email
                SizedBox(height: 2,),
                Text(
                  "nithik@nithi.com",
                  style: const TextStyle(fontSize: 12),

                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  drawerContent( ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        drawerItem("My Devices", "assets/images/logo_track.svg", () => Navigator.of(context).popAndPushNamed(RoutesName.traccarDevicesScreen)),
        drawerItem("Notification Settings", "assets/images/logo_notification.svg", () => Navigator.of(context).popAndPushNamed(RoutesName.traccarNotificationSettingsScreen)),
        drawerItem("Change Password", "assets/images/logo_padLock.svg", () {}),
        drawerItem("Terms and Conditions", "assets/images/logo_document.svg", () {}),
        drawerItem("Privacy Policy", "assets/images/logo_document.svg", () {}),
        drawerItem("Logout", "assets/images/logo_logout.svg", () async {
          await SessionManager.instance.clearSession();
          if (context.mounted) { // Check if the widget is still mounted before navigation
            Navigator.pushNamedAndRemoveUntil(
              context,
              RoutesName.loginScreen,
                  (route) => false,
            );
          }
        }),


      ]
    );
  }


  drawerItem(String titleText, String assetPath,VoidCallback onTap ){
    return         //Device Notification Settings
      GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Container(

            width: MediaQuery.of(context).size.width * 0.5,
            child: Row(
              children: [
                // Drawer Item Logo
                SvgPicture.asset(assetPath, height: 20,width: 20,color: Colors.white,),

                SizedBox(width: 15,),
                // Drawer Item Title
                Text(titleText, style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),)
              ],
            ),
          ),
        ),
      );
  }
}