import 'package:bikerr/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:traccar_gennissi/traccar_gennissi.dart';

class TraccarSummaryPlaybackScreen extends StatefulWidget {
  final List<PositionModel> positions; // Pass your sorted positions list here
  const TraccarSummaryPlaybackScreen({Key? key, required this.positions}) : super(key: key);

  @override
  State<TraccarSummaryPlaybackScreen> createState() => _TraccarSummaryPlaybackScreenState();
}

class _TraccarSummaryPlaybackScreenState extends State<TraccarSummaryPlaybackScreen> {
  late final List<LatLng> routePoints;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Extract LatLng points from positions, ensure sorted by time ascending
    widget.positions.sort((a, b) => a.deviceTime!.compareTo(b.deviceTime!));
    routePoints = widget.positions
        .map((p) => LatLng(p.latitude!, p.longitude!))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final currentPos = routePoints[currentIndex];
    final currentTime = widget.positions[currentIndex].deviceTime;
    final formattedTime = currentTime != null
        ? DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.parse(currentTime).toLocal())
        : 'Unknown time';

    return Scaffold(
      appBar: AppBar(title: const Text("Route Map")),
      body: Stack(
    children: [
    FlutterMap(
    options: MapOptions(
      initialCenter: currentPos,
      initialZoom: 15,
    ),
    children: [
    TileLayer(
    urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
    subdomains: ['a', 'b', 'c'],
    ),
    PolylineLayer(
    polylines: [
    Polyline(
    points: routePoints,
    strokeWidth: 4.0,
    color: Colors.black,
    ),
    ],
    ),
    MarkerLayer(
    markers: [
    Marker(
    width: 40,
    height: 40,
    point: currentPos,
    child: const Icon(Icons.location_on, color: Colors.red, size: 40),
    ),
    ],
    ),
    ],
    ),

    // Floating slider overlay
    Positioned(
    left: 16,
    right: 16,
    bottom: 30,
    child: Card(
    elevation: 6,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    color: Colors.black.withOpacity(0.9),
    child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
    Text(
    formattedTime,
    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
    ),
    Slider(
    thumbColor: Colors.red,
    activeColor: AppColors.whiteText.withAlpha(8),
    value: currentIndex.toDouble(),
    min: 0,
    max: (routePoints.length - 1).toDouble(),
    divisions: routePoints.length - 1,
    label: '$currentIndex',
    onChanged: (val) {
    setState(() {
    currentIndex = val.round();
    });
    },
    ),
    ],
    ),
    ),
    ),
    ),
    ],
    ),

    );
  }
}