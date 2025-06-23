import 'package:bikerr/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:bikerr/features/chat/data/models/chat_room_model.dart'; // Import your ChatRoomModel

class ChatRoomListItem extends StatelessWidget {
  final int id;
  final String? imageUrl;
  final String name;
  final String? ownerName;
  final String? location;
  final int memberCount;
  final int? totalRides;
  final String description;
  final bool isMember; // Indicates if the user is a member of the chat room
  final bool isRequested; // Indicates if the user has a pending join request
  final bool isJoining; // Flag to indicate if this specific item is currently undergoing a join/request action

  final VoidCallback? onJoinTap; // Callback for "Join" button
  final VoidCallback? onRequestTap; // Callback for "Requested" button (e.g., to view request status)
  final VoidCallback? onViewTap; // Callback for "Joined" button (e.g., to navigate to chat)

  const ChatRoomListItem({
    Key? key,
    required this.id,
    this.imageUrl,
    required this.name,
    this.ownerName,
    this.location,
    required this.memberCount,
    this.totalRides,
    required this.description,
    required this.isMember,
    required this.isRequested,
    this.isJoining = false, // Default to false, set to true by BLoC during operation
    this.onJoinTap,
    this.onRequestTap,
    this.onViewTap,
  }) : super(key: key);

  // --- Helper method to determine the current status string ---
  String _getStatus() {
    if (isMember) {
      return 'Joined';
    } else if (isRequested) {
      // This means a request has been sent and is pending
      return 'Requested';
    } else {
      // User is neither a member nor has a pending request
      return 'Join';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine the status string based on the flags
    final statusString = _getStatus();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24.0,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: imageUrl != null
                      ? NetworkImage(imageUrl!)
                      : null,
                  child: imageUrl == null
                      ? Icon(
                    Icons.group,
                    color: Colors.grey[600],
                  )
                      : null,
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                color: AppColors.bikerrRedStroke,
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          // Build the status button dynamically
                          _buildStatusButton(context, statusString),
                        ],
                      ),
                      const SizedBox(height: 4.0),
                      if (ownerName != null || location != null)
                        Text(
                          '${ownerName ?? ''}${ownerName != null && location != null ? ' • ' : ''}${location ?? ''}',
                          style: TextStyle(
                            fontSize: 12.0,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 8.0),
                      Row(
                        children: [
                          _buildInfoChip(
                            icon: Icons.people,
                            label: 'Total Members-$memberCount',
                          ),
                          const SizedBox(width: 8.0),
                          if (totalRides != null)
                            _buildInfoChip(
                              icon: Icons.directions_bike,
                              label: 'Total Rides-$totalRides',
                            ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14.0,
                          color: Colors.grey[800],
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper method to build the status button ---
  Widget _buildStatusButton(BuildContext context, String status) {
    VoidCallback? onPressed;
    Widget child;
    ButtonStyle style;

    // Disable button if an action is already in progress for this item
    final bool isDisabled = isJoining;

    switch (status) {
      case 'Joined':
        onPressed = isDisabled ? null : onViewTap;
        child = const Text(
          'Joined',
          style: TextStyle(fontSize: 12.0, color: Colors.green),
        );
        style = OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.green),
        );
        break;
      case 'Requested':
        onPressed = isDisabled ? null : onRequestTap; // Or null if no action needed for "Requested"
        child = const Text(
          'Requested',
          style: TextStyle(fontSize: 12.0, color: Colors.orange),
        );
        style = OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.orange),
        );
        break;
      case 'Join':
      default:
        onPressed = isDisabled ? null : onJoinTap;
        // Show loading indicator if joining, otherwise show "Join" text
        child = isDisabled
            ? const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : const Text(
          'Join',
          style: TextStyle(fontSize: 12.0, color: Colors.red),
        );
        style = ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
        );
        break;
    }

    // Determine whether to use ElevatedButton or OutlinedButton based on status
    return status == 'Join'
        ? ElevatedButton(
      onPressed: onPressed,
      style: style.copyWith(
        padding: MaterialStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 12.0, vertical: 0),
        ),
        minimumSize: MaterialStateProperty.all(
          const Size(0, 28),
        ),
      ),
      child: child,
    )
        : OutlinedButton(
      onPressed: onPressed,
      style: style.copyWith(
        padding: MaterialStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 12.0, vertical: 0),
        ),
        minimumSize: MaterialStateProperty.all(
          const Size(0, 28),
        ),
      ),
      child: child,
    );
  }

  // --- Helper method to build info chips ---
  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.0, color: Colors.grey[700]),
          const SizedBox(width: 4.0),
          Text(
            label,
            style: TextStyle(fontSize: 12.0, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}