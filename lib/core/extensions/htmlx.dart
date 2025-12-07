import 'package:html/dom.dart';
import 'package:html/parser.dart';

extension ExtractTokenFromHtml on String {
  String extractToken() {
    final Document document = parse(this);
    final Element? tag = document.querySelector('input[name="token"]');

    if (tag != null) {
      final String token = tag.attributes['value'] ?? '';
      return token;
    }

    return '';
  }
}

extension ExtractOptionsFromHtml on String {
  List<String?> parseOptions() {
    final Document document = parse(this);
    final options = document.querySelectorAll('option');

    final result =
        options
            .where((opt) => opt.attributes['value'] != "")
            .map((opt) => opt.text.trim())
            .toList();

    return result;
  }
}
