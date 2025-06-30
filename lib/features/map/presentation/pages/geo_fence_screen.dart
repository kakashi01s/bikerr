import 'package:bikerr/utils/widgets/buttons/back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class GeoFenceScreen extends StatelessWidget {
  final position;
  const GeoFenceScreen({super.key, required this.position});

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: BackButtonComponent(),
      ),
      body: FlutterMap(

        options: MapOptions(
          initialCenter: LatLng(position.latitude, position.longitude),
          initialZoom: 15.0,
          maxZoom: 18.0,
          minZoom: 3.0,


        ),
        children: [
          TileLayer(urlTemplate: 'http://mt0.google.com/vt/lyrs=m&hl=en&x={x}&y={y}&z={z}'),

        ],
      ),
    );
  }
}
