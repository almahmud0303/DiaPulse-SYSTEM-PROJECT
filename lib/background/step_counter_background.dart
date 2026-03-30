import 'dart:async';
import 'dart:io' show Platform;

import 'package:dia_plus/firebase_options.dart';
import 'package:dia_plus/services/step_counter_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

const String _kStepSyncUniqueName = 'dia_plus_step_sync';

/// Android: runs periodically (minimum ~15 minutes) to read the hardware step
/// counter and sync [users/{uid}/daily_steps]. Requires the user to be signed in.
@pragma('vm:entry-point')
void stepSyncCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Future.value(true);
    await StepCounterService.backgroundIngestForUid(user.uid);
    return Future.value(true);
  });
}

bool _stepWorkRegistered = false;

/// Call once after [Firebase.initializeApp] and [runApp] (e.g. post-frame).
Future<void> registerStepBackgroundSync() async {
  if (kIsWeb || !Platform.isAndroid) return;
  if (_stepWorkRegistered) return;
  try {
    await Workmanager().initialize(stepSyncCallbackDispatcher);
    await Workmanager().registerPeriodicTask(
      _kStepSyncUniqueName,
      _kStepSyncUniqueName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
    _stepWorkRegistered = true;
  } catch (e, st) {
    debugPrint('Step background sync registration failed: $e\n$st');
  }
}
