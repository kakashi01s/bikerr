import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionManager {
  SessionManager._internal();

  static final SessionManager _instance = SessionManager._internal();

  static SessionManager get instance => _instance;

  final storage = const FlutterSecureStorage();

  // --- Made properties explicitly nullable ---
  String? userId;
  int? traccarId; // Assuming traccarId is an integer
  String? jwtRefreshToken;
  String? jwtAccessToken;
  String? traccarToken;
  // Removed expiryDate related code
  // ------------------------------------------

  Future<void> setSession({
    // --- Accept nullable types ---
    required String? userId,
    required int? traccarId, // Accept nullable int
    required String? jwtRefreshToken,
    required String? jwtAccessToken,
    required String? traccarToken,
    // -----------------------------
  }) async {
    // Assign to properties
    this.userId = userId;
    this.traccarId = traccarId;
    this.jwtRefreshToken = jwtRefreshToken;
    this.jwtAccessToken = jwtAccessToken;
    this.traccarToken = traccarToken;

    // Write to storage (storage.write handles null by deleting the key)
    await Future.wait([
      storage.write(key: "userId", value: userId),
      // Convert int? to String? for storage
      storage.write(key: "traccarId", value: traccarId?.toString()),
      storage.write(key: "jwtRefreshToken", value: jwtRefreshToken),
      storage.write(key: "jwtAccessToken", value: jwtAccessToken),
      storage.write(key: "traccarToken", value: traccarToken),
    ]);
  }

  Future<void> getSession() async {
    // Read from storage (returns String?)
    final response = await Future.wait([
      storage.read(key: 'userId'),
      storage.read(key: 'traccarId'),
      storage.read(key: 'jwtRefreshToken'),
      storage.read(key: 'jwtAccessToken'),
      storage.read(key: 'traccarToken'),

    ]);

    // Assign and parse as necessary
    userId = response[0];
    // Parse traccarId from String? to int?
    traccarId = response[1] != null ? int.tryParse(response[1]!) : null;
    jwtRefreshToken = response[2];
    jwtAccessToken = response[3];
    traccarToken = response[4];
  }

  Future<void> clearSession() async {
    // Set properties to null
    userId = null;
    traccarId = null;
    jwtRefreshToken = null;
    jwtAccessToken = null;
    traccarToken = null;

    // Delete keys from storage
    await Future.wait([
      storage.delete(key: 'userId'),
      storage.delete(key: 'traccarId'),
      storage.delete(key: 'jwtRefreshToken'),
      storage.delete(key: 'jwtAccessToken'),
      storage.delete(key: 'traccarToken'),

    ]);
  }

  Future<void> updateAccessToken(String? token) async {
    // Accept nullable token
    jwtAccessToken = token;
    // storage.write handles null by deleting the key
    await storage.write(key: "jwtAccessToken", value: token);
  }

  // Optional: Add getters for convenience, ensuring type safety
  // For example:
  // String? get getUserId => userId;
  // int? get getTraccarId => traccarId;
  // String? get getRefreshToken => jwtRefreshToken;
  // String? get getAccessToken => jwtAccessToken;

  // Check if the user is currently authenticated (has an access token)
  bool isAuthenticated() {
    // Consider if you need to check refresh token presence as well
    return jwtAccessToken != null && jwtAccessToken!.isNotEmpty;
  }
}
