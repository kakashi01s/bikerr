import 'dart:convert';

import 'package:bikerr/core/theme.dart';
import 'package:bikerr/features/map/presentation/bloc/map_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:traccar_gennissi/traccar_gennissi.dart';

class TraccarNotificationSettingsScreen extends StatefulWidget {
  final int deviceId;
  const TraccarNotificationSettingsScreen({super.key, required this.deviceId});

  @override
  State<TraccarNotificationSettingsScreen> createState() =>
      _TraccarNotificationSettingsScreenState();
}

class _TraccarNotificationSettingsScreenState extends State<TraccarNotificationSettingsScreen> {
  Map<String, bool> _switchStates = {}; // Maps type => isActive
  String? _currentlyToggling;
  List<NotificationTypeModel> _notificationTypes = [];
  List<NotificationModel> _activeNotifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Dispatch events to fetch initial data for this screen
    context.read<MapBloc>().add(GetTraccarNotificationTypes());
    context.read<MapBloc>().add(const GetTraccarNotifications());
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notification Settings"),
        backgroundColor: const Color(0xFF2E2E32),
      ),
      body: BlocListener<MapBloc, MapState>(
        // Only listen to state changes relevant to this screen
        listenWhen: (previous, current) {
          return current is NotificationTypesLoaded ||
              current is NotificationsLoaded ||
              current is AddTraccarNotification ||
              current is DeleteTraccarNotification ||
              current is MapError;
        },
        listener: (context, state) {
          if (state is NotificationTypesLoaded) {
            _notificationTypes = state.notificationTypes;
          }

          if (state is NotificationsLoaded) {
            _activeNotifications = state.notifications ?? [];

            final activeTypes = _activeNotifications.map((e) => e.type!).toSet();

            setState(() {
              _switchStates = {
                for (var type in _notificationTypes.map((e) => e.type!))
                  type: activeTypes.contains(type),
              };
            });
          }

          if (_notificationTypes.isNotEmpty) {
            final activeTypes = _activeNotifications.map((e) => e.type!).toSet();

            setState(() {
              _switchStates = {
                for (var type in _notificationTypes.map((e) => e.type!))
                  type: activeTypes.contains(type),
              };
              _isLoading = false;
            });
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
            if (_isLoading && state is! MapError) {
              return const Center(child: CircularProgressIndicator());
            }
            if (_notificationTypes.isEmpty) {
              return const Center(child: Text("No notification types available."));
            }
            return _buildNotificationSettings();
          },
        ),
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return ListView.builder(
      itemCount: _notificationTypes.length,
      itemBuilder: (context, index) {
        final notificationType = _notificationTypes[index];
        final type = notificationType.type!;
        final isActive = _switchStates[type] ?? false;


        return SwitchListTile(
          title: Text(
            // Capitalize first letter for better display
            type.replaceFirst(type[0], type[0].toUpperCase()),
            style: const TextStyle(
              color: AppColors.bikerrRedFill,
              fontSize: 18,
            ),
          ),
          value: isActive,
          activeColor: AppColors.bikerrRedFill,
          onChanged: (_currentlyToggling != null)
              ? null
              : (newValue) async {
            setState(() => _currentlyToggling = type);

            final notification = NotificationModel()
             // ..id = -1
              ..type = type
              ..description = ""
              ..always = true
              ..notificators = "web"
              ..calendarId = 0;

            await _showConfirmationDialog(
              type: type,
              newValue: newValue,
                onConfirm: () {
                  if (newValue) {
                    context.read<MapBloc>().add(
                      AddTraccarNotification(jsonEncode(notification)),
                    );
                  } else {
                    final notificationToDelete = _activeNotifications.firstWhere(
                          (n) => n.type == type,
                      orElse: () => NotificationModel(),
                    );
                    if (notificationToDelete.id == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to find notification ID')),
                      );
                      return;
                    }
                    if (notificationToDelete.id != null) {
                      context.read<MapBloc>().add(
                        DeleteTraccarNotification(notificationToDelete.id!.toString()),
                      );
                    }
                  }

                  setState(() {
                    _switchStates[type] = newValue;
                    _currentlyToggling = null;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        newValue ? 'Enabled $type' : 'Disabled $type',
                      ),
                    ),
                  );
                }

            );

            // If user cancels, reset toggling state
            if (mounted && _currentlyToggling == type) {
              setState(() => _currentlyToggling = null);
            }
          },




        );
      },
    );
  }
  Future<void> _showConfirmationDialog({
    required String type,
    required bool newValue,
    required VoidCallback onConfirm,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('You will Enable this notification for All Your GPS devices'),
        content: Text(newValue
            ? 'Enable "$type" notification?'
            : 'Disable "$type" notification?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              onConfirm(); // Fire the bloc event here
              Navigator.of(context).pop();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

}


