import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traccar_gennissi/traccar_gennissi.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
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
  static String? serverURL = 'http://13.60.88.192:8082';
  static String? socketURL = 'ws://13.60.88.192:8082/api/socket';
  static String? sessionCookie;
  static String? traccarToken;
  static WebSocketChannel? _webSocket;
  static final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _sessionKey = 'JSESSIONID';
  static const String _tokenKey = 'traccarToken';
  static const String _idKey = 'traccarId';
  static var _traccarId;
  static StreamController<dynamic> _webSocketController = StreamController<dynamic>.broadcast(); // New: StreamController

  static Future<void> saveSessionCookie(String cookie, String token, traccarId) async {
    sessionCookie = cookie;
    traccarToken = token;
    await _secureStorage.write(key: _sessionKey, value: cookie);
    await _secureStorage.write(key: _tokenKey, value: token);

    headers['Cookie'] = sessionCookie!;
    headers["Authorization"] = "Bearer $token";
    print("[Traccar] Session cookie saved: $cookie");
  }

  static Future<void> loadSessionCookie() async {
    sessionCookie = await _secureStorage.read(key: _sessionKey);
    traccarToken = await _secureStorage.read(key: _tokenKey);
    _traccarId = await _secureStorage.read(key: _idKey);
    if (sessionCookie != null) {
      headers['Cookie'] = sessionCookie!;
      //headers["Authorization"] = "Bearer $traccarToken";
      print("[Traccar] Session cookie loaded: $sessionCookie");
      print("[Traccar] Traccar token loaded: $traccarToken");
      print("[Traccar] Traccar Id loaded: $_traccarId");
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

  // static Future<bool> refreshSessionCookie(String token) async {
  //   try {
  //     final response = await http.get(Uri.parse('$serverURL/api/session?token=$token'));
  //     if (response.statusCode == 200) {
  //       updateCookie(response,token);
  //       return true;
  //     }
  //   } catch (e) {
  //     print("Error refreshing session cookie: $e");
  //   }
  //   return false;
  // }

  static Future<http.Response?> loginWithToken(String token) async {

    final uri = Uri.parse("$serverURL/api/session?token=$token");
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final user = jsonDecode(response.body);
      print(user['id']);
        final cookie = response.headers['set-cookie']!.split(';')[0];
        await saveSessionCookie(cookie, token, user['id']);

      return response;
    } else {
      print("Login failed with status: ${response.statusCode}");
      return null;
    }
  }


  //
  // static void updateCookie(http.Response response, String token) {
  //   String? rawCookie = response.headers['set-cookie'];
  //   if (rawCookie != null) {
  //     int index = rawCookie.indexOf(';');
  //     if (index == -1) {
  //       saveSessionCookie(rawCookie,token);
  //     } else {
  //       saveSessionCookie(rawCookie.substring(0, index),token);
  //     }
  //   }
  // }

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
  static Future<Stream<dynamic>?> connectWebSocket() async {
    await loadSessionCookie();
    print("Traccar Session cookie $sessionCookie");

    if (socketURL == null || sessionCookie == null) {
      print("WebSocket connection failed: socketURL or sessionCookie is null.");
      return null;
    }

    // Reinitialize the stream controller if it's null or closed
    if (_webSocketController == null || _webSocketController!.isClosed) {
      _webSocketController = StreamController<dynamic>.broadcast();
    }
    final headers = {
      HttpHeaders.cookieHeader: sessionCookie,
    };
    try {
      final ws = await IOWebSocketChannel.connect(
        socketURL!,
        headers: headers,
      );
      _webSocket = ws;
      print("[Traccar] WebSocket Connected to $socketURL");

      _webSocket!.stream.listen(
            (data) {
          print("[Traccar] WebSocket Data received: $data");
          try {
            final Map<String, dynamic> decodedData = json.decode(data);
            if (decodedData.containsKey('devices')) {
              _webSocketController?.add(Device.fromList(decodedData['devices']));
            } else if (decodedData.containsKey('positions')) {
              _webSocketController?.add(PositionModel.fromList(decodedData['positions']));
            } else if (decodedData.containsKey('events')) {
              _webSocketController?.add(Event.fromList(decodedData['events']));
            } else {
              _webSocketController?.add(data); // Fallback for other data
            }
          } catch (e) {
            print("[Traccar] JSON decode error: $e");
            _webSocketController?.addError(e);
          }
        },
        onError: (error) {
          print("[Traccar] WebSocket Error: $error");
          _webSocketController?.addError(error);
        },
        onDone: () {
          print("[Traccar] WebSocket Disconnected.");
          _webSocketController?.close();
          _webSocket = null;
        },
      );

      return _webSocketController!.stream;
    } catch (e) {
      print("[Traccar] Error connecting WebSocket: $e");
      _webSocketController?.addError(e);
      return null;
    }
  }

  static void disconnectWebSocket() {
    _webSocket?.sink.close();
    _webSocket = null;
    _webSocketController?.close();

    print("[Traccar] WebSocket manually disconnected.");
  }

  static Future<List<Device>?> getDevices() async {
    loadSessionCookie();
    final headers = {"Authorization":"Bearer $traccarToken"};
    try {
      // 1. Construct the Uri
      final uri = Uri.parse('$serverURL/api/devices').replace(
        queryParameters: {
          'userId': _traccarId, // Add the userId as a query parameter
        },
      );

      // 2. Make the HTTP GET request
      final response = await http.get(
        uri, // Use the constructed Uri object
        headers: headers,
      );
      print("Getting traccar devices");
      if (response.statusCode == 200) {
        Iterable list = json.decode(response.body);
        print("traccar devices ${list}");
        return list.map((model) => Device.fromJson(model)).toList();

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