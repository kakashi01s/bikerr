import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../traccar_gennissi.dart'; // Assuming this is needed
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
  static Map<String, String> headers = {}; // Initialize headers map
  static const String _headersKey = 'traccar_all_headers'; // Key for saving the entire headers map
  static var _traccarId; // Internal static variable for traccarId

  // Getter for traccarId to be accessed from outside
  static int? get traccarId => _traccarId;


  // Default Traccar server URL and socket URL
  static String? serverURL = "http://13.60.88.192:8082";
  static String? socketURL = "ws://13.60.88.192:8082/api/websocket";

  // Method to set the Bearer Token and save the entire headers map and traccarId
  static Future<void> setBearerToken(String token, int traccarId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (token.isNotEmpty) {
      headers["Authorization"] = "Bearer $token";
      _traccarId = traccarId; // Set the static variable
      // Save the entire headers map as a JSON string
      await prefs.setString(_headersKey, json.encode(headers));
      await prefs.setInt('traccarId', traccarId); // Save traccarId to local storage
      print("Bearer token set and entire headers map saved locally by Traccar plugin: ${headers['Authorization']}");
      print("Traccar ID saved locally: $traccarId");
    } else {
      print("Received empty token. Authorization header not set and headers not saved.");
      headers.remove('Authorization'); // Clear token if invalid/empty
      await prefs.remove(_headersKey); // Remove from local storage as well
      await prefs.remove('traccarId'); // Also remove traccarId
      _traccarId = null; // Clear the static variable
    }
  }

  // Method to load the entire headers map and traccarId from local storage
  static Future<void> loadBearerToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? storedHeadersJson = prefs.getString(_headersKey);
    if (storedHeadersJson != null && storedHeadersJson.isNotEmpty) {
      try {
        final Map<String, dynamic> decodedHeaders = json.decode(storedHeadersJson);
        headers = decodedHeaders.map((key, value) => MapEntry(key, value.toString()));
        _traccarId = prefs.getInt('traccarId'); // Load traccarId
        print("Headers map loaded from local storage by Traccar plugin.");
        print("Traccar ID loaded from local storage: $_traccarId");
      } catch (e) {
        print("Error decoding stored headers or traccarId: $e");
        await prefs.remove(_headersKey); // Clear corrupted data
        await prefs.remove('traccarId');
        _traccarId = null; // Clear the static variable
      }
    } else {
      print("No headers map found in local storage for Traccar plugin.");
      print("No Traccar ID found in local storage.");
    }
  }

  // Utility to initialize server and socket URLs
  static Future<void> initializeTraccarUrls() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (prefs.containsKey('url')) {
      serverURL = prefs.get('url').toString();
      var uri = Uri.parse(serverURL!);

      String socketScheme;
      if (uri.scheme == "http") {
        socketScheme = "ws://";
      } else {
        socketScheme = "wss://";
      }

      if (uri.hasPort) {
        socketURL =
            socketScheme + uri.host + ":" + uri.port.toString() + "/api/socket";
      } else {
        socketURL = socketScheme + uri.host + "/api/socket";
      }
    } else {
      serverURL = "http://demo.traccar.org"; // Default if not configured
    }
    print("Traccar Server URL: $serverURL");
    print("Traccar Socket URL: $socketURL");
  }

  // Session logout: Clears the headers map and removes it from local storage
  static Future<void> sessionLogout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    headers.clear(); // Clear all headers
    _traccarId = null; // Clear the static variable
    await prefs.remove(_headersKey); // Remove the stored headers map
    await prefs.remove('traccarId'); // Remove traccarId from local storage
    print("Session logout: Headers and Traccar ID cleared locally by Traccar plugin.");
  }


  // --- All other API calls are updated to use 'headers' (which now contains 'Authorization') ---
  // Ensuring all references to 'cookie' are replaced with 'Authorization'

  static Future<List<Device>?> getDevices() async {
    await loadBearerToken(); // Load headers before the call
    print("[Traccar.dart] Running Get devices");
    print("[Traccar.dart] Headers ${headers}");
    print("[Traccar.dart] User Id ${_traccarId}");
    Map<String, String> queryParams = {};

    // Only add userId if _traccarId is available
    if (_traccarId != null) {
      queryParams['userId'] = _traccarId.toString();
    }

    final uri = Uri.http(
      Uri.parse(serverURL!).authority, // Extracts the host and port
      '/api/devices', // Path
      queryParams, // Pass the query parameters map
    );

    final response = await http.get(
      uri, // Use the constructed Uri object
      headers: headers, // Uses the static 'headers' map
    );

    print("Get devices = ${response.body}");
    if (response.statusCode == 200) {
      Iterable list = json.decode(response.body);
      print("Get devices = ${list}");
      return list.map((model) => Device.fromJson(model)).toList();
    } else {
      print("Get devices = ${response.statusCode}");
      return null;
    }
  }

  static Future<List<PositionModel>?> getPositionById(
      String deviceId, String posId) async {
    await loadBearerToken(); // Load headers before the call
    headers['Accept'] = "application/json"; // Add Accept header if necessary
    final response = await http.get(
        Uri.parse(serverURL! +
            "/api/positions?deviceId=" +
            deviceId +
            "&id=" +
            posId),
        headers: headers); // Uses the static 'headers' map
    if (response.statusCode == 200) {
      Iterable list = json.decode(response.body);
      return list.map((model) => PositionModel.fromJson(model)).toList();
    } else {
      print("Get devices = ${response.statusCode}");
      return null;
    }
  }

  static Future<List<PositionModel>?> getPositions(
      String deviceId, String from, String to) async {
    await loadBearerToken(); // Load headers before the call
    headers['Accept'] = "application/json"; // Add Accept header if necessary
    final response = await http.get(
        Uri.parse(serverURL! +
            "/api/positions?deviceId=" +
            deviceId +
            "&from=" +
            from +
            "&to=" +
            to),
        headers: headers); // Uses the static 'headers' map
    if (response.statusCode == 200) {
      Iterable list = json.decode(response.body);
      return list.map((model) => PositionModel.fromJson(model)).toList();
    } else {
      print(response.statusCode);
      return null;
    }
  }

  static Future<List<PositionModel>?> getLatestPositions() async {
    await loadBearerToken(); // Load headers before the call
    headers['Accept'] = "application/json"; // Add Accept header if necessary
    final response = await http.get(Uri.parse(serverURL! + "/api/positions"),
        headers: headers); // Uses the static 'headers' map
    if (response.statusCode == 200) {
      Iterable list = json.decode(response.body);
      return list.map((model) => PositionModel.fromJson(model)).toList();
    } else {
      print(response.statusCode);
      return null;
    }
  }

  static Future<List<Device>?> getDevicesById(String id) async {
    await loadBearerToken(); // Load headers before the call
    final response = await http
        .get(Uri.parse(serverURL! + "/api/devices?id=" + id), headers: headers); // Uses the static 'headers' map
    if (response.statusCode == 200) {
      Iterable list = json.decode(response.body);
      return list.map((model) => Device.fromJson(model)).toList();
    } else {
      print(response.statusCode);
      return null;
    }
  }

  static Future<http.Response> getSendCommands(String id) async {
    await loadBearerToken(); // Load headers before the call
    final response = await http.get(
        Uri.parse(serverURL! + "/api/commands/types?deviceId=" + id),
        headers: headers); // Uses the static 'headers' map
    return response;
  }

  static Future<http.Response> sendCommands(String command) async {
    await loadBearerToken(); // Load headers before the call
    headers['content-type'] = "application/json"; // Ensure correct content type
    final response = await http.post(
        Uri.parse(serverURL! + "/api/commands/send"),
        body: command,
        headers: headers); // Uses the static 'headers' map
    return response;
  }

  static Future<http.Response> updateUser(String user, String id) async {
    await loadBearerToken(); // Load headers before the call
    headers['content-type'] = "application/json; charset=utf-8"; // Ensure correct content type
    final response = await http.put(Uri.parse(serverURL! + "/api/users/" + id),
        body: user, headers: headers); // Uses the static 'headers' map
    return response;
  }

  static Future<List<RouteReport>?> getRoute(
      String deviceId, String from, String to) async {
    await loadBearerToken(); // Load headers before the call
    headers['Accept'] = "application/json"; // Add Accept header if necessary
    final response = await http.get(
        Uri.parse(serverURL! +
            "/api/reports/route?deviceId=" +
            deviceId +
            "&from=" +
            from +
            "&to=" +
            to),
        headers: headers); // Uses the static 'headers' map
    if (response.statusCode == 200) {
      Iterable list = json.decode(response.body);
      return list.map((model) => RouteReport.fromJson(model)).toList();
    } else {
      print(response.statusCode);
      return null;
    }
  }

  static Future<List<NotificationTypeModel>?> getNotificationTypes() async {
    await loadBearerToken(); // Load headers before the call
    headers['Accept'] = "application/json"; // Add Accept header if necessary
    final response = await http.get(
        Uri.parse(serverURL! + "/api/notifications/types"),
        headers: headers); // Uses the static 'headers' map
    if (response.statusCode == 200) {
      Iterable list = json.decode(response.body);
      return list
          .map((model) => NotificationTypeModel.fromJson(model))
          .toList();
    } else {
      print(response.statusCode);
      return null;
    }
  }

  static Future<List<Event>?> getEvents(
      String deviceId, String from, String to) async {
    await loadBearerToken(); // Load headers before the call
    headers['Accept'] = "application/json"; // Add Accept header if necessary
    final response = await http.get(
        Uri.parse(serverURL! +
            "/api/reports/events?deviceId=" +
            deviceId +
            "&from=" +
            from +
            "&to=" +
            to),
        headers: headers); // Uses the static 'headers' map
    if (response.statusCode == 200) {
      Iterable list = json.decode(response.body);
      return list.map((model) => Event.fromJson(model)).toList();
    } else {
      print(response.statusCode);
      return null;
    }
  }

  static Future<Event?> getEventById(String id) async {
    await loadBearerToken(); // Load headers before the call
    headers['Accept'] = "application/json"; // Add Accept header if necessary
    final response = await http.get(Uri.parse(serverURL! + "/api/events/" + id),
        headers: headers); // Uses the static 'headers' map
    if (response.statusCode == 200) {
      return Event.fromJson(json.decode(response.body));
    } else {
      print(response.statusCode);
      return null;
    }
  }

  static Future<List<Event>?> getAllDeviceEvents(
      var deviceId, String from, String to) async {
    await loadBearerToken(); // Load headers before the call
    var uri =
    Uri(queryParameters: {'deviceId': deviceId.toString(), 'from': from, 'to': to}); // Ensure deviceId is string
    headers['Accept'] = "application/json"; // Add Accept header if necessary
    final response = await http.get(
        Uri.parse(serverURL! + "/api/reports/events" + uri.toString()),
        headers: headers); // Uses the static 'headers' map
    if (response.statusCode == 200) {
      Iterable list = json.decode(response.body);
      return list.map((model) => Event.fromJson(model)).toList();
    } else {
      print(response.statusCode);
      return null;
    }
  }

  static Future<List<Trip>?> getTrip(
      String deviceId, String from, String to) async {
    await loadBearerToken(); // Load headers before the call
    headers['Accept'] = "application/json"; // Add Accept header if necessary
    final response = await http.get(
        Uri.parse(serverURL! +
            "/api/reports/trips?deviceId=" +
            deviceId +
            "&from=" +
            from +
            "&to=" +
            to),
        headers: headers); // Uses the static 'headers' map
    if (response.statusCode == 200) {
      Iterable list = json.decode(response.body);
      return list.map((model) => Trip.fromJson(model)).toList();
    } else {
      print(response.statusCode);
      return null;
    }
  }

  static Future<List<Stop>?> getStops(
      String deviceId, String from, String to) async {
    await loadBearerToken(); // Load headers before the call
    headers['Accept'] = "application/json"; // Add Accept header if necessary
    final response = await http.get(
        Uri.parse(serverURL! +
            "/api/reports/stops?deviceId=" +
            deviceId +
            "&from=" +
            from +
            "&to=" +
            to),
        headers: headers); // Uses the static 'headers' map
    if (response.statusCode == 200) {
      Iterable list = json.decode(response.body);
      return list.map((model) => Stop.fromJson(model)).toList();
    } else {
      print(response.statusCode);
      return null;
    }
  }

  static Future<List<Summary>?> getSummary(
      String deviceId, String from, String to) async {
    await loadBearerToken(); // Load headers before the call
    headers['Accept'] = "application/json"; // Add Accept header if necessary
    final response = await http.get(
        Uri.parse(serverURL! +
            "/api/reports/summary?deviceId=" +
            deviceId +
            "&from=" +
            from +
            "&to=" +
            to),
        headers: headers); // Uses the static 'headers' map
    if (response.statusCode == 200) {
      Iterable list = json.decode(response.body);
      return list.map((model) => Summary.fromJson(model)).toList();
    } else {
      print(response.statusCode);
      return null;
    }
  }

  static Future<List<GeofenceModel>?> getGeoFencesByUserID(
      String userID) async {
    await loadBearerToken(); // Load headers before the call
    headers['Accept'] = "application/json"; // Add Accept header if necessary
    final response = await http.get(
        Uri.parse(serverURL! + "/api/geofences?userId=" + userID),
        headers: headers); // Uses the static 'headers' map
    if (response.statusCode == 200) {
      Iterable list = json.decode(response.body);
      return list.map((model) => GeofenceModel.fromJson(model)).toList();
    } else {
      print(response.statusCode);
      return null;
    }
  }

  static Future<List<GeofenceModel>?> getGeoFencesByDeviceID(
      String deviceId) async {
    await loadBearerToken(); // Load headers before the call
    headers['Accept'] = "application/json"; // Add Accept header if necessary
    final response = await http.get(
        Uri.parse(serverURL! + "/api/geofences?deviceId=" + deviceId),
        headers: headers); // Uses the static 'headers' map
    if (response.statusCode == 200) {
      Iterable list = json.decode(response.body);
      return list.map((model) => GeofenceModel.fromJson(model)).toList();
    } else {
      print(response.statusCode);
      return null;
    }
  }

  static Future<http.Response> addGeofence(String fence) async {
    await loadBearerToken(); // Load headers before the call
    headers['content-type'] = "application/json; charset=utf-8"; // Ensure correct content type
    final response = await http.post(Uri.parse(serverURL! + "/api/geofences"),
        body: fence, headers: headers); // Uses the static 'headers' map
    return response;
  }

  static Future<http.Response> addDevice(String device) async {
    await loadBearerToken(); // Load headers before the call
    headers['content-type'] = "application/json; charset=utf-8"; // Ensure correct content type
    final response = await http.post(Uri.parse(serverURL! + "/api/devices"),
        body: device, headers: headers); // Uses the static 'headers' map
    return response;
  }

  static Future<http.Response> updateGeofence(String fence, String id) async {
    await loadBearerToken(); // Load headers before the call
    headers['content-type'] = "application/json; charset=utf-8"; // Ensure correct content type
    final response = await http.put(
        Uri.parse(serverURL! + "/api/geofences/" + id),
        body: fence,
        headers: headers); // Uses the static 'headers' map
    return response;
  }

  static Future<http.Response> updateDevices(String fence, String id) async {
    await loadBearerToken(); // Load headers before the call
    headers['content-type'] = "application/json; charset=utf-8"; // Ensure correct content type
    final response = await http.put(
        Uri.parse(serverURL! + "/api/devices/" + id),
        body: fence,
        headers: headers); // Uses the static 'headers' map
    return response;
  }

  static Future<http.Response> addPermission(String permission) async {
    await loadBearerToken(); // Load headers before the call
    headers['content-type'] = "application/json; charset=utf-8"; // Ensure correct content type
    final response = await http.post(Uri.parse(serverURL! + "/api/permissions"),
        body: permission, headers: headers); // Uses the static 'headers' map
    return response;
  }

  static Future<StreamedResponse> deletePermission(dynamic deviceId, dynamic geofenceId) async { // Corrected argument name
    await loadBearerToken(); // Load headers before the call
    http.Request rq =
    http.Request('DELETE', Uri.parse(serverURL! + "/api/permissions"));
    rq.headers.addAll(<String, String>{
      "Accept": "application/json",
      "Content-type": "application/json; charset=utf-8",
      "Authorization": headers['Authorization'].toString() // Use Authorization header
    });
    rq.body = jsonEncode({"deviceId": deviceId, "geofenceId": geofenceId}); // Corrected key for consistency

    return http.Client().send(rq);
  }

  static Future<http.Response> deleteGeofence(dynamic id) async {
    await loadBearerToken(); // Load headers before the call
    headers['content-type'] = "application/json; charset=utf-8"; // Ensure correct content type
    final response = await http
        .delete(Uri.parse(serverURL! + "/api/geofences/$id"), headers: headers); // Uses the static 'headers' map
    return response;
  }

  static Future<http.Response?> geocode(String lat, String lng) async {
    await loadBearerToken(); // Load headers before the call
    headers['Accept'] = "application/json"; // Add Accept header if necessary
    final response = await http.get(
        Uri.parse(
            serverURL! + "/api/server/geocode?latitude=$lat&longitude=$lng"),
        headers: headers); // Uses the static 'headers' map
    if (response.statusCode == 200) {
      return response;
    } else {
      print(response.statusCode);
      return null;
    }
  }


  static Future<List<NotificationModel>?> getNotifications() async {
    await loadBearerToken(); // Load headers before the call
    headers['Accept'] = "application/json"; // Add Accept header if necessary
    final response = await http.get(
        Uri.parse(serverURL! + "/api/notifications"),
        headers: headers); // Uses the static 'headers' map
    if (response.statusCode == 200) {
      Iterable list = json.decode(response.body);
      return list
          .map((model) => NotificationModel.fromJson(model))
          .toList();
    } else {
      print(response.statusCode);
      return null;
    }
  }

  static Future<NotificationModel?> addNotifications(String notification) async {
    await loadBearerToken(); // Load headers before the call
    headers['Accept'] = "application/json"; // Add Accept header if necessary
    final response = await http.post(
        Uri.parse(serverURL! + "/api/notifications"),
        body: notification,
        headers: headers); // Uses the static 'headers' map
    if (response.statusCode == 200) {
      return NotificationModel.fromJson(json.decode(response.body));
    } else {
      print(response.statusCode);
      return null;
    }
  }

  static Future<http.Response> deleteNotifications(String id) async {
    await loadBearerToken(); // Load headers before the call
    headers['content-type'] = "application/json; charset=utf-8"; // Ensure correct content type
    final response = await http
        .delete(Uri.parse(serverURL! + "/api/notifications/$id"), headers: headers); // Uses the static 'headers' map
    return response;
  }

  static Future<List<CommandModel>?> getSavedCommands(id) async {
    await loadBearerToken(); // Load headers before the call
    final response = await http.get(
        Uri.parse(serverURL! + "/api/commands/send?deviceId=" + id.toString()),
        headers: headers); // Uses the static 'headers' map
    if (response.statusCode == 200) {
      Iterable list = json.decode(response.body);
      return list.map((model) => CommandModel.fromJson(model)).toList();
    } else {
      print(response.statusCode);
      return null;
    }
  }

  static Future<List<MaintenanceModel>?> getMaintenance() async {
    await loadBearerToken(); // Load headers before the call
    final response = await http.get(
        Uri.parse(serverURL! + "/api/maintenance"),
        headers: headers); // Uses the static 'headers' map
    if (response.statusCode == 200) {
      Iterable list = json.decode(response.body);
      return list.map((model) => MaintenanceModel.fromJson(model)).toList();
    } else {
      print(response.statusCode);
      return null;
    }
  }

  static Future<List<MaintenanceModel>?> getMaintenanceByDeviceId(String id) async {
    await loadBearerToken(); // Load headers before the call
    final response = await http.get(
        Uri.parse(serverURL! + "/api/maintenance?deviceId=" + id.toString()),
        headers: headers); // Uses the static 'headers' map
    if (response.statusCode == 200) {
      print(response.body);
      Iterable list = json.decode(response.body);
      return list.map((model) => MaintenanceModel.fromJson(model)).toList();
    } else {
      print(response.statusCode);
      return null;
    }
  }

  static Future<http.Response> deleteMaintenance(dynamic id) async {
    await loadBearerToken(); // Load headers before the call
    headers['content-type'] = "application/json; charset=utf-8"; // Ensure correct content type
    final response = await http
        .delete(Uri.parse(serverURL! + "/api/maintenance/$id"), headers: headers); // Uses the static 'headers' map
    return response;
  }

  static Future<http.Response> addMaintenance(String m) async {
    await loadBearerToken(); // Load headers before the call
    headers['content-type'] = "application/json; charset=utf-8"; // Ensure correct content type
    final response = await http.post(Uri.parse(serverURL! + "/api/maintenance"),
        body: m, headers: headers); // Uses the static 'headers' map
    print(response.body);
    return response;
  }

  static Future<http.Response> updateMaintenance(String m) async {
    await loadBearerToken(); // Load headers before the call
    headers['content-type'] = "application/json; charset=utf-8"; // Ensure correct content type
    final response = await http.post(Uri.parse(serverURL! + "/api/maintenance"),
        body: m, headers: headers); // Uses the static 'headers' map
    print(response.body);
    return response;
  }

  static Future<StreamedResponse> deleteMaintenancePermission(deviceId, maintenanceId) async { // Corrected argument name
    await loadBearerToken(); // Load headers before the call
    http.Request rq =
    http.Request('DELETE', Uri.parse(serverURL! + "/api/permissions"));
    rq.headers.addAll(<String, String>{
      "Accept": "application/json",
      "Content-type": "application/json; charset=utf-8",
      "Authorization": headers['Authorization'].toString() // Use Authorization header
    });
    rq.body = jsonEncode({"deviceId": deviceId, "maintenanceId": maintenanceId});

    return http.Client().send(rq);
  }
}