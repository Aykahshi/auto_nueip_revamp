import 'dart:convert';

import 'package:dio/dio.dart';

import '../config/api_config.dart';

/// Interceptor to handle the specific behavior of the login API.
/// - Treats 200 OK with "status: fail" in the body as an error.
/// - Treats 303 See Other as a successful response.
class LoginInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Check if it's the login API response with status code 200
    if (response.requestOptions.path == ApiConfig.LOGIN_URL &&
        response.statusCode == 200) {
      try {
        // Attempt to parse the response data
        // Dio's transformer might have already parsed it if content-type is json
        dynamic responseData = response.data;
        Map<String, dynamic> dataMap;

        if (responseData is String) {
          // If data is a string, try decoding it as JSON
          // This handles cases where content-type might be text/html but contains JSON
          try {
            dataMap = jsonDecode(responseData) as Map<String, dynamic>;
          } catch (e) {
            // If decoding fails, it's not the JSON format we expect for failure.
            // Let it pass through as a potentially valid non-JSON 200 response.
            super.onResponse(response, handler);
            return;
          }
        } else if (responseData is Map<String, dynamic>) {
          // If data is already a map
          dataMap = responseData;
        } else {
          // Unexpected data type, let it pass through
          super.onResponse(response, handler);
          return;
        }

        // Check if the status indicates failure
        if (dataMap['status'] == 'fail') {
          // Extract error message and details
          String errorMessage = 'Login failed.'; // Default message
          Map<String, dynamic>? errorDetails;

          if (dataMap.containsKey('errors') && dataMap['errors'] is Map) {
            final errors = dataMap['errors'] as Map<String, dynamic>;
            errorDetails = errors; // Store the whole errors map
            if (errors.containsKey('message') && errors['message'] is String) {
              errorMessage = errors['message'] as String;
            } else {
              // Construct message from other error details if 'message' is missing
              errorMessage = errors.entries
                  .map((e) => '${e.key}: ${e.value}')
                  .join(', ');
              errorMessage = 'Login failed: $errorMessage';
            }
          }

          // Reject the response with a DioException, making it an error
          final error = DioException(
            requestOptions: response.requestOptions,
            response: response, // Include the original response
            type: DioExceptionType.badResponse,
            error:
                errorDetails ??
                errorMessage, // Store details map or fallback message
            message: errorMessage, // Keep the general message
          );
          handler.reject(error); // Pass the error down the chain
          return; // Stop further processing of this response
        }
      } catch (e) {
        // Handle potential parsing errors or missing keys gracefully.
        // We assume if parsing fails, it's not the specific "fail" JSON structure.
        // Log the error for debugging if necessary.
      }
    }
    // If not the login API, not status 200, or not the "fail" structure,
    // continue with the normal response handling.
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Check if the error is for the login API, is a bad response type,
    // and specifically has the status code 303.
    if (err.requestOptions.path == ApiConfig.LOGIN_URL &&
        err.response?.statusCode == 303 &&
        err.type == DioExceptionType.badResponse) {
      // If it's the expected 303 redirect for a successful login,
      // resolve it with the response. This treats the "error" as a success.
      handler.resolve(err.response!);
      return; // Stop further error processing
    }
    // For all other errors, continue with the normal error handling.
    super.onError(err, handler);
  }
}
