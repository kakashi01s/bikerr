import 'package:bikerr/core/theme.dart'; // Assuming this includes AppColors
import 'package:bikerr/features/chat/presentation/bloc/chat_bloc.dart'; // Import ChatBloc
import 'package:bikerr/features/chat/presentation/pages/chatRoomInfoScreen.dart';
import 'package:bikerr/features/chat/presentation/pages/chatRoomRidesScreen.dart'; // Assuming this widget exists
import 'package:bikerr/features/chat/presentation/pages/chat_screen.dart';
import 'package:bikerr/features/chat/presentation/widgets/chat_app_bar.dart'; // Assuming this widget exists
import 'package:bikerr/utils/enums/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BaseChatScreen extends StatefulWidget {
  final int chatRoomId;
  final String chatRoomName;
  const BaseChatScreen({
    super.key,
    required this.chatRoomId,
    required this.chatRoomName,
  });

  @override
  State<BaseChatScreen> createState() => _BaseChatScreenState();
}

class _BaseChatScreenState extends State<BaseChatScreen> {
  late ChatBloc _chatBloc;
  int _selectedTab = 1; // Default to Chat tab

  // Variables to track horizontal drag for swipe gesture
  double _dragStartX = 0;
  double _dragCurrentX = 0;

  // Create widget instances once
  late final ChatScreen _chatScreen;
  late final Chatroominfoscreen _infoScreen;
  late final Chatroomridesscreen _ridesScreen;

  @override
  void initState() {
    super.initState();
    _chatBloc = context.read<ChatBloc>();

    // Initialize the screen widget instances
    _chatScreen = ChatScreen(
      chatRoomId: widget.chatRoomId,
      // scrollPhysics will be set dynamically in the build method
    );
    _infoScreen = Chatroominfoscreen(chatRoomId: widget.chatRoomId);
    _ridesScreen = Chatroomridesscreen();

    // Only fetch messages when on the chat tab initially or if needed
    _chatBloc.add(
      GetAllMessagesEvent(chatRoomId: widget.chatRoomId, page: 1, pageSize: 20),
    );
    _chatBloc.add(GetChatRoomDetail(chatRoomId: widget.chatRoomId));
  }

  @override
  void dispose() {
    // No need to dispose the screen widgets here, they are managed by the stack
    super.dispose();
  }

  // Function to handle horizontal drag start
  void _onHorizontalDragStart(DragStartDetails details) {
    // Only start drag if on the Chat screen
    if (_selectedTab == 1) {
      _dragStartX = details.globalPosition.dx;
      _dragCurrentX = details.globalPosition.dx;
    } else {
      // If not on Chat screen, reset drag to prevent accidental swipes
      _dragStartX = 0;
      _dragCurrentX = 0;
    }
  }

