import 'dart:convert';

import 'package:bikerr/core/theme.dart';
import 'package:bikerr/features/map/presentation/widgets/app_bar.dart';
import 'package:bikerr/utils/widgets/buttons/app_button.dart';
import 'package:bikerr/utils/widgets/common/text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:traccar_gennissi/traccar_gennissi.dart';

import '../bloc/map_bloc.dart';

class TraccarDevicesScreen extends StatefulWidget {
  const TraccarDevicesScreen({super.key});

  @override
  State<TraccarDevicesScreen> createState() => _TraccarDevicesScreenState();
}

class _TraccarDevicesScreenState extends State<TraccarDevicesScreen> {

  List<Device> _deviceList = [];


  bool _isLoading = true;

  late TextEditingController vehicleNameController;
  late TextEditingController imeiController;

  @override
  void initState() {
    super.initState();
    vehicleNameController = TextEditingController();
    imeiController = TextEditingController();
    context.read<MapBloc>().add(GetUserTraccarDevices());
  }

  @override
  void dispose() {
    vehicleNameController.dispose();
    imeiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
      // CustomAppBar(),

      AppBar(
        title: const Text("Traccar Devices"),
        backgroundColor: const Color(0xFF2E2E32),
      ),
      body: BlocListener<MapBloc, MapState>(
        // Only listen to state changes relevant to this screen
        listenWhen: (previous, current) {
          return current is DeleteTraccarDeviceLoading ||
              current is DeleteTraccarDeviceLoaded ||
              current is AddTraccarDeviceLoading ||
              current is AddTraccarDeviceLoaded ||
              current is TraccarDevicesLoaded ||
              current is MapError;
        },
        listener: (context, state) {
          if(state is TraccarDevicesLoaded){
            setState(() {
             _deviceList = state.devices;
              _isLoading = false;
            });
          }
          if(state is TraccarDevicesLoading)
            {
              _isLoading = true;
            }
          if (state is DeleteTraccarDeviceLoading) {
            setState(() {
              _isLoading = true;
            });
          }
          if (state is DeleteTraccarDeviceLoaded) {
            setState(() {
              _isLoading = false;
            });
            context.read<MapBloc>().add(GetUserTraccarDevices());
          }
          if (state is MapError && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Error: ${state.message}'),
              backgroundColor: Colors.red,
            ));
            setState(() => _isLoading = false);
          }
        },
        child: BlocBuilder<MapBloc, MapState>(
          // Build the UI based on loading or loaded states
          builder: (context, state) {
            if (state is TraccarDevicesLoaded) {
              return _buildDeviceList();
            }
            if (_isLoading && state is! MapError) {
              return const Center(child: CircularProgressIndicator());
            }
            if (_deviceList.isEmpty) {
              return const Center(
                  child: Text("No notification types available."));
            }
            return _buildDeviceList();
          },
        ),
      ),
      floatingActionButton: _buildAddTraccarDeviceButton(context),
    );
  }


  _buildAddTraccarDeviceButton(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text("Add Traccar Device"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: vehicleNameController,
                      decoration: const InputDecoration(
                        labelText: "Vehicle Name",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: imeiController,
                      decoration: const InputDecoration(
                        labelText: "IMEI",
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    final device = Device();
                    device.name = vehicleNameController.text;
                    device.uniqueId = imeiController.text;

                    final jsonMap = device.toJson()
                      ..remove('lastPositionId');

                    context.read<MapBloc>().add(AddTraccarDevice(jsonEncode(jsonMap)));

                    vehicleNameController.clear();
                    imeiController.clear();

                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text("Submit"),
                ),
              ],
            );
          },
        );
      },
      backgroundColor: const Color(0xFF2E2E32),
      child: const Icon(Icons.add),
    );
  }



  Widget _buildDeviceList() {
    print("[Traccar devices] $_deviceList");

    return ListView.builder(
      itemCount: _deviceList.length,
      itemBuilder: (context, index) {
        final device = _deviceList[index];
        return Card(
          color: AppColors.markerBg1,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Name: ${device.name ?? 'Unknown'}",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text("ID: ${device.id}"),
                      Text("Status: ${device.status ?? 'Unknown'}"),
                      Text("IMEI: ${device.uniqueId ?? 'N/A'}"),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: Text("Delete '${device.name}'?"),
                        content: const Text("This action cannot be undone."),
                        actions: [
                          TextButton(
                            child: const Text("Delete", style: TextStyle(color: Colors.red)),
                            onPressed: () {
                              context.read<MapBloc>().add(DeleteTraccarDevice(device.id!));
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
          ),
        );
      },
    );
  }


}
