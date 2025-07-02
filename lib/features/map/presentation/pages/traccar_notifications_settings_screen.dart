import 'package:bikerr/features/map/presentation/bloc/map_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TraccarNotificationSettingsScreen extends StatefulWidget {
  final int deviceId;
  const TraccarNotificationSettingsScreen({super.key, required this.deviceId});

  @override
  State<TraccarNotificationSettingsScreen> createState() => _TraccarNotificationSettingsScreenState();
}



class _TraccarNotificationSettingsScreenState extends State<TraccarNotificationSettingsScreen> {


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    context.read<MapBloc>().add(GetTraccarNotificationTypes());
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      title: Text("Notification Settings"),
      ),
      body: ListView.builder(itemBuilder: (context, index) {

    },
    )
    );
  }
}
