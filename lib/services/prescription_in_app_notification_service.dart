import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrescriptionInAppNotificationService {
  static const _prefsLastSeenKey = 'prescriptions_last_seen_ms';

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    'diapulse_prescriptions_channel',
    'DiaPulse Prescriptions',
    description: 'Notifications when a doctor prescribes medicines',
    importance: Importance.high,
  );

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(initSettings);

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(_androidChannel);
    await androidImpl?.requestNotificationsPermission();

    final iosImpl =
        _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await iosImpl?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  Future<void> startForPatient(String uid) async {
    await initialize();
    await stop();

    final prefs = await SharedPreferences.getInstance();
    final lastSeenMs = prefs.getInt(_prefsLastSeenKey) ?? 0;
    final lastSeen = DateTime.fromMillisecondsSinceEpoch(lastSeenMs);

    _sub = _firestore
        .collection('medicines')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .listen((snap) async {
      for (final change in snap.docChanges) {
        if (change.type != DocumentChangeType.added) continue;
        final data = change.doc.data();
        if (data == null) continue;

        final prescribedAtRaw = data['prescribedAt'];
        final prescribedAt = DateTime.tryParse(prescribedAtRaw?.toString() ?? '');
        if (prescribedAt == null) continue;
        if (!prescribedAt.isAfter(lastSeen)) continue;

        final medName = (data['name'] as String?) ?? 'Medicine';
        final byName = (data['prescribedByName'] as String?)?.trim();
        final title = 'New prescription';
        final body = (byName != null && byName.isNotEmpty)
            ? '$medName prescribed by $byName'
            : '$medName was prescribed by your doctor';

        await _plugin.show(
          DateTime.now().millisecondsSinceEpoch.remainder(100000),
          title,
          body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _androidChannel.id,
              _androidChannel.name,
              channelDescription: _androidChannel.description,
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: const DarwinNotificationDetails(),
          ),
        );
      }

      final nowMs = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt(_prefsLastSeenKey, nowMs);
    });
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }
}

