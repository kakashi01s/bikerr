import 'dart:async';

import 'package:bikerr/config/constants.dart';
import 'package:bikerr/config/routes/route_names.dart';
import 'package:bikerr/core/theme.dart';
import 'package:bikerr/features/map/domain/usecases/get_current_location_usecase.dart';
import 'package:bikerr/features/map/presentation/bloc/map_bloc.dart';
import 'package:bikerr/features/map/presentation/widgets/action_bar.dart';
import 'package:bikerr/features/map/presentation/widgets/app_bar.dart';
import 'package:bikerr/services/session/session_manager.dart';
import 'package:bikerr/utils/di/service_locator.dart';
import 'package:bikerr/utils/enums/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:traccar_flutter/traccar_flutter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _traccarFlutterPlugin = TraccarFlutter();
  final Completer<GoogleMapController> _controller = Completer();
  final SessionManager sessionManager = SessionManager.instance;

  late final MapBloc _mapBloc;
  Set<Marker> _markers = {};
  LatLng? _lastPosition;
  BitmapDescriptor? _customIcon;
  bool isServiceStarted = false;
  String? traccingMessage;

  @override
  void initState() {
    super.initState();
    _mapBloc = MapBloc(
      getCurrentLocationUsecase: sl<GetCurrentLocationUsecase>(),
    );
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadCustomMarker();
    // await _initTraccar();
    await _handleLocationPermission();
  }

  Future<void> _loadCustomMarker() async {
    _customIcon = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(48, 48)),
      AppLogos.mapMarker,
    );
  }

  // Future<void> _initTraccar() async {
  //   traccingMessage = await _traccarFlutterPlugin.initTraccar();
  //   traccingMessage = await _traccarFlutterPlugin.setConfigs(
  //     TraccarConfigs(
  //       interval: 10000,
  //       distance: 10,
  //       deviceId: '1241',
  //       serverUrl: 'http://13.60.88.192:8082',
  //       notificationIcon: 'ic_notification',
  //       wakelock: true,
  //     ),
  //   );
  //   setState(() {});
  // }

  Future<void> _handleLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      await _getLastAndStartLocation();
    } else {
      final requested = await Geolocator.requestPermission();
      if (requested == LocationPermission.always ||
          requested == LocationPermission.whileInUse) {
        await _getLastAndStartLocation();
      } else {
        _showSnackBar("Location permission not granted.");
      }
    }
  }

  Future<void> _getLastAndStartLocation() async {
    final lastPosition = await Geolocator.getLastKnownPosition(
      forceAndroidLocationManager: true,
    );
    if (lastPosition != null) _updateLocation(lastPosition);
    _mapBloc.add(GetInitialLocation());
  }

  Future<void> _updateLocation(Position position) async {
    final newLatLng = LatLng(position.latitude, position.longitude);
    _lastPosition = newLatLng;

    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('user_location'),
          position: newLatLng,
          icon:
              _customIcon ??
              BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueMagenta,
              ),
        ),
      };
    });

    if (_controller.isCompleted) {
      final controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newLatLng(newLatLng));
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _mapBloc.add(StopLocationTracking());
    super.dispose();
  }

  Future<void> _toggleService() async {
    try {
      final result =
          isServiceStarted
              ? await _traccarFlutterPlugin.stopService()
              : await _traccarFlutterPlugin.startService();

      setState(() {
        traccingMessage = result;
        isServiceStarted = !isServiceStarted;
      });
    } catch (e) {
      setState(() {
        traccingMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 16.0, right: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FloatingActionButton(
                heroTag: "btn1",
                backgroundColor: Colors.white,
                onPressed: () {
                  // _toggleService();
                },
                child: Icon(isServiceStarted ? Icons.stop : Icons.play_arrow),
              ),
            ],
          ),
        ),
        body: BlocProvider.value(
          value: _mapBloc,
          child: BlocListener<MapBloc, MapState>(
            listener: (context, state) {
              if (state.position != null) _updateLocation(state.position!);

              switch (state.postApiStatus) {
                case PostApiStatus.error:
                  _showSnackBar("Error: ${state.errorMessage}");
                  break;
                case PostApiStatus.locationServiceDisabled:
                  _showSnackBar("Location services are disabled.");
                  break;
                case PostApiStatus.permissionDenied:
                  _showSnackBar("Location permission denied.");
                  break;
                case PostApiStatus.permissionDeniedForever:
                  _showSnackBar("Location permission denied permanently.");
                  break;
                default:
                  break;
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CustomAppBar(),
                ActionBar(
                  onMessageTap: () {
                    Navigator.pushNamed(
                      context,
                      RoutesName.conversationsScreen,
                    );
                  },
                ),
                Expanded(
                  child: Stack(
                    children: [
                      // GoogleMap(
                      //   mapType: MapType.normal,
                      //   initialCameraPosition: CameraPosition(
                      //     target:
                      //         _lastPosition ?? const LatLng(20.5937, 78.9629),
                      //     zoom: 20,
                      //     tilt: 30.0,
                      //   ),
                      //   zoomControlsEnabled: false,
                      //   compassEnabled: false,
                      //   buildingsEnabled: false,
                      //   myLocationEnabled: false,
                      //   myLocationButtonEnabled: false,

                      //   onMapCreated: (controller) {
                      //     if (!_controller.isCompleted)
                      //       _controller.complete(controller);
                      //   },
                      //   markers: _markers,
                      // ),
                      BlocBuilder<MapBloc, MapState>(
                        builder: (context, state) {
                          return state.postApiStatus == PostApiStatus.loading
                              ? const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.bikerrRedFill,
                                ),
                              )
                              : const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