  // Function to handle horizontal drag update
  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    // Only update drag if on the Chat screen
    if (_selectedTab == 1) {
      _dragCurrentX = details.globalPosition.dx;
      // You can add logic here if you want a parallax effect or visual feedback during the drag
    }
  }

  // Function to handle horizontal drag end
  void _onHorizontalDragEnd(DragEndDetails details) {
    // Only process drag end if on the Chat screen
    if (_selectedTab == 1 && _dragStartX != 0) {
      // Check if a drag was initiated
      final dragDistance = _dragCurrentX - _dragStartX;
      final screenWidth = MediaQuery.of(context).size.width;
      const swipeThreshold =
          0.25; // Swipe threshold as a fraction of screen width

      // Swipe Right (to reveal Info screen from the left)
      if (dragDistance > screenWidth * swipeThreshold) {
        setState(() {
          _selectedTab = 0; // Switch to Info tab
        });
      }
      // Swipe Left (to reveal Rides screen from the right)
      else if (dragDistance < -screenWidth * swipeThreshold) {
        setState(() {
          _selectedTab = 2; // Switch to Rides tab
        });
      }
    }
    // Add swipe back logic for Info and Rides screens here if needed,
    // or handle it with a back button/gesture within those screens.
    // The current _onHorizontalDragEnd is primarily for the Chat screen.

    // Reset drag variables
    _dragStartX = 0;
    _dragCurrentX = 0;
  }

  // Helper to calculate the left position for the Chat screen
  double _getChatScreenLeftPosition(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final panelWidth = screenWidth * 0.75; // 3/4th of screen width

    if (_selectedTab == 0) {
      // Info tab is active (Chat is pushed right)
      return panelWidth;
    } else if (_selectedTab == 2) {
      // Rides tab is active (Chat is pushed left)
      return -panelWidth;
    } else {
      // Chat tab is active (Chat is centered)
      return 0;
    }
  }

  // Helper to calculate the left position for the Info panel
  double _getInfoPanelLeftPosition(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final panelWidth = screenWidth * 0.75; // 3/4th of screen width

    if (_selectedTab == 0) {
      // Info tab is active (Info is at left edge)
      return 0;
    } else {
      // Info is inactive (off-screen left)
      return -panelWidth;
    }
  }

  // Helper to calculate the left position for the Rides panel
  double _getRidesPanelLeftPosition(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final panelWidth = screenWidth * 0.75; // 3/4th of screen width

    if (_selectedTab == 2) {
      // Rides tab is active (Rides is at right, covering 3/4th)
      return screenWidth - panelWidth; // Leaves 1/4th on the left
    } else {
      // Rides is inactive (off-screen right)
      return screenWidth;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final panelWidth = screenWidth * 0.75; // 3/4th of screen width

    return BlocListener<ChatBloc, ChatState>(
      listener: (context, state) {},
      child: Scaffold(
        backgroundColor: AppColors.bgColor,
        appBar: ChatAppBar(chatRoomName: widget.chatRoomName),
        body: Column(
          children: [
            // Chat Tab Bar remains at the top
            Center(
              child: ChatTabBar(
                selectedTab: _selectedTab,
                onTabChanged: (index) {
                  setState(() {
                    _selectedTab = index;
                    // You might want to trigger data loading here based on the selected tab
                    if (index == 1) {
                      // If switching to Chat tab
                      // Optionally re-fetch messages or ensure they are loaded
                      if (_chatBloc.state.messages.isEmpty) {
                        _chatBloc.add(
                          GetAllMessagesEvent(
                            chatRoomId: widget.chatRoomId,
                            page: 1,
                            pageSize: 20,
                          ),
                        );
                      }
                    }
                    // Add similar logic for fetching Info or Rides data if needed
                  });
                },
              ),
            ),
            // Use Expanded with a Stack for the main content area
            Expanded(
              child: Stack(
                children: [
                  // Chat Screen (Slides horizontally)
                  AnimatedPositioned(
                    duration: Duration(milliseconds: 300), // Animation duration
                    curve: Curves.easeInOut, // Animation curve
                    left: _getChatScreenLeftPosition(
                      context,
                    ), // Animate left position
                    top: 0,
                    bottom: 0,
                    width:
                        screenWidth, // Chat screen always has full screen width
                    // Use the stored instance of ChatScreen
                    child: GestureDetector(
                      onHorizontalDragStart: _onHorizontalDragStart,
                      onHorizontalDragUpdate: _onHorizontalDragUpdate,
                      onHorizontalDragEnd: _onHorizontalDragEnd,
                      // Use a ValueKey that depends on the selected tab to help Flutter
                      // update the gesture detector correctly.
                      key: ValueKey(_selectedTab),
                      child: ChatScreen(
                        chatRoomId: widget.chatRoomId,
                        scrollPhysics:
                            _selectedTab == 1
                                ? null
                                : NeverScrollableScrollPhysics(),
                      ),
                    ),
                  ),

                  // Info Panel (Slides from the left)
                  AnimatedPositioned(
                    duration: Duration(milliseconds: 300), // Animation duration
                    curve: Curves.easeInOut, // Animation curve
                    left: _getInfoPanelLeftPosition(
                      context,
                    ), // Animate left position
                    top: 0,
                    bottom: 0,
                    width: panelWidth, // 3/4th of screen width
                    // Use the stored instance of InfoScreen
                    // Use Offstage to keep the widget in the tree but invisible and non-interactive
                    child: Offstage(
                      offstage:
                          _selectedTab !=
                          0, // Offstage when not on the Info tab
                      child: _infoScreen,
                    ),
                  ),

                  // Rides Panel (Slides from the right)
                  AnimatedPositioned(
                    duration: Duration(milliseconds: 300), // Animation duration
                    curve: Curves.easeInOut, // Animation curve
                    left: _getRidesPanelLeftPosition(
                      context,
                    ), // Animate left position
                    top: 0,
                    bottom: 0,
                    width: panelWidth, // 3/4th of screen width
                    // Use the stored instance of RidesScreen
                    // Use Offstage to keep the widget in the tree but invisible and non-interactive
                    child: Offstage(
                      offstage:
                          _selectedTab !=
                          2, // Offstage when not on the Rides tab
                      child: _ridesScreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ChatTabBar widget remains the same
class ChatTabBar extends StatelessWidget {
  final int selectedTab;
  final Function(int) onTabChanged;
  const ChatTabBar({
    super.key,
    required this.selectedTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tabs = ['Info', 'Chat', 'Rides'];
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 25),
      child: Container(
        height: 30,
        decoration: BoxDecoration(
          color: AppColors.messageListPage,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(tabs.length, (index) {
            final isSelected = selectedTab == index;
            return Expanded(
              child: GestureDetector(
                onTap: () => onTabChanged(index),
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? AppColors.bikerrRedFill
                            : AppColors.messageListPage,
                    borderRadius: isSelected ? BorderRadius.circular(5) : null,
                  ),
                  child: Center(
                    child: Text(tabs[index], style: textTheme.labelSmall),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
