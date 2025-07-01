import 'dart:convert';

import 'package:bikerr/core/theme.dart';
import 'package:bikerr/utils/widgets/buttons/back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../bloc/map_bloc.dart';

class GeoFenceScreen extends StatefulWidget {
  final position;
  final deviceId;

  const GeoFenceScreen({super.key, required this.position,required this.deviceId});

  @override
  State<GeoFenceScreen> createState() => _GeoFenceScreenState();
}

class _GeoFenceScreenState extends State<GeoFenceScreen> {
  LatLng? _markerLocation; // Stores the location of the pinned marker.
  double _geofenceRadius = 50.0; // Initial geofence radius in meters.
  // Lists to store markers and circles to be displayed on the map.
  List<Marker> _markers = [];
  List<CircleMarker> _circles = [];

  // Initial camera position for the map (e.g., a default city).
  static const LatLng _initialCenter = LatLng(24.5854, 73.7125); // Coordinates for Udaipur, Rajasthan, India.
  static const double _initialZoom = 12.0;

  @override
  void initState() {
    context.read<MapBloc>().add(GetTraccarGeofencesByDeviceId(widget.deviceId));
    super.initState();
    // No initial marker or circle, user will tap to pin.
  }

  // Function to handle map taps and place a marker.
  void _onMapTapped(TapPosition tapPosition, LatLng latLng) {
    setState(() {
      _markerLocation = latLng; // Update marker location.
      _updateMapElements(); // Update markers and circles on the map.
    });
  }

  // Function to update the markers and circles lists based on _markerLocation and _geofenceRadius.
  void _updateMapElements() {
    _markers.clear(); // Clear existing markers.
    _circles.clear(); // Clear existing circles.

    if (_markerLocation != null) {
      // Add the pinned marker.
      _markers.add(
        Marker(
          point: _markerLocation!,
          width: 80,
          height: 80,
          child:  const Icon(
            Icons.location_pin,
            color: Colors.red,
            size: 40.0,
          ),
          // You can add a tooltip for information on tap if desired.
          // Or use a custom GestureDetector for more complex info window.
        ),
      );

      // Add the geofence circle.
      _circles.add(
        CircleMarker(
          point: _markerLocation!,
          radius: _geofenceRadius, // Radius from the slider.
        //  use  : false, // Do not use meter conversion for radius (it's already in meters).
          color: Colors.blue.withOpacity(0.2), // Semi-transparent blue fill.
          borderColor: Colors.blue, // Blue border.
          borderStrokeWidth: 2,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      // appBar: AppBar(
      //   title: const Text('Circular Geofence Map'),
      //   centerTitle: true,
      //   elevation: 0,
      //   backgroundColor: Colors.transparent, // Custom app bar color.
      //   shape: const RoundedRectangleBorder(
      //     borderRadius: BorderRadius.vertical(
      //       bottom: Radius.circular(15),
      //     ),
      //   ),
      // ),
      body: Stack(
        children: [

          // FlutterMap widget occupying the entire body.
          FlutterMap(
            options: MapOptions(
              initialCenter: _markerLocation ?? _initialCenter, // Center on marker if present, else initial.
              initialZoom: _initialZoom,
              onTap: _onMapTapped, // Handle map taps.
              maxZoom: 18.0, // Define max zoom for tiles.
              minZoom: 2.0,  // Define min zoom for tiles.
            ),
            children: [
              // Tile Layer for map tiles (OpenStreetMap is commonly used).
              TileLayer(
                urlTemplate: 'http://mt0.google.com/vt/lyrs=m&hl=en&x={x}&y={y}&z={z}',
              ),
              // Marker Layer to display markers.
              MarkerLayer(
                markers: _markers,
              ),
              // Circle Layer to display geofence circles.
              CircleLayer(
                circles: _circles,
              ),
            ],
          ),
          // Geofence radius slider, positioned at the bottom.
          if (_markerLocation != null) // Only show slider if a marker is pinned.
            Positioned(
              top: 100.0,
              left: 20.0,
              right: 20.0,
              child: Card(

                elevation: 8,
                color: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),

                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Geofence Radius: ${_geofenceRadius.toStringAsFixed(0)} meters',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Slider(
                        thumbColor: AppColors.bikerrRedFill ,
                        activeColor: AppColors.markerBg1,
                        secondaryActiveColor: Colors.transparent,
                        value: _geofenceRadius,
                        min: 10.0, // Minimum radius (e.g., 100 meters).
                        max: 500.0, // Maximum radius (e.g., 5 kilometers).
                        divisions: 100, // (Max - Min) / 100 + 1 => 49 divisions for 100m steps
                        label: '${_geofenceRadius.toStringAsFixed(0)}m',
                        onChanged: (newValue) {
                          setState(() {
                            _geofenceRadius = newValue; // Update radius.
                            _updateMapElements(); // Redraw circle.
                          });
                        },
                      ),
                      // const Text(
                      //   'Tap on the map to pin a location and set a geofence.',
                      //   style: TextStyle(fontSize: 12, color: Colors.grey),
                      //   textAlign: TextAlign.center,
                      // ),
                    ],
                  ),
                ),
              ),
            ),



          if (_markerLocation != null) // Only show Button if a marker is pinned.
            Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.5,
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  color: AppColors.bgColor,
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (dialogContext) {
                        final TextEditingController _nameController = TextEditingController();
                        final TextEditingController _descController = TextEditingController();
                        return AlertDialog(
                          title: const Text('Add Geofence Details'),
                          content: SingleChildScrollView(
                            child: Column(
                              children: [
                                TextField(
                                  controller: _nameController,
                                  decoration: const InputDecoration(labelText: 'Name'),
                                ),
                                TextField(
                                  controller: _descController,
                                  decoration: const InputDecoration(labelText: 'Description'),
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(dialogContext);
                              },
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                final name = _nameController.text.trim();
                                final desc = _descController.text.trim();

                                if (name.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Name is required.')),
                                  );
                                  return;
                                }

                                final area = 'CIRCLE (${_markerLocation!.latitude} ${_markerLocation!.longitude}, $_geofenceRadius)';


                                final geofenceJson = {

                                  "name": name,
                                  "description": desc,
                                  "area": area,

                                };

                                context.read<MapBloc>().add(AddTraccarGeofence(jsonEncode(geofenceJson), widget.deviceId.toString()));

                                Navigator.pop(dialogContext);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Geofence creation requested.')),
                                );
                              },
                              child: const Text('Add'),
                            ),
                          ],
                        );
                      },
                    );
                  },


                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Add",
                        style: TextStyle(
                          color: AppColors.bikerrRedFill,
                        ),
                      ),
                      Icon(Icons.add, color: AppColors.bikerrRedFill),
                    ],
                  ),
                ),
              ),
            ),
          ),



          Positioned(
              top: 40,
              left: 20,

              child: Container(
                padding: const EdgeInsets.all(9,),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  color: AppColors.bgColor, // Background color for the container
                ),
                alignment: Alignment.center, // Aligns its child (BackButtonComponent) to the center
                child: BackButtonComponent(),
              )),
        ],
      ),
    );
  }
}