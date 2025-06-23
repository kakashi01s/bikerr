import 'package:bikerr/config/constants.dart';
import 'package:bikerr/core/theme.dart';
import 'package:bikerr/features/auth/data/models/user_model.dart';
import 'package:bikerr/features/chat/data/models/chat_room_model.dart';
import 'package:bikerr/features/chat/data/models/chat_room_user_model.dart';
import 'package:bikerr/features/chat/domain/entitiy/chat_room_user_entity.dart';
import 'package:bikerr/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:bikerr/services/session/session_manager.dart';
import 'package:bikerr/utils/enums/enums.dart';
import 'package:bikerr/utils/widgets/buttons/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
// Consider adding this import if you use collection extension methods like firstWhereOrNull
// import 'package:collection/collection.dart';

class Chatroominfoscreen extends StatelessWidget {
  // Get the current user ID. SessionManager.instance.userId should be initialized
  // before this widget is built.
  final String? _currentUserId = SessionManager.instance.userId;
  final int chatRoomId;
  Chatroominfoscreen({super.key, required this.chatRoomId});

  @override
  Widget build(BuildContext context) {
    // Debugging: Print the current user ID when the widget builds
    print('Chatroominfoscreen built for chatRoomId: $chatRoomId');
    print('Current User ID from SessionManager: $_currentUserId');

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      // Removed AppBar as requested
      body: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          print(
            'Chatroominfoscreen BlocBuilder rebuilt. Status: ${state.postApiStatus}, Error: ${state.errorMessage}',
          );

          // Show loading indicator while fetching details initially
          if (state.postApiStatus == PostApiStatus.loading &&
              state.chatRoomDetails == null) {
            return Center(child: CircularProgressIndicator());
          }
          // Handle initial error state if fetching details failed
          // Check error and status to ensure it's a relevant error state
          if (state.postApiStatus != PostApiStatus.loading &&
              state.errorMessage != null &&
              state.chatRoomDetails == null) {
            print('Failed to load chat room details: ${state.errorMessage}');
            return Center(
              child: Text(
                "Failed to load group info: ${state.errorMessage}",
                textAlign: TextAlign.center,
              ),
            );
          }

          // Check if chatRoomDetails is still null after loading/error check
          final chatRoomDetails = state.chatRoomDetails;
          if (chatRoomDetails == null) {
            print('Chat room details are null.');
            // This might happen if chatRoomId was invalid or group doesn't exist
            return Center(child: Text("Group information not available."));
          }
          print(
            'Chat room details loaded: ${chatRoomDetails.name}, Members: ${chatRoomDetails.users?.length ?? 0}',
          );

          // Now we have chatRoomDetails, build the content
          final users = chatRoomDetails.users;

          // --- Determine if the current user is the owner ---
          bool isCurrentUserOwner = false;
          if (users != null && _currentUserId != null) {
            print(
              'Searching for current user ($_currentUserId) in members list...',
            );
            // Find the member corresponding to the current user
            // Use .cast() for safety if list contains nulls
            final currentUserMember = users
                .cast<ChatRoomUserEntity?>()
                .firstWhere(
                  (member) => member?.user.id.toString() == _currentUserId,
                  orElse: () => null, // Return null if not found
                );

            if (currentUserMember != null) {
              print(
                'Current user found in members list. Role: ${currentUserMember.role}, User ID: ${currentUserMember.user.id}',
              );
              // Check if the found member is the owner
              // Ensure you are comparing against the correct OWNER role value
              if (currentUserMember.role == 'OWNER') {
                // Use Enum if defined
                isCurrentUserOwner = true;
                print('Current user IS identified as the OWNER.');
              } else {
                print('Current user is NOT the OWNER.');
              }
            } else {
              print(
                'Current user ($_currentUserId) NOT found in members list.',
              );
            }
          } else {
            print(
              'Users list is null or current user ID is null. Cannot determine if current user is owner.',
            );
          }
          // --- End Determine current user owner ---

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Group Detail Section
              GroupDetail(chatRoomModel: chatRoomDetails),

              // Members List Title
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Text(
                  "Members (${users?.length ?? 0})",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.whiteText,
                  ), // Example styling
                ),
              ),
              Divider(
                color: AppColors.bikerrRedFill.withOpacity(
                  0.5,
                ), // Consistent divider color
                height: 1,
              ), // Add a divider
              // Members List (takes remaining space)
              Expanded(
                child: users == null || users.isEmpty
                        ? Center(child: Text("No members in this group."))
                        : ListView.separated(
                          // Use ListView.separated for built-in dividers
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16, // Increased horizontal padding
                            vertical: 8, // Increased vertical padding
                          ),
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final member = users[index];
                            // Ensure member is not null if users list itself can contain nulls
                            if (member == null) return SizedBox.shrink();

                            // Use Enum if available, otherwise compare string roles
                            final isAdmin = member.role == "OWNER";

                            // --- Determine if admin actions should be shown for THIS specific member ---
                            // Show actions if:
                            // 1. The current user is the owner of the group (`isCurrentUserOwner` is true)
                            // 2. The member being displayed is NOT the current user (`member.user.id != _currentUserId`)
                            final bool showAdminActions =
                                isCurrentUserOwner &&
                                member.user.id !=
                                    _currentUserId; // Add print statements here

                            print('User Tile for: ${member.user.name}');
                            print(
                              '  User ID: ${member.user.id}, Role: ${member.role}',
                            );
                            print('  isCurrentUserOwner: $isCurrentUserOwner');
                            print(
                              '  member.user.id != _currentUserId: ${member.user.id} != ${_currentUserId} -> ${member.user.id != _currentUserId}',
                            );
                            print(
                              '  showAdminActions for this tile: $showAdminActions',
                            );
                            // Optional: Add condition && member.role != ChatRoomRole.OWNER
                            // if owners cannot manage other owners.

                            return UserTile(
                              chatRoomModel: chatRoomDetails,
                              member: member,
                              isOWNER: isAdmin,
                              showAdminActions:
                                  showAdminActions, // Pass the new flag
                            );
                          },
                          separatorBuilder:
                              (context, index) => Divider(
                                // Add a separator line between items
                                color: AppColors.bikerrRedFill.withOpacity(
                                  0.5,
                                ), // Make divider slightly transparent
                                height: 1,
                                indent:
                                    50, // Indent divider to align with avatar+spacing
                              ),
                        ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// --- Group Detail Widget --- (Kept from previous step)
