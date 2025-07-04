import 'package:bikerr/config/routes/route_names.dart';
import 'package:bikerr/core/theme.dart';
import 'package:bikerr/features/map/presentation/bloc/map_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:traccar_gennissi/traccar_gennissi.dart';

class TraccarDeviceSummaryScreen extends StatefulWidget {
  final String deviceId;
  const TraccarDeviceSummaryScreen({super.key, required this.deviceId, });

  @override
  State<TraccarDeviceSummaryScreen> createState() => _TraccarDeviceSummaryScreenState();
}


class _TraccarDeviceSummaryScreenState extends State<TraccarDeviceSummaryScreen> {
  final ScrollController _scrollController = ScrollController();
  int _daysToShow = 7; // initial days to show

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    final now = DateTime.now().toUtc();
    final toDate = DateTime.utc(now.year, now.month, now.day, 23, 59, 59, 999);
    final fromDateRaw = now.subtract(Duration(days: 30));
    final fromDate = DateTime.utc(fromDateRaw.year, fromDateRaw.month, fromDateRaw.day, 0, 0, 0, 0);

    context.read<MapBloc>().add(
      GetTraccarSummaryReport(
        widget.deviceId,
        fromDate.toIso8601String(),
        toDate.toIso8601String(),
      ),
    );  }


  Map<String, List<PositionModel>> groupPositionsByDay(List<PositionModel> positions) {
    final Map<String, List<PositionModel>> grouped = {};
    for (final pos in positions) {
      final dt = pos.deviceTime != null ? DateTime.tryParse(pos.deviceTime!)?.toLocal() : null;
      if (dt == null) continue;

      final dayKey = DateFormat('yyyy-MM-dd').format(dt);
      grouped.putIfAbsent(dayKey, () => []);
      grouped[dayKey]!.add(pos);
    }
    return grouped;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reports"),
      ),
      body: BlocBuilder<MapBloc, MapState>(
        buildWhen: (previous, current) {
          // Only rebuild if state is one of these
          return current is SummaryReportLoaded ||
              current is ReportLoading ||
              current is MapError;
        },
        builder: (context, state) {
          if (state is SummaryReportLoaded) {
            final groupedData = groupPositionsByDay(state.summary ?? []);
            final sortedDates = groupedData.keys.toList()
              ..sort((a, b) => b.compareTo(a));

            final visibleDays = sortedDates.take(_daysToShow).toList();

            return ListView.builder(
              controller: _scrollController,
              itemCount: visibleDays.length + 1, // extra for loading indicator
              itemBuilder: (context, index) {
                if (index == visibleDays.length) {
                  // Show loading at bottom if more data available
                  return _daysToShow < sortedDates.length
                      ? Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                      : SizedBox.shrink();
                }
                final day = visibleDays[index];
                final positions = groupedData[day]!;

                return Card(
                  color: AppColors.markerBg1,
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  elevation: 3,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        RoutesName.traccarSummaryPlaybackScreen,
                        arguments: {'positions': positions},
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        SizedBox(

                          height: 200,
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: positions.isNotEmpty
                                  ? LatLng(positions[0].latitude ?? 0, positions[0].longitude ?? 0)
                                  : LatLng(0, 0),
                              initialZoom: 13,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                               // subdomains: const ['a', 'b', 'c'],
                               // userAgentPackageName: 'com.example.app',
                              ),
                              MarkerLayer(
                                markers: positions.map((pos) {
                                  final lat = pos.latitude ?? 0;
                                  final lng = pos.longitude ?? 0;
                                  return Marker(
                                    width: 8,
                                    height: 8,
                                    point: LatLng(lat, lng),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              if (positions.length > 1)
                                PolylineLayer(
                                  polylines: [
                                    Polyline(
                                      points: positions
                                          .map((pos) => LatLng(pos.latitude ?? 0, pos.longitude ?? 0))
                                          .toList(),
                                      color: Colors.blue.withOpacity(0.7),
                                      strokeWidth: 3,
                                    )
                                  ],
                                ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              Text(DateFormat('EEEE, MMM d, yyyy').format(DateTime.parse(day)), style: TextStyle(fontSize: 15),),
                              SizedBox(width: 10,),
                              Text('${positions.length} positions',style: TextStyle(fontSize: 15),),

                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          } else if (state is ReportLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is MapError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          // For other states, show something or just empty container
          return const SizedBox.shrink();
        },
      ),

    );
  }
}
