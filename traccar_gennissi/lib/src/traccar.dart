import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traccar_gennissi/traccar_gennissi.dart';
import 'model/Device.dart';
import 'model/Event.dart';
import 'model/GeofenceModel.dart';
import 'model/NotificationType.dart';
import 'model/PositionModel.dart';
import 'model/RouteReport.dart';
import 'model/Stop.dart';
import 'model/Summary.dart';
import 'model/Trip.dart';

class Traccar {
  static Map<String, String> headers = {'Content-Type': 'application/json'};
  static String? serverURL;
  static String? socketURL;
  static String? sessionCookie;
  static WebSocket? _webSocket;
  static final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _sessionKey = 'JSESSIONID';
  static final StreamController<dynamic> _webSocketController = StreamController<dynamic>.broadcast(); // New: StreamController

  static Future<void> saveSessionCookie(String cookie) async {
    sessionCookie = cookie;
    await _secureStorage.write(key: _sessionKey, value: cookie);
    headers['Cookie'] = sessionCookie!;
    print("[Traccar] Session cookie saved: $cookie");
  }

  static Future<void> loadSessionCookie() async {
    sessionCookie = await _secureStorage.read(key: _sessionKey);
    if (sessionCookie != null) {
      headers['Cookie'] = sessionCookie!;
      print("[Traccar] Session cookie loaded: $sessionCookie");
    } else {
      print("[Traccar] No session cookie found.");
    }
  }

  static Future<void> clearSessionCookie() async {
    sessionCookie = null;
    await _secureStorage.delete(key: _sessionKey);
    headers.remove('Cookie');
    print("[Traccar] Session cookie cleared.");
  }

  static Future<bool> refreshSessionCookie(String token) async {
    try {
      final response = await http.get(Uri.parse('$serverURL/api/session?token=$token'));
      if (response.statusCode == 200) {
        updateCookie(response);
        return true;
      }
    } catch (e) {
      print("Error refreshing session cookie: $e");
    }
    return false;
  }