class GroupDetail extends StatelessWidget {
  final ChatRoomModel? chatRoomModel;
  const GroupDetail({super.key, required this.chatRoomModel});

  @override
  Widget build(BuildContext context) {
    var textTheme = Theme.of(context).textTheme;

    if (chatRoomModel == null) {
      return SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.bikerrRedFill.withOpacity(0.5),
                child: SvgPicture.asset(
                  AppLogos.user,
                  height: 35,
                  colorFilter: ColorFilter.mode(
                    AppColors.buttonColor,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(
                        chatRoomModel!.name ?? "Group Name",
                        style: textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                      IconButton(onPressed: () {

                      }, icon: Icon(Icons.logout))
                    ],),
                   
                    Text(
                      chatRoomModel!.city ?? "Group City",
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.bikerrRedFill,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Text(
            "Description",
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.bikerrRedFill,
            ),
          ),
          SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.buttonColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.bikerrRedFill.withOpacity(0.3),
              ),
            ),
            child: Text(
              chatRoomModel!.description ?? "No description provided.",
              style: textTheme.bodySmall?.copyWith(color: AppColors.whiteText),
            ),
          ),
        ],
      ),
    );
  }
}

// --- User Tile Widget --- (Kept from previous step, simplified avatar)
class UserTile extends StatelessWidget {
  final bool isOWNER;
  final ChatRoomUserEntity member;
  final ChatRoomModel chatRoomModel;
  final bool showAdminActions; // Should admin actions be shown for THIS tile?

  const UserTile({
    super.key,
    required this.isOWNER,
    required this.member,
    this.showAdminActions = false,
    required this.chatRoomModel, // Default to false if not provided
  });

  @override
  Widget build(BuildContext context) {
    var textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // User Avatar (Simplified as requested)
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.bikerrRedFill.withOpacity(0.5),
            child: Icon(Icons.person, color: AppColors.buttonColor),
          ),
          SizedBox(width: 12),

          // User Name (Expanded)
          Expanded(
            child: Text(
              member.user.name ?? "Unknown User",
              style: textTheme.labelSmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Owner Badge (only show if THIS user is the owner being displayed)
          if (isOWNER)
            Container(
              margin: const EdgeInsets.only(left: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.bikerrRedFill.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.bikerrRedStroke, width: 1),
              ),
              child: Text(
                "OWNER",
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.bikerrRedStroke,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),

          // Admin Actions (only show if showAdminActions is true)
          if (showAdminActions) // Condition controlled by parent
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: IconButton(
                icon: Icon(Icons.more_vert, color: AppColors.whiteText),
                tooltip: 'Admin Options',
                onPressed: () {
                  print('Admin options tapped for ${member.user.name}');
                  _showAdminOptions(context, member);
                },
              ),
            ),
        ],
      ),
    );
  }

  // Helper method to show admin options (example using ModalBottomSheet)
  void _showAdminOptions(BuildContext context, ChatRoomUserEntity member) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.remove_circle_outline, color: Colors.red),
                title: Text('Remove User'),
                onTap: () {
                  Navigator.pop(context);
                  print(
                    'Remove user tapped for ${member.user.name} (ID: ${member.user.id}) from )',
                  );
                  // TODO: Dispatch Bloc event to remove user
                  context.read<ChatBloc>().add(
                    RemoveUserEvent(
                      chatRoomId: chatRoomModel.id.toString(),
                      memberId: member.user.id.toString(),
                    ),
                  );
                },
              ),
              // TODO: Add more options like "Change Role", "Promote to Admin", "Demote", etc.
            ],
          ),
        );
      },
    );
  }
}
