import 'package:cookie_jar/cookie_jar.dart';

extension CookieParser on List<Cookie> {
  String parse() {
    final cookieList =
        map((cookie) {
          return {'name': cookie.name, 'value': cookie.value};
        }).toList();
    String cookieHeader = cookieList
        .map((cookie) {
          return '${cookie['name']}=${cookie['value']}';
        })
        .join('; ');
    return cookieHeader;
  }
}
