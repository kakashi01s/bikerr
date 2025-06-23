import 'package:bikerr/config/constants.dart';
import 'package:bikerr/services/session/session_manager.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();

  factory SocketService() => _instance;

  late IO.Socket _socket;
  final SessionManager session = SessionManager.instance;

  SocketService._internal() {
    initSocket();
  }

  // Initialize the socket connection
  initSocket() async {
    String token =
        session.jwtAccessToken ?? ''; // Get token from session manager

    _socket = IO.io(
      AppUrl.baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .build(),
    );

    _socket.connect();

    _socket.onConnect((_) {
      print('Socket Connected: ${_socket.id}');
    });

    // Handle reconnection attempts
    _socket.onReconnect((_) {
      print('Socket Reconnected: ${_socket.id}');
    });

    // Handle disconnection
    _socket.onDisconnect((_) {
      print('Socket Disconnected: ${_socket.id}');
    });

    // // Listen for incoming messages (moved to Bloc)
    // _socket.on('newMessage', (message) {
    //   print('Received message: $message');
    //   // Handled in the Bloc
    // });
  }

  // Send a message
  void sendMessage(String roomId, String senderId, String messageText) {
    final message = {
      'roomId': roomId,
      'senderId': senderId,
      'text': messageText,
    };

    _socket.emit('sendMessage', message); // Emit message to the server
  }

  // Join a specific chat
  void joinChat(int chatRoomId) {
    _socket.emit('joinChat', chatRoomId); // Emit joinChat event
  }

  // Leave a specific chat
  void leaveChat(int chatRoomId) {
    _socket.emit('leaveChat', chatRoomId); // Emit leaveChat event
  }

  // Get the current socket instance
  IO.Socket get socket => _socket;

  // Disconnect the socket manually if needed
  void disconnect() {
    _socket.disconnect();
  }
}
