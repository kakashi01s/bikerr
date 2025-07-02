import 'dart:convert';

import 'package:bikerr/core/theme.dart';
import 'package:bikerr/utils/widgets/buttons/back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_sliding_toast/flutter_sliding_toast.dart';
import 'package:latlong2/latlong.dart';
import 'package:traccar_gennissi/traccar_gennissi.dart';

import '../bloc/map_bloc.dart';

class GeoFenceScreen extends StatefulWidget {
  final position;
  final int deviceId;

  const GeoFenceScreen({super.key, required this.position, required this.deviceId});

  @override
  State<GeoFenceScreen> createState() => _GeoFenceScreenState();
}

class _GeoFenceScreenState extends State<GeoFenceScreen> {
  // --- State Variables ---

  bool _isCreatingGeofence = false;

  LatLng? _markerLocation;
  double _geofenceRadius = 50.0;
  final List<Marker> _newGeofenceMarkers = [];
  final List<CircleMarker> _newGeofenceCircles = [];

  final List<Marker> _existingGeofenceMarkers = [];
  final List<CircleMarker> _existingGeofenceCircles = [];
  int? _selectedGeofenceId;

  static const LatLng _initialCenter = LatLng(24.5854, 73.7125);
  static const double _initialZoom = 12.0;

  @override
  void initState() {
    super.initState();
    context.read<MapBloc>().add(GetTraccarGeofencesByDeviceId(widget.deviceId));
  }

  // --- Geofence Parsing and Drawing Logic ---

  Map<String, double?> _parseGeofenceArea(String area) {
    try {
      final cleanedArea = area.replaceAll('CIRCLE (', '').replaceAll(')', '');
      final parts = cleanedArea.split(',');
      final latLon = parts[0].split(' ');
      return {
        'lat': double.tryParse(latLon[0]),
        'lon': double.tryParse(latLon[1]),
        'radius': double.tryParse(parts[1].trim())
      };
    } catch (e) {
      return {'lat': null, 'lon': null, 'radius': null};
    }
  }

