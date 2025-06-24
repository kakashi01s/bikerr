// In lib/utils/network/network_api_services.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:bikerr/config/constants.dart';
import 'package:bikerr/services/session/session_manager.dart';
import 'package:http/http.dart' as http;
import 'package:bikerr/utils/exceptions/app_exceptions.dart'; // Import the updated exceptions file
import 'package:bikerr/utils/network/base_api_services.dart';

class NetworkServicesApi implements BaseApiServices {
  final client = http.Client();

  // Implementations for getApi, postApi, putApi, patchApi, deleteApi remain the same,
  // they just call _sendRequest.

  @override
  Future<http.Response> getApi(
    String url, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return await _sendRequest((headers) {
      Uri uri = Uri.parse(url);
      if (queryParameters != null && queryParameters.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParameters);
      }
      return client.get(uri, headers: headers);
    });
  }

  @override
  Future<http.Response> postApi(String url, data) async {
    return await _sendRequest((headers) {
      return client.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(data),
      );
    });
  }

  @override
  Future<http.Response> putApi(String url, data) async {
    return await _sendRequest((headers) {
      return client.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(data),
      );
    });
  }

  @override
  Future<http.Response> patchApi(String url, data) async {
    return await _sendRequest((headers) {
      return client.patch(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(data),
      );
    });
  }

  @override
  Future<http.Response> deleteApi(String url) async {
    return await _sendRequest((headers) {
      return client.delete(Uri.parse(url), headers: headers);
    });
  }

  // New method to get a pre-signed URL for uploading images to S3
  Future<http.Response> getPresignedUrl(
    String fileType, {
    String folder = 'uploads/messages',
    String fileName = 'file',
  }) async {
    return await _sendRequest((headers) {
      return client.post(
        Uri.parse(AppUrl.generateUploadUrl),
        headers: headers,
        body: jsonEncode({
          'fileType': fileType,
          'folder': folder,
          'fileName': fileName,
        }),
      );
    });
  }

  // New method to upload the image to S3 using the pre-signed URL
  Future<http.StreamedResponse> uploadImageToS3(
    String uploadUrl,
    File imageFile,
  ) async {
    try {
      final request = http.MultipartRequest('PUT', Uri.parse(uploadUrl))
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Use range for success
        return response;
      } else {
        // Read the response body for more details on S3 errors
        final responseBody = await response.stream.bytesToString();
        print("S3 Upload Error Response Body: $responseBody");
        throw FetchDataException(
          // Use FetchDataException for non-S3 errors
          'Error uploading image to S3: ${response.statusCode}\n$responseBody',
        );
      }
    } catch (e) {
      throw FetchDataException('Exception during image upload: $e');
    }
  }

  Future<http.Response> _sendRequest(
    Future<http.Response> Function(Map<String, String>) requestFn,
  ) async {
    try {
      final accessToken = SessionManager.instance.jwtAccessToken;
      print("[API] Original Access Token: $accessToken");

      final headers = {
        'Content-Type': 'application/json',
        if (accessToken != null && accessToken.isNotEmpty)
          'Authorization': 'Bearer $accessToken',
      };

      http.Response response = await requestFn(
        headers,
      ).timeout(const Duration(seconds: 50));

      if (response.statusCode == 401) {
        print("[API] 401 received. Trying to refresh token...");
        final refreshed = await _refreshAccessToken();

        if (refreshed) {
          final newAccessToken = SessionManager.instance.jwtAccessToken;
          print("[API] Retrying with new Access Token: $newAccessToken");

          final newHeaders = {
            'Content-Type': 'application/json',
            if (newAccessToken != null &&
                newAccessToken.isNotEmpty) // Added empty check
              'Authorization': 'Bearer $newAccessToken',
          };

          // Retry the original request with the new token
          response = await requestFn(newHeaders);

          // Check the status of the retried request
          if (response.statusCode >= 200 && response.statusCode < 300 && response.statusCode == 404) {
            return response; // Success after retry
          } else if (response.statusCode == 401 || response.statusCode == 403) {
            // If retry also fails with 401/403, the new token is bad or permission denied
            print(
              "[API] Retried request failed with status: ${response.statusCode}",
            );
            // **THROW AUTHENTICATION FAILED EXCEPTION**
            throw AuthenticationFailedException(
              'Session expired after refresh retry.', // More specific message
            );
          }
          // If retry failed with a different status code, it's likely a different API error
          print(
            "[API] Retried request failed with non-auth status: ${response.statusCode}",
          );
          throw FetchDataException(
            'Error after token refresh retry: ${response.statusCode}\n${response.body}',
          );
        } else {
          // If refresh token failed (_refreshAccessToken returned false)
          print("[API] Token refresh failed in _sendRequest.");
          // **THROW AUTHENTICATION FAILED EXCEPTION**
          // _refreshAccessToken has already cleared the session if backend returned 401/403 to refresh
          throw AuthenticationFailedException(
            'Session expired. Please login again.',
          );
        }
      }

      // If the original response was not 401 and is successful
      if (response.statusCode >= 200 && response.statusCode < 300 ) {
        return response;
      }


      if(response.statusCode == 404){
        return response;
      }
      // If the original response was not 401 but was an error status code
      print("[API] Final Response Status: ${response.statusCode}");
      print("[API] Final Response Body: ${response.body}");
      // Handle other specific error codes if needed (e.g., 403 Forbidden)
      if (response.statusCode == 403) {
        throw UnauthorizedException(
          // Use UnauthorizedException or a specific PermissionDeniedException
          'Permission denied: ${response.body}',
        );
      }

      // For other non-success status codes
      throw FetchDataException(
        'Error with status code: ${response.statusCode}\n${response.body}',
      );
    } on SocketException {
      throw NoInternetException("Please check your Internet Connection");
    } on TimeoutException {
      throw RequestTimeoutException(
        "Request TimedOut",
      ); // Use RequestTimeoutException
    } on AuthenticationFailedException {
      // **Re-throw the specific authentication failure exception**
      // This ensures it propagates up to the Bloc/UI layer
      rethrow;
    } catch (e, stackTrace) {
      // Catch any other unexpected exceptions
      print("[API] Unexpected exception in _sendRequest: $e\n$stackTrace");
      // Decide if you want to clear session on *any* unexpected error
      // SessionManager.instance.clearSession(); // Optional: Clear session on any API error
      throw FetchDataException(
        'An unexpected error occurred during API call: ${e.toString()}',
      ); // Wrap in a general exception
    }
  }

  Future<bool> _refreshAccessToken() async {
    final refreshToken = SessionManager.instance.jwtRefreshToken;
    print("[RefreshToken] Attempting with: $refreshToken");

    if (refreshToken == null || refreshToken.isEmpty) {
      print("[RefreshToken] Empty refresh token.");
      return false; // Cannot refresh without a token
    }

    final uri = Uri.parse(AppUrl.refreshAccessToken);

    try {
      final response = await client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(
            const Duration(seconds: 30),
          ); // Add timeout for refresh request

      print("[RefreshToken] Response status: ${response.statusCode}");
      print("[RefreshToken] Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['accessToken'];
        // It's also good practice to check if the refresh token was renewed, though not strictly necessary for this issue
        // final newRefreshToken = data['refreshToken']; // If backend renews refresh token

        if (newAccessToken == null || newAccessToken.isEmpty) {
          print(
            "[RefreshToken] No valid access token returned in refresh response.",
          );
          // Treat as a failure, clear session
          await SessionManager.instance.clearSession();
          return false; // Indicate refresh failed
        }

        // Update session with the new access token (and potentially renewed refresh token)
        await SessionManager.instance.setSession(
          userId: SessionManager.instance.userId, // Use nullable properties
          traccarId:
              SessionManager.instance.traccarId, // Use nullable properties
          jwtRefreshToken:
              refreshToken, // Keep the same refresh token if not renewed by backend
          // jwtRefreshToken: newRefreshToken ?? refreshToken, // Use new refresh token if provided
          jwtAccessToken: newAccessToken,
          traccarToken: SessionManager.instance.traccarToken
        );

        print("[RefreshToken] Access token refreshed successfully");
        return true; // Indicate refresh was successful
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // If refresh endpoint explicitly returns 401 or 403, the refresh token is bad
        print(
          "[RefreshToken] Invalid or expired refresh token received from endpoint.",
        );
        // **Crucially, clear the invalid refresh token from storage**
        await SessionManager.instance
            .clearSession(); // Clear all session data including invalid refresh token
        return false; // Indicate refresh failed
      } else {
        // Handle other non-success status codes from refresh endpoint
        print(
          "[RefreshToken] Refresh token endpoint returned unexpected status: ${response.statusCode}",
        );
        // Decide if other error codes from refresh should also clear session
        // await SessionManager.instance.clearSession(); // Optional: Clear session on other refresh errors
        return false; // Indicate refresh failed
      }
    } on SocketException {
      print("[RefreshToken] Socket Exception during refresh token request.");
      await SessionManager.instance
          .clearSession(); // Clear session on network errors during refresh
      return false;
    } on TimeoutException {
      print("[RefreshToken] Timeout Exception during refresh token request.");
      await SessionManager.instance
          .clearSession(); // Clear session on timeout during refresh
      return false;
    } catch (e, stackTrace) {
      print(
        "[RefreshToken] Unexpected exception during refresh token request: $e\n$stackTrace",
      );
      // Clear session on any other unexpected exception during the refresh process as a safety measure
      await SessionManager.instance.clearSession();
      return false; // Indicate refresh failed
    }
  }
}
