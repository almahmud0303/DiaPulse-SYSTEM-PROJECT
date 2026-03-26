import 'backup_file_saver_stub.dart'
    if (dart.library.io) 'backup_file_saver_io.dart'
    if (dart.library.html) 'backup_file_saver_web.dart' as impl;

/// Saves backup JSON and returns a user-facing location/description.
Future<String> saveBackupJson({
  required String filename,
  required String jsonContent,
}) {
  return impl.saveBackupJson(filename: filename, jsonContent: jsonContent);
}