  void _updateExistingGeofencesOnMap(List<GeofenceModel> geofences) {
    _existingGeofenceMarkers.clear();
    _existingGeofenceCircles.clear();

    for (var geofence in geofences) {
      final parsedArea = _parseGeofenceArea(geofence.area ?? '');
      final lat = parsedArea['lat'];
      final lon = parsedArea['lon'];
      final radius = parsedArea['radius'];

      if (lat != null && lon != null && radius != null) {
        final center = LatLng(lat, lon);
        final isSelected = geofence.id == _selectedGeofenceId;

        _existingGeofenceCircles.add(
          CircleMarker(
            point: center,
            radius: radius,
            color: isSelected ? Colors.orange.withOpacity(0.4) : Colors.green.withOpacity(0.3),
            borderColor: isSelected ? Colors.orange : Colors.green,
            borderStrokeWidth: isSelected ? 3 : 2,
          ),
        );
        _existingGeofenceMarkers.add(
          Marker(
            point: center,
            width: 150,
            height: 50,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isCreatingGeofence = false;
                  if (_selectedGeofenceId == geofence.id) {
                    _selectedGeofenceId = null;
                  } else {
                    _selectedGeofenceId = geofence.id;
                  }
                });
              },
              child: Align(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(10),
                    border: isSelected ? Border.all(color: Colors.orange, width: 2) : null,
                  ),
                  child: Text(
                    geofence.name ?? 'Geofence',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }
    setState(() {});
  }

  // --- Event Handlers ---

  void _onMapTapped(TapPosition tapPosition, LatLng latLng) {
    setState(() {
      _isCreatingGeofence = true;
      _selectedGeofenceId = null;
      _markerLocation = latLng;
      _updateNewGeofenceElements();
    });
  }

  void _updateNewGeofenceElements() {
    _newGeofenceMarkers.clear();
    _newGeofenceCircles.clear();
    if (_markerLocation != null) {
      _newGeofenceMarkers.add(
        Marker(
          point: _markerLocation!,
          width: 80,
          height: 80,
          child: const Icon(Icons.location_pin, color: Colors.red, size: 40.0),
        ),
      );
      _newGeofenceCircles.add(
        CircleMarker(
          point: _markerLocation!,
          radius: _geofenceRadius,
          color: Colors.blue.withOpacity(0.2),
          borderColor: Colors.blue,
          borderStrokeWidth: 2,
        ),
      );
    }
  }

  void _cancelCreation() {
    setState(() {
      _isCreatingGeofence = false;
      _markerLocation = null;
      _updateNewGeofenceElements();
    });
  }

  void _confirmAndDeleteGeofence() {
    if (_selectedGeofenceId == null) return;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Geofence?'),
        content: const Text('Are you sure you want to delete this geofence?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<MapBloc>().add(DeleteTraccarGeofence(_selectedGeofenceId!.toString()));
              Navigator.of(context).pop();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- Build Method ---

  @override
  Widget build(BuildContext context) {
    final showDeleteButton = _selectedGeofenceId != null && !_isCreatingGeofence;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocListener<MapBloc, MapState>(
        listener: (context, state) {
          if (state is GeofencesLoaded) {
            _updateExistingGeofencesOnMap(state.geofences);
          } else if (state is DeleteTraccarGeofenceLoaded && state.success) {
            InteractiveToast.slide(

              context: context,
              //leading: _leadingWidget(),
              title: Center(
                child: const Text(
                  "Geo Fence Deleted",
                  style: TextStyle(
                    color: AppColors.bikerrRedFill,
                    fontSize: 5
                  ),
                ),
              ),
             // trailing: _trailingWidget(),
              toastStyle: const ToastStyle(titleLeadingGap: 10, backgroundColor: Colors.transparent),
              toastSetting:const SlidingToastSetting(
                animationDuration: Duration(seconds: 1),
                displayDuration: Duration(seconds: 2),
                toastStartPosition: ToastPosition.top,
                toastAlignment: Alignment.topCenter,
              ),
            );
            setState(() => _selectedGeofenceId = null);
            context.read<MapBloc>().add(GetTraccarGeofencesByDeviceId(widget.deviceId));
          } else if (state is MapError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${state.message}'), backgroundColor: Colors.red),
            );
          }
        },
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: _markerLocation ?? _initialCenter,
                initialZoom: _initialZoom,
                onTap: _onMapTapped,
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png",

                  retinaMode: RetinaMode.isHighDensity(context),                ),
                if (!_isCreatingGeofence) ...[
                  CircleLayer(circles: _existingGeofenceCircles),
                  MarkerLayer(markers: _existingGeofenceMarkers),
                ],
                if (_isCreatingGeofence) ...[
                  CircleLayer(circles: _newGeofenceCircles),
                  MarkerLayer(markers: _newGeofenceMarkers),
                ]
              ],
            ),
            if (_isCreatingGeofence) ...[
              Positioned(
                top: 100.0,
                left: 20.0,
                right: 20.0,
                child: Card(
                  elevation: 8,
                  color: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Adjust Your Geofence',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.bikerrbgColor),
                        ),

                        Slider(
                          secondaryActiveColor: Colors.transparent,


                          thumbColor: AppColors.bikerrRedFill,
                          activeColor: AppColors.markerBg1,
                          value: _geofenceRadius,
                          min: 10.0,
                          max: 500.0,
                          divisions: 49,
                          label: '${_geofenceRadius.toStringAsFixed(0)}m',
                          onChanged: (newValue) {
                            setState(() {
                              _geofenceRadius = newValue;
                              _updateNewGeofenceElements();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 30,
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.grey[700],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      onPressed: _cancelCreation,
                      icon: const Icon(Icons.clear),
                      label: const Text("Cancel"),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.bikerrRedFill,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text("Add"),
                      // ** RESTORED FUNCTIONALITY **
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (dialogContext) {
                            final TextEditingController nameController = TextEditingController();
                            final TextEditingController descController = TextEditingController();
                            return AlertDialog(
                              title: const Text('Add Geofence Details'),
                              content: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextField(
                                      controller: nameController,
                                      decoration: const InputDecoration(labelText: 'Name'),
                                    ),
                                    TextField(
                                      controller: descController,
                                      decoration: const InputDecoration(labelText: 'Description'),
                                    ),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    final name = nameController.text.trim();
                                    final desc = descController.text.trim();

                                    if (name.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Name is required.')),
                                      );
                                      return;
                                    }

                                    final area = 'CIRCLE (${_markerLocation!.latitude} ${_markerLocation!.longitude}, $_geofenceRadius)';

                                    final GeofenceModel geofenceJson = GeofenceModel();
                                    geofenceJson.id= -1;
                                    geofenceJson.name = name;
                                    geofenceJson.description = desc;
                                    geofenceJson.area = area;
                                    geofenceJson.calendarId=0;

                                    context.read<MapBloc>().add(AddTraccarGeofence(jsonEncode(geofenceJson), widget.deviceId.toString()));

                                    Navigator.pop(dialogContext);

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Geofence creation requested.')),
                                    );

                                    _cancelCreation(); // Exit creation mode
                                  },
                                  child: const Text('Add'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
            if (showDeleteButton)
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Center(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    onPressed: _confirmAndDeleteGeofence,
                    icon: const Icon(Icons.delete_forever),
                    label: const Text("Delete Geofence"),
                  ),
                ),
              ),
            Positioned(
              top: 40,
              left: 20,
              child: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  color: AppColors.bgColor,
                ),
                child: const BackButtonComponent(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}