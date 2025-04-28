import 'dart:convert';

import 'package:flutter/foundation.dart';
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

extension ExtractTextFromHtml on String {
  void parseInboxMsg(String jsonResponse) {
    final notifications = jsonDecode(jsonResponse) as List<dynamic>;

    for (var notification in notifications) {
      String messageWithHtml = notification['message'];

      String plainText = extractText(messageWithHtml);

      debugPrint('Source: $messageWithHtml');
      debugPrint('Extracted: $plainText');
      debugPrint('-------------------');
    }
  }

  String extractText(String htmlString) {
    final document = parse(htmlString);

    final String plainText = document.body?.text ?? '';

    return _decodeUnicodeEscapes(plainText);
  }

  String _decodeUnicodeEscapes(String text) {
    try {
      return json.decode('"${text.replaceAll('"', '\\"')}"');
    } catch (e) {
      return text;
    }
  }
}
