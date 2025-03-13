import 'package:botsdock/apps/chat/utils/client/dio_client.dart';

class Tools {
  static final client = DioClient();

  static Future<List> google_search(
      {required String query, int num_results = 10}) async {
    final response = await client.get(
      "/v1/google_search/",
      queryParameters: {"query": query, "num_results": num_results},
    );

    return response ?? [];
  }

  static Future<String> webpage_query({required String url}) async {
    final response = await client.get(
      "/v1/fetch_webpage/",
      queryParameters: {"url": url},
    );
    if (response != null && response.isNotEmpty) return response;
    return "empty result";
  }
}
