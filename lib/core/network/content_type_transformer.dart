import 'package:dio/dio.dart';

class ContentTypeTransformer extends BackgroundTransformer {
  @override
  Future transformResponse(
    RequestOptions options,
    ResponseBody responseBody,
  ) async {
    if (responseBody.headers['content-type']?.first ==
        'application/json;; charset=UTF-8') {
      responseBody.headers['content-type'] = [
        'application/json; charset=UTF-8',
      ];
    }
    return super.transformResponse(options, responseBody);
  }
}
