import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/retry.dart';
import 'package:fetch_client/fetch_client.dart';

import 'package:openai_dart/openai_dart.dart' as openai;

import 'package:botsdock/apps/chat/utils/client/transformer.dart';

class HttpClient {
  static Stream<openai.AssistantStreamEvent> CreateAssistantStream({
    required String baseUrl,
    required String path,
    String method = "POST",
    Map<String, String> headerParams = const {},
    Map<String, dynamic> queryParams = const {},
    String? requestType,
    String? responseType,
    Object? body,
  }) async* {
    final r = await makeRequestStream(
      baseUrl: baseUrl,
      path: path,
      method: method,
      headerParams: headerParams,
      queryParams: queryParams,
      requestType: 'application/json',
      responseType: 'text/event-stream',
      body: body,
    );
    yield* r.stream.transform(const OpenAIAssistantStreamTransformer());
  }

  static Stream<String> createStream({
    required String baseUrl,
    required String path,
    String method = "POST",
    Map<String, String> headerParams = const {},
    Map<String, dynamic> queryParams = const {},
    String? requestType,
    String? responseType,
    Object? body,
  }) async* {
    final r = await makeRequestStream(
      baseUrl: baseUrl,
      path: path,
      method: method,
      headerParams: headerParams,
      queryParams: queryParams,
      requestType: 'application/json',
      responseType: 'text/event-stream',
      body: body,
    );

    yield* r.stream.transform(const OpenAIStreamTransformer());
  }

  @protected
  static Future<http.StreamedResponse> makeRequestStream({
    required String baseUrl,
    required String path,
    String method = "POST",
    Map<String, dynamic> queryParams = const {},
    Map<String, String> headerParams = const {},
    bool isMultipart = false,
    String requestType = '',
    String responseType = '',
    Object? body,
  }) async {
    late http.StreamedResponse response;
    try {
      response = await _request(
        baseUrl: baseUrl,
        path: path,
        method: method,
        queryParams: queryParams,
        headerParams: headerParams,
        requestType: requestType,
        responseType: responseType,
        body: body,
      );
      // Handle user response middleware
      response = await onStreamedResponse(response);
    } catch (e) {
      // Handle request and response errors
      throw Exception('_request error');
    }

    // Check for successful response
    if ((response.statusCode ~/ 100) == 2) {
      return response;
    }

    // Handle unsuccessful response
    throw Exception('Unsuccessful response');
  }

  @protected
  static Future<http.StreamedResponse> _request({
    required String baseUrl,
    required String path,
    String? method = "POST",
    Map<String, dynamic> queryParams = const {},
    Map<String, String> headerParams = const {},
    bool isMultipart = false,
    String requestType = '',
    String responseType = '',
    Object? body,
  }) async {
    // Ensure a url is provided
    assert(
      baseUrl.isNotEmpty,
      'baseUrl is required, but none defined in spec or provided by user',
    );

    var client = RetryClient(
      kIsWeb ? FetchClient(mode: RequestMode.cors) : http.Client(),
    );
    // Add global query parameters
    queryParams = {...queryParams};

    // Ensure query parameters are strings or iterable of strings
    queryParams = queryParams.map((key, value) {
      if (value is Iterable) {
        return MapEntry(key, value.map((v) => v.toString()));
      } else {
        return MapEntry(key, value.toString());
      }
    });

    // Build the request URI
    Uri uri = Uri.parse(baseUrl + path);
    if (queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    // Build the headers
    Map<String, String> headers = {...headerParams};

    // Define the request type being sent to server
    if (requestType.isNotEmpty) {
      headers['content-type'] = requestType;
    }

    // Define the response type expected to receive from server
    if (responseType.isNotEmpty) {
      headers['accept'] = responseType;
    }

    // Build the request object
    http.BaseRequest request;
    if (isMultipart) {
      // Handle multipart request
      request = http.MultipartRequest(method!, uri);
      request = request as http.MultipartRequest;
      if (body is List<http.MultipartFile>) {
        request.files.addAll(body);
      } else {
        request.files.add(body as http.MultipartFile);
      }
    } else {
      // Handle normal request
      request = http.Request(method!, uri);
      request = request as http.Request;
      try {
        if (body != null) {
          request.body = json.encode(body);
        }
      } catch (e) {
        // Handle request encoding error
        throw Exception('Could not encode: ${body.runtimeType}');
      }
    }

    // Add request headers
    request.headers.addAll(headers);

    // Handle user request middleware
    request = await onRequest(request);

    // Submit request
    return await client.send(request);
  }

  static Future<http.BaseRequest> onRequest(http.BaseRequest request) {
    return Future.value(request);
  }

  static Future<http.StreamedResponse> onStreamedResponse(
    final http.StreamedResponse response,
  ) {
    return Future.value(response);
  }
}
