// ignore_for_file: constant_identifier_names
sealed class ApiConfig {
  const ApiConfig._();

  static const String BASE_URL = 'https://cloud.nueip.com';

  static const Map<String, String> HEADERS = {
    'Content-Type': 'application/x-www-form-urlencoded',
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
  };
}
