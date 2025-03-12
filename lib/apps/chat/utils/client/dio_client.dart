import 'dart:io';

import 'package:botsdock/apps/chat/utils/client/path.dart';
import 'package:botsdock/apps/chat/utils/logger.dart';
import 'package:dio/dio.dart';

class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int _maxRetries;

  RetryInterceptor({required this.dio, int maxRetries = 3})
      : _maxRetries = maxRetries;

  @override
  Future onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_shouldRetry(err)) {
      return _retry(err.requestOptions, handler, _maxRetries);
    }
    super.onError(err, handler);
  }

  Future<dynamic> _retry(
    RequestOptions requestOptions,
    ErrorInterceptorHandler handler,
    int remainingRetries,
  ) async {
    try {
      Logger.warn(
        'Retrying $remainingRetries,${requestOptions.method} ${requestOptions.path}',
      );
      final response = await dio.request(
        requestOptions.path,
        data: requestOptions.data,
        queryParameters: requestOptions.queryParameters,
        options: Options(
          method: requestOptions.method,
          headers: requestOptions.headers,
          contentType: requestOptions.contentType,
          responseType: requestOptions.responseType,
          extra: requestOptions.extra,
        ),
        cancelToken: requestOptions.cancelToken,
      );

      return handler.resolve(response);
    } on DioException catch (e) {
      if (remainingRetries > 0 && _shouldRetry(e)) {
        await Future.delayed(Duration(seconds: 3));
        return _retry(requestOptions, handler, remainingRetries - 1);
      }
      return handler.reject(e);
    }
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError ||
        err.error is SocketException;
  }
}

class DioClient {
  static final DioClient _instance = DioClient._internal();
  late final Dio dio;

  factory DioClient() => _instance;

  DioClient._internal() {
    BaseOptions options = BaseOptions(
      baseUrl: ChatPath.base,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json', // default Content-Type
      },
    );
    dio = Dio(options);

    dio.interceptors.addAll([
      // LogInterceptor(),
      // RetryInterceptor(dio: dio, maxRetries: 3)
    ]);
    dio.interceptors.add(RetryInterceptor(dio: dio, maxRetries: 3));
  }

  T _processResponse<T>(Response response) {
    if (response.statusCode! >= 200 && response.statusCode! < 300) {
      return response.data as T;
    } else {
      throw Exception('Error: ${response.statusMessage}');
    }
  }

  Exception _handleError(error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          return Exception('connectionTimeout');
        case DioExceptionType.sendTimeout:
          return Exception('sendTimeout');
        case DioExceptionType.receiveTimeout:
          return Exception('receiveTimeout');
        case DioExceptionType.badResponse:
          return Exception('service error: ${error.response?.statusCode}');
        case DioExceptionType.cancel:
          return Exception('request cancel');
        case DioExceptionType.unknown:
          return Exception('network error: unknow');
        case DioExceptionType.badCertificate:
          return Exception('badCertificate');
        case DioExceptionType.connectionError:
          return Exception('connectionError');
      }
    }
    return Exception('unknow error');
  }

  Future<T> get<T>(String path,
      {Map<String, dynamic>? queryParameters, Options? options}) async {
    try {
      Response response = await dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return _processResponse<T>(response);
    } catch (e, s) {
      Logger.error("dio get error: $e, stack:$s");
      throw _handleError(e);
    }
  }

  Future<T> post<T>(String path,
      {dynamic data,
      Map<String, dynamic>? queryParameters,
      Options? options}) async {
    try {
      Response response = await dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _processResponse<T>(response);
    } catch (e, s) {
      Logger.error("dio post error: $e, stack:$s");
      throw _handleError(e);
    }
  }

  Future<T> delete<T>(String path,
      {dynamic data,
      Map<String, dynamic>? queryParameters,
      Options? options}) async {
    try {
      Response response = await dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _processResponse<T>(response);
    } catch (e, s) {
      Logger.error("dio delete error: $e, stack:$s");
      throw _handleError(e);
    }
  }
}