  static Future<http.Response?> loginWithToken(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (prefs.containsKey('url')) {
      serverURL = prefs.get('url').toString();
      var uri = Uri.parse(serverURL!);
      String socketScheme = uri.scheme == "http" ? "ws://" : "wss://";
      socketURL = uri.hasPort
          ? "$socketScheme${uri.host}:${uri.port}/api/socket"
          : "$socketScheme${uri.host}/api/socket";
    } else {
      serverURL = "http://demo.traccar.org";
    }

    final uri = Uri.parse("$serverURL/api/session?token=$token");
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final rawCookie = response.headers['set-cookie'];
      if (rawCookie != null) {
        final cookie = rawCookie.split(';').firstWhere(
              (c) => c.trim().startsWith('JSESSIONID'),
          orElse: () => '',
        ).trim();
        await saveSessionCookie(cookie);
      }
      return response;
    } else {
      print("Login failed with status: ${response.statusCode}");
      return null;
    }
  }

  static Future<bool> login(String purchaseCode, email, password) async {
    final prefs = await SharedPreferences.getInstance();
    serverURL = prefs.getString('url') ?? 'http://13.60.88.192:8082'; // Use local IP for now as it was in previous traccar.dart
    socketURL = prefs.getString('socketUrl') ?? 'ws://13.60.88.192:8082/api/socket';

    final response = await http.post(
      Uri.parse('$serverURL/api/session'),
      headers: headers,
      body: json.encode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      updateCookie(response);
      await prefs.setString('email', email);
      await prefs.setString('password', password);
      return true;
    } else {
      print(response.statusCode);
      return false;
    }
  }

  static void updateCookie(http.Response response) {
    String? rawCookie = response.headers['set-cookie'];
    if (rawCookie != null) {
      int index = rawCookie.indexOf(';');
      if (index == -1) {
        saveSessionCookie(rawCookie);
      } else {
        saveSessionCookie(rawCookie.substring(0, index));
      }
    }
  }

  static Future<bool> sessionLogout() async {
    try {
      final response = await http.delete(Uri.parse('$serverURL/api/session'), headers: headers);
      if (response.statusCode == 204) {
        await clearSessionCookie();
        disconnectWebSocket(); // Disconnect WebSocket on logout
        return true;
      } else {
        print("Logout failed: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("Error during logout: $e");
      return false;
    }
  }

  // Modified: connectWebSocket now returns a Stream
  static Stream<dynamic>? connectWebSocket() {
    if (socketURL == null || sessionCookie == null) {
      print("WebSocket connection failed: socketURL or sessionCookie is null.");
      return null;
    }
    try {
      // Corrected: WebSocket.connect returns a Future<WebSocket>.
      // We call .then() on this Future to handle the connected WebSocket.
      WebSocket.connect(socketURL!, headers: {'Cookie': sessionCookie!}).then((ws) {
        _webSocket = ws; // Assign the connected WebSocket to _webSocket
        print("[Traccar] WebSocket Connected to $socketURL");
        _webSocket?.listen( // Use _webSocket for listening now
              (data) {
            // Process the incoming data and add it to the stream controller
            print("[Traccar] WebSocket Data received: $data");
            final Map<String, dynamic> decodedData = json.decode(data);
            if (decodedData.containsKey('devices')) {
              _webSocketController.add(Device.fromList(decodedData['devices']));
            } else if (decodedData.containsKey('positions')) {
              _webSocketController.add(PositionModel.fromList(decodedData['positions']));
            } else if (decodedData.containsKey('events')) {
              _webSocketController.add(Event.fromList(decodedData['events']));
            } else {
              _webSocketController.add(data); // Fallback for other data types
            }
          },
          onError: (error) {
            print("[Traccar] WebSocket Error: $error");
            _webSocketController.addError(error);
          },
          onDone: () {
            print("[Traccar] WebSocket Disconnected.");
            _webSocketController.close(); // Close the controller when WebSocket is done
            _webSocket = null;
          },
        );
      }).catchError((e) {
        print("[Traccar] WebSocket connection error: $e");
        _webSocketController.addError(e);
      });
      return _webSocketController.stream; // Return the stream from the controller
    } catch (e) {
      print("[Traccar] Error connecting WebSocket: $e");
      _webSocketController.addError(e);
      return null;
    }
  }

  static void disconnectWebSocket() {
    _webSocket?.close();
    _webSocket = null;
    if (!_webSocketController.isClosed) { // Ensure controller is not already closed
      _webSocketController.close();
    }
    print("[Traccar] WebSocket manually disconnected.");
  }

  static Future<List<Device>?> getDevices() async {
    try {
      final response = await http.get(Uri.parse('$serverURL/api/devices'), headers: headers);
      if (response.statusCode == 200) {
        return Device.fromList(json.decode(response.body));
      } else {
        print(response.statusCode);
        return null;
      }
    } catch (e) {
      print("Error getting devices: $e");
      return null;
    }
  }

  static Future<PositionModel?> getPositionById(String deviceId, String posId) async {
    try {
      final response = await http.get(Uri.parse('$serverURL/api/positions/$posId'), headers: headers);
      if (response.statusCode == 200) {
        return PositionModel.fromJson(json.decode(response.body));
      } else {
        print(response.statusCode);
        return null;
      }
    } catch (e) {
      print("Error getting position by ID: $e");
      return null;
    }
  }

  static Future<List<PositionModel>?> getPositions(String deviceId, String from, String to) async {
    try {
      final response = await http.get(Uri.parse('$serverURL/api/reports/positions?deviceId=$deviceId&from=$from&to=$to'), headers: headers);
      if (response.statusCode == 200) {
        return PositionModel.fromList(json.decode(response.body));
      } else {
        print(response.statusCode);
        return null;
      }
    } catch (e) {
      print("Error getting positions: $e");
      return null;
    }
  }

  static Future<List<PositionModel>?> getLatestPositions() async {
    try {
      final response = await http.get(Uri.parse('$serverURL/api/positions'), headers: headers);
      if (response.statusCode == 200) {
        return PositionModel.fromList(json.decode(response.body));
      } else {
        print(response.statusCode);
        return null;
      }
    } catch (e) {
      print("Error getting latest positions: $e");
      return null;
    }
  }

  static Future<Device?> getDevicesById(String id) async {
    try {
      final response = await http.get(Uri.parse('$serverURL/api/devices/$id'), headers: headers);
      if (response.statusCode == 200) {
        return Device.fromJson(json.decode(response.body));
      } else {
        print(response.statusCode);
        return null;
      }
    } catch (e) {
      print("Error getting device by ID: $e");
      return null;
    }
  }

  static Future<List<String>?> getSendCommands(String id) async {
    try {
      final response = await http.get(Uri.parse('$serverURL/api/commands/types?deviceId=$id'), headers: headers);
      if (response.statusCode == 200) {
        return List<String>.from(json.decode(response.body));
      } else {
        print(response.statusCode);
        return null;
      }
    } catch (e) {
      print("Error getting send commands: $e");
      return null;
    }
  }

  static Future<List<RouteReport>?> getRoute(String deviceId, String from, String to) async {
    try {
      final response = await http.get(Uri.parse('$serverURL/api/reports/route?deviceId=$deviceId&from=$from&to=$to'), headers: headers);
      if (response.statusCode == 200) {
        Iterable list = json.decode(response.body);
        return list.map((model) => RouteReport.fromJson(model)).toList();
      } else {
        print(response.statusCode);
        return null;
      }
    } catch (e) {
      print("Error getting route: $e");
      return null;
    }
  }

  static Future<List<NotificationTypeModel>?> getNotificationTypes() async {
    try {
      final response = await http.get(Uri.parse('$serverURL/api/notifications/types'), headers: headers);
      if (response.statusCode == 200) {
        Iterable list = json.decode(response.body);
        return list.map((model) => NotificationTypeModel.fromJson(model)).toList();
      } else {
        print(response.statusCode);
        return null;
      }
    } catch (e) {
      print("Error getting notification types: $e");
      return null;
    }
  }

  static Future<List<Event>?> getEvents(String deviceId, String from, String to) async {
    try {
      final response = await http.get(Uri.parse('$serverURL/api/reports/events?deviceId=$deviceId&from=$from&to=$to'), headers: headers);
      if (response.statusCode == 200) {
        Iterable list = json.decode(response.body);
        return list.map((model) => Event.fromJson(model)).toList();
      } else {
        print(response.statusCode);
        return null;
      }
    } catch (e) {
      print("Error getting events: $e");
      return null;
    }
  }

  static Future<Event?> getEventById(String id) async {
    try {
      final response = await http.get(Uri.parse('$serverURL/api/events/$id'), headers: headers);
      if (response.statusCode == 200) {
        return Event.fromJson(json.decode(response.body));
      } else {
        print(response.statusCode);
        return null;
      }
    } catch (e) {
      print("Error getting event by ID: $e");
      return null;
    }
  }

  static Future<List<Event>?> getAllDeviceEvents(var deviceId, String from, String to) async {
    try {
      final response = await http.get(Uri.parse('$serverURL/api/events?deviceId=$deviceId&from=$from&to=$to'), headers: headers);
      if (response.statusCode == 200) {
        Iterable list = json.decode(response.body);
        return list.map((model) => Event.fromJson(model)).toList();
      } else {
        print(response.statusCode);
        return null;
      }
    } catch (e) {
      print("Error getting all device events: $e");
      return null;
    }
  }

  static Future<List<Trip>?> getTrip(String deviceId, String from, String to) async {
    try {
      final response = await http.get(Uri.parse('$serverURL/api/reports/trips?deviceId=$deviceId&from=$from&to=$to'), headers: headers);
      if (response.statusCode == 200) {
        Iterable list = json.decode(response.body);
        return list.map((model) => Trip.fromJson(model)).toList();
      } else {
        print(response.statusCode);
        return null;
      }
    } catch (e) {
      print("Error getting trip: $e");
      return null;
    }
  }

  static Future<List<Stop>?> getStops(String deviceId, String from, String to) async {
    try {
      final response = await http.get(Uri.parse('$serverURL/api/reports/stops?deviceId=$deviceId&from=$from&to=$to'), headers: headers);
      if (response.statusCode == 200) {
        Iterable list = json.decode(response.body);
        return list.map((model) => Stop.fromJson(model)).toList();
      } else {
        print(response.statusCode);
        return null;
      }
    } catch (e) {
      print("Error getting stops: $e");
      return null;
    }
  }

  static Future<Summary?> getSummary(String deviceId, String from, String to) async {
    try {
      final response = await http.get(Uri.parse('$serverURL/api/reports/summary?deviceId=$deviceId&from=$from&to=$to'), headers: headers);
      if (response.statusCode == 200) {
        return Summary.fromJson(json.decode(response.body));
      } else {
        print(response.statusCode);
        return null;
      }
    } catch (e) {
      print("Error getting summary: $e");
      return null;
    }
  }

  static Future<List<GeofenceModel>?> getGeoFencesByUserID(String userID) async {
    try {
      final response = await http.get(Uri.parse('$serverURL/api/geofences?userId=$userID'), headers: headers);
      if (response.statusCode == 200) {
        Iterable list = json.decode(response.body);
        return list.map((model) => GeofenceModel.fromJson(model)).toList();
      } else {
        print(response.statusCode);
        return null;
      }
    } catch (e) {
      print("Error getting geofences by user ID: $e");
      return null;
    }
  }

  static Future<List<GeofenceModel>?> getGeoFencesByDeviceID(String deviceId) async {
    try {
      final response = await http.get(Uri.parse('$serverURL/api/geofences?deviceId=$deviceId'), headers: headers);
      if (response.statusCode == 200) {
        Iterable list = json.decode(response.body);
        return list.map((model) => GeofenceModel.fromJson(model)).toList();
      } else {
        print(response.statusCode);
        return null;
      }
    } catch (e) {
      print("Error getting geofences by device ID: $e");
      return null;
    }
  }

  static Future<String?> geocode(String lat, String lng) async {
    try {
      final response = await http.get(Uri.parse('$serverURL/api/geocode?latitude=$lat&longitude=$lng'), headers: headers);
      if (response.statusCode == 200) {
        return response.body; // Assuming the body is the geocoded address directly
      } else {
        print(response.statusCode);
        return null;
      }
    } catch (e) {
      print("Error during geocoding: $e");
      return null;
    }
  }

  static Future<List<NotificationModel>?> getNotifications() async {
    try {
      final response = await http.get(Uri.parse('$serverURL/api/notifications'), headers: headers);
      if (response.statusCode == 200) {
        Iterable list = json.decode(response.body);
        return list.map((model) => NotificationModel.fromJson(model)).toList();
      } else {
        print(response.statusCode);
        return null;
      }
    } catch (e) {
      print("Error getting notifications: $e");
      return null;
    }
  }

  static Future<String?> sendCommands(String command) async {
    try {
      final response = await http.post(
        Uri.parse('$serverURL/api/commands'),
        headers: headers,
        body: command,
      );
      if (response.statusCode == 200) {
        return response.body;
      } else {
        print(response.statusCode);
        return null;
      }
    } catch (e) {
      print("Error sending command: $e");
      return null;
    }
  }

  static Future<String?> updateUser(String user, String id) async {
    try {
      final response = await http.put(
        Uri.parse('$serverURL/api/users/$id'),
        headers: headers,
        body: user,
      );
      if (response.statusCode == 200) {
        return response.body;
      } else {
        print(response.statusCode);
        return null;
      }
    } catch (e) {
      print("Error updating user: $e");
      return null;
    }
  }

  static Future<String?> addGeofence(String fence) async {
    try {
      final response = await http.post(
        Uri.parse('$serverURL/api/geofences'),
        headers: headers,
        body: fence,
      );
      if (response.statusCode == 200) {
        return response.body;
      } else {
        print(response.statusCode);
        return null;
      }
    } catch (e) {
      print("Error adding geofence: $e");
      return null;
    }
  }

  static Future<String?> addDevice(String device) async {
    try {
      final response = await http.post(
        Uri.parse('$serverURL/api/devices'),
        headers: headers,
        body: device,
      );
      if (response.statusCode == 200) {
        return response.body;
      } else {
        print(response.statusCode);
        return null;
      }
    } catch (e) {
      print("Error adding device: $e");
      return null;
    }
  }

  static Future<String?> updateGeofence(String fence, String id) async {
    try {
      final response = await http.put(
        Uri.parse('$serverURL/api/geofences/$id'),
        headers: headers,
        body: fence,
      );
      if (response.statusCode == 200) {
        return response.body;
      } else {
        print(response.statusCode);
        return null;
      }
    } catch (e) {
      print("Error updating geofence: $e");
      return null;
    }
  }

  static Future<String?> updateDevices(String device, String id) async {
    try {
      final response = await http.put(
        Uri.parse('$serverURL/api/devices/$id'),
        headers: headers,
        body: device,
      );
      if (response.statusCode == 200) {
        return response.body;
      } else {
        print(response.statusCode);
        return null;
      }
    } catch (e) {
      print("Error updating devices: $e");
      return null;
    }
  }

  static Future<String?> addPermission(String permission) async {
    try {
      final response = await http.post(
        Uri.parse('$serverURL/api/permissions'),
        headers: headers,
        body: permission,
      );
      if (response.statusCode == 200) {
        return response.body;
      } else {
        print(response.statusCode);
        return null;
      }
    } catch (e) {
      print("Error adding permission: $e");
      return null;
    }
  }

  static Future<String?> deletePermission(dynamic deviceId, dynamic fenceId) async {
    try {
      final response = await http.delete(
        Uri.parse('$serverURL/api/permissions?deviceId=$deviceId&geofenceId=$fenceId'),
        headers: headers,
      );
      if (response.statusCode == 204) {
        return "Permission deleted successfully";
      } else {
        print(response.statusCode);
        return null;
      }
    } catch (e) {
      print("Error deleting permission: $e");
      return null;
    }
  }

  static Future<String?> deleteGeofence(dynamic id) async {
    try {
      final response = await http.delete(
        Uri.parse('$serverURL/api/geofences/$id'),
        headers: headers,
      );
      if (response.statusCode == 204) {
        return "Geofence deleted successfully";
      } else {
        print(response.statusCode);
        return null;
      }
    } catch (e) {
      print("Error deleting geofence: $e");
      return null;
    }
  }

  static Future<NotificationModel?> addNotifications(String notification) async {
    try {
      final response = await http.post(
        Uri.parse(serverURL! + "/api/notifications"),
        body: notification,
        headers: headers,
      );
      if (response.statusCode == 200) {
        return NotificationModel.fromJson(json.decode(response.body));
      } else {
        print(response.statusCode);
        return null;
      }
    } catch (e) {
      print("Error adding notification: $e");
      return null;
    }
  }

  static Future<http.Response> deleteNotifications(String id) async {
    final response = await http.delete(
      Uri.parse('$serverURL/api/notifications/$id'),
      headers: headers,
    );
    return response;
  }
}