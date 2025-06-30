import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:traccar_gennissi/traccar_gennissi.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class Traccar {

  static const _cookieKey = 'traccar_cookie';
  static const _tokenKey = 'traccar_token';
  static const _idKey = 'traccar_id';

  static final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static StreamController<dynamic> _webSocketController = StreamController<dynamic>.broadcast();

  static String? serverURL = 'http://13.60.88.192:8082';
  static String? socketURL = 'ws://13.60.88.192:8082/api/socket';
  static String? sessionCookie;
  static int? _traccarId;
  static String? _traccarToken;

  static WebSocketChannel? _webSocket;

  static Map<String, String> get defaultHeaders => {
    // 'Content-Type': 'application/json',
    if (sessionCookie != null) 'Cookie': sessionCookie!,
    if (_traccarToken != null) 'Authorization': 'Bearer $_traccarToken',
  };

  static Future<void> saveSessionCookie(String sessionCookie, String traccarToken, int traccarId) async {
    print('[Traccar] Saving cookie $sessionCookie');
    await _secureStorage.write(key: _cookieKey, value: sessionCookie);
    await _secureStorage.write(key: _tokenKey, value: traccarToken);
    await _secureStorage.write(key: _idKey, value: traccarId.toString());

    _traccarToken = traccarToken;
    _traccarId = traccarId;
  }

  static Future<void> loadSessionCookieAndBearerToken() async {
    _traccarToken ??= await _secureStorage.read(key: _tokenKey);
    sessionCookie ??= await _secureStorage.read(key: _cookieKey);
    final idStr = await _secureStorage.read(key: _idKey);
    _traccarId ??= idStr != null ? int.tryParse(idStr) : null;

    if (_traccarToken != null) {
      defaultHeaders['Authorization'] = 'Bearer $_traccarToken';
    }
  }
  static Future<void> clearSession() async {
    await _secureStorage.delete(key: _cookieKey);
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _idKey);
    _traccarToken = null;
    _traccarId = null;
    defaultHeaders.remove('Authorization');
  }


  static Future<Stream<dynamic>?> connectWebSocket() async {
    await loadSessionCookieAndBearerToken();

    print("Socket Url$socketURL");
    print("Session Cookie$sessionCookie");

    if (socketURL == null || sessionCookie == null) {
      print("[Traccar] WebSocket connection failed: Missing URL or session.");
      return null;
    }



    try {
      final ws = IOWebSocketChannel.connect(
        socketURL!,
        headers: {HttpHeaders.cookieHeader: sessionCookie!},
      );
      _webSocket = ws;


      print("[Traccar] WebSocket connected.");


      if (_webSocketController.isClosed) {
        _webSocketController = StreamController<dynamic>.broadcast();
      }

      _webSocket!.stream.listen(
            (data) {

              if (_webSocketController.isClosed) {
                print("[Traccar] WebSocket data received after controller closed. Ignoring.");
                return; // Crucial check
              }
         // print("[Traccar] WebSocket data: $data");
          try {
            final decoded = json.decode(data);
            if (decoded.containsKey('devices')) {
              _webSocketController.add(decoded['devices'].map((model) => Device.fromJson(model)).toList());
             // _webSocketController.add(Device.fromList(decoded['devices']));
            } else if (decoded.containsKey('positions')) {
              _webSocketController.add(PositionModel.fromList(decoded['positions']));
            } else if (decoded.containsKey('events')) {
              _webSocketController.add(Event.fromList(decoded['events']));
            } else {
              _webSocketController.add(data);
            }
          } catch (e) {
            if (!_webSocketController.isClosed) { // Another crucial check
              _webSocketController.addError(e);
            } else {
              print("[Traccar] WebSocket data decoding error, but controller already closed. Error: $e. Data: $data");
            }
          }
        },
        onError: (e) {
          if (!_webSocketController.isClosed) { // Crucial check
            print("[Traccar] WebSocket error: $e");
            _webSocketController.addError(e);
          } else {
            print("[Traccar] WebSocket error, but controller already closed. Error: $e");
          }
          // You might want to close the WebSocket sink here too on error
          _webSocket?.sink.close();
          _webSocket = null; // Clear the reference
        },
        onDone: () {
          print("[Traccar] WebSocket disconnected.");
          if (!_webSocketController.isClosed) { // Crucial check to avoid double-close error
            _webSocketController.close();
          }
          _webSocket = null; // Clear the reference
        },
      );

      return _webSocketController.stream;
    } catch (e) {
      print("[Traccar] WebSocket connect error: $e");
      if (!_webSocketController.isClosed) { // Ensure controller is closed if connection fails
        _webSocketController.close();
      }
      return null;
    }
  }





  static Future<bool> sessionLogout() async {
    try {
      final response = await http.delete(
        Uri.parse('$serverURL/api/session'),
        headers: defaultHeaders,
      );
      if (response.statusCode == 204) {
        await clearSession();
        disconnectWebSocket();
        return true;
      } else {
        print("Logout failed: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("Logout error: $e");
      return false;
    }
  }
  static void disconnectWebSocket() {
    _webSocket?.sink.close();
    _webSocket = null;
    if (!_webSocketController.isClosed) _webSocketController.close();
    print("[Traccar] WebSocket manually disconnected.");
  }

  static Future<List<Device>?> getDevices() async {
    // Ensure session cookie or bearer token is loaded for authentication
    await loadSessionCookieAndBearerToken();

    // Log authentication details being used (for debugging)
    print("[Traccar] Attempting to get devices...");
    print("[Traccar] Current session cookie: $sessionCookie");
    print("[Traccar] Current Bearer Token: ${_traccarToken != null ? 'Present' : 'Not Present'}");
    print("[Traccar] Authenticated User ID: $_traccarId");


    // Construct the URI for the devices endpoint.
    // The `/api/devices` endpoint typically returns devices accessible by the
    // authenticated user based on the session cookie or Authorization header.
    // Adding `userId` as a query parameter is usually NOT necessary/correct for this endpoint
    // unless your Traccar setup has specific customizations.
    final uri = Uri.parse('$serverURL/api/devices').replace(queryParameters: {'userId': '$_traccarId'});

    try {
      final response = await http.get(uri, headers: defaultHeaders);

      print("[Traccar] Get Devices Response Status: ${response.statusCode}");
      print("[Traccar] Get Devices Response Body: ${response.body}");
      print("[Traccar] Get Devices Response Headers: ${response.headers}");


      if (response.statusCode == 200) {
        // Decode the JSON array from the response body
        final List<dynamic> jsonList = json.decode(response.body);

        // Map each JSON object to a Device model instance
        List<Device> devices = jsonList.map((model) => Device.fromJson(model as Map<String, dynamic>)).toList();

        print("[Traccar] Successfully retrieved ${devices.length} devices.");
        return devices;
      } else {
        // Handle API error responses
        print("[Traccar] Get Devices API Error: Status ${response.statusCode}");
        print("[Traccar] Error response body: ${response.body}");
        // You might want to throw an exception or return a specific error object here
        return null;
      }
    } catch (e) {
      // Handle network errors or other exceptions
      print("[Traccar] Get Devices Network/Unexpected Error: $e");
      if (e is SocketException) {
        print("[Traccar] Possible network issue or server not reachable.");
      } else if (e is FormatException) {
        print("[Traccar] Response body was not valid JSON.");
      }
      return null;
    }
  }




  static Future<PositionModel?> getPositionById(String posId) async {
    await loadSessionCookieAndBearerToken();
    final uri = Uri.parse('$serverURL/api/positions').replace(queryParameters: {'id': '$posId'});

    try {

      final response = await http.get(uri, headers: defaultHeaders);


      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("getPositionById: data: $data");
        if (data is List && data.isNotEmpty) {
          final lastPosition = data.last;
          if (lastPosition is Map<String, dynamic>) {
            return PositionModel.fromJson(lastPosition);
          } else {
            print("getPositionById: Unexpected item format in list: $lastPosition");
          }
        } else {
          print("getPositionById: No position data found or unexpected format");
        }
      } else {
        print("getPositionById failed: ${response.statusCode}");
      }
    } catch (e) {
      print("Error in getPositionById: $e");
    }

    return null;
  }

  static Future<List<PositionModel>?> getPositions(String deviceId, String from, String to) async {
    await loadSessionCookieAndBearerToken();
    try {
      final uri = Uri.parse('$serverURL/api/reports/positions?deviceId=$deviceId&from=$from&to=$to');
      final response = await http.get(uri, headers: defaultHeaders);
      if (response.statusCode == 200) {
        return PositionModel.fromList(json.decode(response.body));
      }
      print("getPositions failed: ${response.statusCode}");
    } catch (e) {
      print("Error in getPositions: $e");
    }
    return null;
  }

  static Future<List<PositionModel>?> getLatestPositions() async {
    await loadSessionCookieAndBearerToken();
    try {
      final response = await http.get(
        Uri.parse('$serverURL/api/positions'),
        headers: defaultHeaders,
      );
      if (response.statusCode == 200) {
        return PositionModel.fromList(json.decode(response.body));
      }
      print("getLatestPositions failed: ${response.statusCode}");
    } catch (e) {
      print("Error in getLatestPositions: $e");
    }
    return null;
  }

  static Future<Device?> getDevicesById(String id) async {
    await loadSessionCookieAndBearerToken();
    try {
      final response = await http.get(
        Uri.parse('$serverURL/api/devices/$id'),
        headers: defaultHeaders,
      );
      if (response.statusCode == 200) {
        return Device.fromJson(json.decode(response.body));
      }
      print("getDevicesById failed: ${response.statusCode}");
    } catch (e) {
      print("Error in getDevicesById: $e");
    }
    return null;
  }

  static Future<List<String>?> getSendCommands(String id) async {
    await loadSessionCookieAndBearerToken();
    try {
      final response = await http.get(
        Uri.parse('$serverURL/api/commands/types?deviceId=$id'),
        headers: defaultHeaders,
      );
      if (response.statusCode == 200) {
        return List<String>.from(json.decode(response.body));
      }
      print("getSendCommands failed: ${response.statusCode}");
    } catch (e) {
      print("Error in getSendCommands: $e");
    }
    return null;
  }

  static Future<List<RouteReport>?> getRoute(String deviceId, String from, String to) async {
    await loadSessionCookieAndBearerToken();
    try {
      final response = await http.get(
        Uri.parse('$serverURL/api/reports/route?deviceId=$deviceId&from=$from&to=$to'),
        headers: defaultHeaders,
      );
      if (response.statusCode == 200) {
        Iterable list = json.decode(response.body);
        return list.map((e) => RouteReport.fromJson(e)).toList();
      }
      print("getRoute failed: ${response.statusCode}");
    } catch (e) {
      print("Error in getRoute: $e");
    }
    return null;
  }

  static Future<List<Event>?> getEvents(String deviceId, String from, String to) async {
    await loadSessionCookieAndBearerToken();
    try {
      final uri = Uri.parse('$serverURL/api/reports/events?deviceId=$deviceId&from=$from&to=$to');
      final response = await http.get(uri, headers: defaultHeaders);
      if (response.statusCode == 200) {
        Iterable list = json.decode(response.body);
        return list.map((e) => Event.fromJson(e)).toList();
      }
      print("getEvents failed: ${response.statusCode}");
    } catch (e) {
      print("Error in getEvents: $e");
    }
    return null;
  }

  static Future<Event?> getEventById(String id) async {
    await loadSessionCookieAndBearerToken();
    try {
      final response = await http.get(
        Uri.parse('$serverURL/api/events/$id'),
        headers: defaultHeaders,
      );
      if (response.statusCode == 200) {
        return Event.fromJson(json.decode(response.body));
      }
      print("getEventById failed: ${response.statusCode}");
    } catch (e) {
      print("Error in getEventById: $e");
    }
    return null;
  }

  static Future<List<Trip>?> getTrip(String deviceId, String from, String to) async {
    await loadSessionCookieAndBearerToken();
    try {
      final uri = Uri.parse('$serverURL/api/reports/trips?deviceId=$deviceId&from=$from&to=$to');
      final response = await http.get(uri, headers: defaultHeaders);
      if (response.statusCode == 200) {
        Iterable list = json.decode(response.body);
        return list.map((e) => Trip.fromJson(e)).toList();
      }
      print("getTrip failed: ${response.statusCode}");
    } catch (e) {
      print("Error in getTrip: $e");
    }
    return null;
  }

  static Future<List<Stop>?> getStops(String deviceId, String from, String to) async {
    await loadSessionCookieAndBearerToken();
    try {
      final response = await http.get(
        Uri.parse('$serverURL/api/reports/stops?deviceId=$deviceId&from=$from&to=$to'),
        headers: defaultHeaders,
      );
      if (response.statusCode == 200) {
        Iterable list = json.decode(response.body);
        return list.map((e) => Stop.fromJson(e)).toList();
      }
      print("getStops failed: ${response.statusCode}");
    } catch (e) {
      print("Error in getStops: $e");
    }
    return null;
  }

  static Future<Summary?> getSummary(String deviceId, String from, String to) async {
    await loadSessionCookieAndBearerToken();
    try {
      final response = await http.get(
        Uri.parse('$serverURL/api/reports/summary?deviceId=$deviceId&from=$from&to=$to'),
        headers: defaultHeaders,
      );
      if (response.statusCode == 200) {
        return Summary.fromJson(json.decode(response.body));
      }
      print("getSummary failed: ${response.statusCode}");
    } catch (e) {
      print("Error in getSummary: $e");
    }
    return null;
  }

  static Future<List<NotificationTypeModel>?> getNotificationTypes() async {
    await loadSessionCookieAndBearerToken();
    try {
      final response = await http.get(
        Uri.parse('$serverURL/api/notifications/types'),
        headers: defaultHeaders,
      );
      if (response.statusCode == 200) {
        Iterable list = json.decode(response.body);
        return list.map((e) => NotificationTypeModel.fromJson(e)).toList();
      }
      print("getNotificationTypes failed: ${response.statusCode}");
    } catch (e) {
      print("Error in getNotificationTypes: $e");
    }
    return null;
  }

  static Future<String?> sendCommands(String commandJson) async {
    await loadSessionCookieAndBearerToken();
    try {
      final response = await http.post(
        Uri.parse('$serverURL/api/commands'),
        headers: defaultHeaders,
        body: commandJson,
      );
      return response.statusCode == 200 ? response.body : null;
    } catch (e) {
      print("Error sending command: $e");
      return null;
    }
  }

  static Future<String?> updateUser(String userJson, String id) async {
    await loadSessionCookieAndBearerToken();
    try {
      final response = await http.put(
        Uri.parse('$serverURL/api/users/$id'),
        headers: defaultHeaders,
        body: userJson,
      );
      return response.statusCode == 200 ? response.body : null;
    } catch (e) {
      print("Error updating user: $e");
      return null;
    }
  }
  static Future<String?> addDevice(String deviceJson) async {
    await loadSessionCookieAndBearerToken();
    try {
      final response = await http.post(
        Uri.parse('$serverURL/api/devices'),
        headers: defaultHeaders,
        body: deviceJson,
      );
      return response.statusCode == 200 ? response.body : null;
    } catch (e) {
      print("Error adding device: $e");
      return null;
    }
  }

  static Future<String?> updateDevice(String deviceJson, String id) async {
    await loadSessionCookieAndBearerToken();
    try {
      final response = await http.put(
        Uri.parse('$serverURL/api/devices/$id'),
        headers: defaultHeaders,
        body: deviceJson,
      );
      return response.statusCode == 200 ? response.body : null;
    } catch (e) {
      print("Error updating device: $e");
      return null;
    }
  }

  static Future<bool> addPermission(String permissionJson) async {
    await loadSessionCookieAndBearerToken();
    try {
      final response = await http.post(
        Uri.parse('$serverURL/api/permissions'),
        headers: defaultHeaders,
        body: permissionJson,
      );
      return response.statusCode == 204;
    } catch (e) {
      print("Error adding permission: $e");
      return false;
    }
  }

  static Future<bool> deletePermission(String permissionJson) async {
    await loadSessionCookieAndBearerToken();
    try {
      final response = await http.post(
        Uri.parse('$serverURL/api/permissions/delete'),
        headers: defaultHeaders,
        body: permissionJson,
      );
      return response.statusCode == 204;
    } catch (e) {
      print("Error deleting permission: $e");
      return false;
    }
  }  static Future<bool> deleteDevice(int id) async {
    await loadSessionCookieAndBearerToken();
    try {
      final response = await http.delete(
        Uri.parse('$serverURL/api/devices/$id'),
        headers: defaultHeaders

      );
      return response.statusCode == 204;
    } catch (e) {
      print("Error deleting device: $e");
      return false;
    }
  }
  static Future<String?> addGeofence(String geofenceJson) async {
    await loadSessionCookieAndBearerToken();
    try {
      final response = await http.post(
        Uri.parse('$serverURL/api/geofences'),
        headers: defaultHeaders,
        body: geofenceJson,
      );
      return response.statusCode == 200 ? response.body : null;
    } catch (e) {
      print("Error adding geofence: $e");
      return null;
    }
  }

  static Future<String?> updateGeofence(String geofenceJson, String id) async {
    await loadSessionCookieAndBearerToken();
    try {
      final response = await http.put(
        Uri.parse('$serverURL/api/geofences/$id'),
        headers: defaultHeaders,
        body: geofenceJson,
      );
      return response.statusCode == 200 ? response.body : null;
    } catch (e) {
      print("Error updating geofence: $e");
      return null;
    }
  }

  static Future<bool> deleteGeofence(String id) async {
    await loadSessionCookieAndBearerToken();
    try {
      final response = await http.delete(
        Uri.parse('$serverURL/api/geofences/$id'),
        headers: defaultHeaders,
      );
      return response.statusCode == 204;
    } catch (e) {
      print("Error deleting geofence: $e");
      return false;
    }
  }

  static Future<List<GeofenceModel>?> getGeoFencesByUserID(String userId) async {
    await loadSessionCookieAndBearerToken();
    try {
      final uri = Uri.parse('$serverURL/api/geofences?userId=$userId');
      final response = await http.get(uri, headers: defaultHeaders);
      if (response.statusCode == 200) {
        Iterable list = json.decode(response.body);
        return list.map((e) => GeofenceModel.fromJson(e)).toList();
      }
      print("getGeoFencesByUserID failed: ${response.statusCode}");
    } catch (e) {
      print("Error in getGeoFencesByUserID: $e");
    }
    return null;
  }

  static Future<List<GeofenceModel>?> getGeoFencesByDeviceID(String deviceId) async {
    await loadSessionCookieAndBearerToken();
    try {
      final uri = Uri.parse('$serverURL/api/geofences?deviceId=$deviceId');
      final response = await http.get(uri, headers: defaultHeaders);
      if (response.statusCode == 200) {
        Iterable list = json.decode(response.body);
        return list.map((e) => GeofenceModel.fromJson(e)).toList();
      }
      print("getGeoFencesByDeviceID failed: ${response.statusCode}");
    } catch (e) {
      print("Error in getGeoFencesByDeviceID: $e");
    }
    return null;
  }
  static Future<String?> addNotification(String notificationJson) async {
    await loadSessionCookieAndBearerToken();
    try {
      final response = await http.post(
        Uri.parse('$serverURL/api/notifications'),
        headers: defaultHeaders,
        body: notificationJson,
      );
      return response.statusCode == 200 ? response.body : null;
    } catch (e) {
      print("Error adding notification: $e");
      return null;
    }
  }

  static Future<bool> deleteNotification(String id) async {
    await loadSessionCookieAndBearerToken();
    try {
      final response = await http.delete(
        Uri.parse('$serverURL/api/notifications/$id'),
        headers: defaultHeaders,
      );
      return response.statusCode == 204;
    } catch (e) {
      print("Error deleting notification: $e");
      return false;
    }
  }

  static Future<List<NotificationModel>?> getNotifications(String userId) async {
    await loadSessionCookieAndBearerToken();
    try {
      final uri = Uri.parse('$serverURL/api/notifications?userId=$userId');
      final response = await http.get(uri, headers: defaultHeaders);
      if (response.statusCode == 200) {
        Iterable list = json.decode(response.body);
        return list.map((e) => NotificationModel.fromJson(e)).toList();
      }
      print("getNotifications failed: ${response.statusCode}");
    } catch (e) {
      print("Error in getNotifications: $e");
    }
    return null;
  }
}

