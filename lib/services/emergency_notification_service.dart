import 'package:dia_plus/models/emergency_alert.dart';
import 'package:dia_plus/models/emergency_alert_type.dart';
import 'package:dia_plus/services/reminder_notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class EmergencyNotificationService {
  EmergencyNotificationService({
    ReminderNotificationService? reminderNotificationService,
    FlutterLocalNotificationsPlugin? plugin,
  }) : _reminderNotificationService =
           reminderNotificationService ?? ReminderNotificationService(),
       _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
        'diapulse_emergency_alerts_channel',
        'DiaPulse Emergency Alerts',
        description: 'Urgent notifications for critical glucose emergencies',
        importance: Importance.max,
      );

  static const AndroidNotificationChannel _simulationChannel =
      AndroidNotificationChannel(
        'diapulse_emergency_simulation_channel',
        'DiaPulse Emergency Simulations',
        description: 'Simulation notifications for project demo actions',
        importance: Importance.high,
      );

  final ReminderNotificationService _reminderNotificationService;
  final FlutterLocalNotificationsPlugin _plugin;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    // Reuse the app's existing notification bootstrap path first.
    await _reminderNotificationService.initialize();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(initSettings);

    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImpl?.createNotificationChannel(_androidChannel);
    await androidImpl?.createNotificationChannel(_simulationChannel);

    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    await initialize();
    return _reminderNotificationService.requestPermissions();
  }

  Future<void> showEmergencyAlertNotification(
    EmergencyAlert alert, {
    bool soundEnabled = true,
    bool vibrationEnabled = true,
  }) async {
    await initialize();

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _androidChannel.id,
        _androidChannel.name,
        channelDescription: _androidChannel.description,
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.alarm,
        playSound: soundEnabled,
        enableVibration: vibrationEnabled,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: soundEnabled,
        interruptionLevel: InterruptionLevel.critical,
      ),
    );

    await _plugin.show(
      _buildNotificationId(alert.id),
      alert.title,
      alert.message,
      details,
      payload: alert.id,
    );
  }

  Future<void> showSimulationNotice({required String title, required String message}) async {
    await initialize();

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _simulationChannel.id,
        _simulationChannel.name,
        channelDescription: _simulationChannel.description,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch % 2147480000,
      title,
      message,
      details,
    );
  }

  Future<void> showTestEmergency(EmergencyAlertType type) async {
    await initialize();

    final title = type == EmergencyAlertType.criticalLow
        ? 'Critical Low Glucose Alert'
        : 'Critical High Glucose Alert';
    final message = type == EmergencyAlertType.criticalLow
        ? 'Your glucose is critically low. Take fast-acting sugar now.'
        : 'Your glucose is critically high. Follow your treatment plan now.';

    final alert = EmergencyAlert(
      id: 'test_${DateTime.now().millisecondsSinceEpoch}',
      glucoseValue: type == EmergencyAlertType.criticalLow ? 52 : 338,
      alertType: type,
      title: title,
      message: message,
      timestamp: DateTime.now(),
      severityLabel: 'Critical',
      recommendedActions: const [],
      createdAt: DateTime.now(),
    );

    await showEmergencyAlertNotification(alert);
  }

  int _buildNotificationId(String sourceId) {
    var hash = 17;
    for (final codeUnit in sourceId.codeUnits) {
      hash = 31 * hash + codeUnit;
    }
    return hash.abs() % 2147480000;
  }
}
