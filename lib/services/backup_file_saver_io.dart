import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<String> saveBackupJson({
  required String filename,
  required String jsonContent,
}) async {
  final downloads = await getDownloadsDirectory();
  final baseDir = downloads ?? await getApplicationDocumentsDirectory();
  final outFile = File('${baseDir.path}${Platform.pathSeparator}$filename');
  await outFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(jsonDecode(jsonContent)),
  );
  return outFile.path;
}
