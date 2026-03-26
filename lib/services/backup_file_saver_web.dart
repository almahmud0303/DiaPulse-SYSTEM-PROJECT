// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:convert';
import 'dart:html' as html;

Future<String> saveBackupJson({
  required String filename,
  required String jsonContent,
}) async {
  final normalized =
      const JsonEncoder.withIndent('  ').convert(jsonDecode(jsonContent));
  final bytes = utf8.encode(normalized);
  final blob = html.Blob([bytes], 'application/json');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final a =
      html.AnchorElement(href: url)
        ..download = filename
        ..style.display = 'none';
  html.document.body?.append(a);
  a.click();
  a.remove();
  html.Url.revokeObjectUrl(url);
  return 'Browser download started';
}
