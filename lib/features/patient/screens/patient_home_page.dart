import 'package:dia_plus/features/patient/screens/add_reading_page.dart';
import 'package:dia_plus/features/patient/screens/emergency_alert_details_page.dart';
import 'package:dia_plus/features/patient/screens/health_score_details_page.dart';
import 'package:dia_plus/features/patient/screens/reminders_page.dart';
import 'package:dia_plus/features/patient/screens/log_activity_page.dart';
import 'package:dia_plus/features/patient/screens/log_meal_page.dart';
import 'package:dia_plus/features/patient/screens/take_medicine_page.dart';
import 'package:dia_plus/features/patient/widgets/health_score_card.dart';
import 'package:dia_plus/features/patient/widgets/next_reminder_widget.dart';
import 'package:dia_plus/models/emergency_alert.dart';
import 'package:dia_plus/features/shared/screens/conversation_list_page.dart';
import 'package:dia_plus/features/shared/screens/diabetes_essentials_page.dart';
import 'package:dia_plus/features/shared/screens/doctor_consultation_page.dart';
import 'package:dia_plus/features/patient/screens/patient_appointments_page.dart';
import 'package:dia_plus/models/appointment.dart';
import 'package:dia_plus/models/glucose_reading.dart';
import 'package:dia_plus/models/health_score.dart';
import 'package:dia_plus/models/reminder.dart';
import 'package:dia_plus/services/appointment_service.dart';
import 'package:dia_plus/models/emergency_alert_type.dart';
import 'package:dia_plus/models/glucose_reading.dart';
import 'package:dia_plus/models/health_score.dart';
import 'package:dia_plus/models/reminder.dart';
import 'package:dia_plus/services/emergency_alert_service.dart';
import 'package:dia_plus/services/glucose_reading_service.dart';
import 'package:dia_plus/services/health_score_service.dart';
import 'package:dia_plus/services/medicine_service.dart';
import 'package:dia_plus/services/reminder_notification_service.dart';
import 'package:dia_plus/services/reminder_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Patient main dashboard - greeting, latest glucose, today summary,
/// quick actions, mini weekly graph, reminders, health score.
class PatientHomePage extends StatefulWidget {
  const PatientHomePage({super.key});

  @override
  State<PatientHomePage> createState() => _PatientHomePageState();
}

class _PatientHomePageState extends State<PatientHomePage> {
  final _readingService = GlucoseReadingService();
  final _medicineService = MedicineService();
  final _reminderService = ReminderService();
  final _healthScoreService = HealthScoreService();
  final _appointmentService = AppointmentService();
  final _emergencyAlertService = EmergencyAlertService();

  String _userName = 'User';
  String _userInitials = 'U';
  GlucoseReading? _latestReading;
  List<GlucoseReading> _todayReadings = [];
  List<GlucoseReading> _weekReadings = [];
  bool _loading = true;
  int _medicinesTakenToday = 0; // Placeholder - no medicine tracking yet
  int _medicinesTotalToday = 2; // Placeholder
  String? _nextMedicineTime; // Placeholder
  String? _nextAppointment; // Placeholder
  String? _nextGlucoseTest; // Placeholder - next glucose test time
  AppointmentStatus? _nextAppointmentStatus;
  Reminder? _nextReminder;
  DateTime? _nextReminderAt;
  EmergencyAlert? _latestEmergencyAlert;
  HealthScore? _healthScore;
  bool _healthScoreLoading = false;
  String? _healthScoreError;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'User';
      _userInitials = prefs.getString('userInitials') ?? 'U';
    });

    if (user == null) {
      setState(() {
        _loading = false;
        _latestEmergencyAlert = null;
        _healthScore = null;
        _healthScoreLoading = false;
        _healthScoreError = null;
      });
      return;
    }

    setState(() {
      _healthScoreLoading = true;
      _healthScoreError = null;
    });

    try {
      final latest = await _readingService.getLatestReading(user.uid);
      final today = await _readingService.getTodayReadings(user.uid);
      final week = await _readingService.getReadingsForLast7Days(user.uid);

      int medTaken = 0;
      int medTotal = 0;
      String? nextMed;
      try {
        final medicines = await _medicineService.getMedicines(user.uid);
        medTotal = medicines.length;
        final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final entries = await _medicineService.getEntries(
          user.uid,
          fromDate: todayStr,
          toDate: todayStr,
        );
        medTaken = entries.where((e) => e.taken).length;
        final next = await _medicineService.getNextMedicineToday(user.uid);
        if (next != null) nextMed = '${next.time} (${next.name})';
        // Schedule local notifications at each medicine time (daily).
        ReminderNotificationService().scheduleMedicineReminders(medicines);
      } catch (_) {}

      Reminder? smartNextReminder;
      DateTime? smartNextReminderAt;
      EmergencyAlert? latestEmergency;
      HealthScore? score;
      String? scoreError;
      try {
        await _reminderService.initialize();
        smartNextReminder = await _reminderService.getNextReminder();
        if (smartNextReminder != null) {
          smartNextReminderAt = _reminderService.getNextTriggerTime(
            smartNextReminder,
          );
        }
      } catch (_) {}

      try {
        final unacknowledged = await _emergencyAlertService
            .getUnacknowledgedAlerts();
        final userAlerts =
            unacknowledged
                .where((alert) => _belongsToUser(alert, user.uid))
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        latestEmergency = userAlerts.isEmpty ? null : userAlerts.first;
      } catch (_) {}

      try {
        score = await _healthScoreService.calculateHealthScore(
          user.uid,
          period: HealthScorePeriod.last7Days,
        );
      } catch (e) {
        scoreError = 'Unable to load health score right now.';
      }

      String? nextAppointment;
      AppointmentStatus? nextAppointmentStatus;
      try {
        final apps = await _appointmentService.getForPatient(user.uid);
        if (apps.isNotEmpty) {
          final a = apps.first;
          final name = a.doctorName ?? 'Doctor';
          nextAppointment = '$name • ${a.status.displayLabel}';
          nextAppointmentStatus = a.status;
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _latestReading = latest;
          _todayReadings = today;
          _weekReadings = week;
          _medicinesTakenToday = medTaken;
          _medicinesTotalToday = medTotal;
          _nextMedicineTime = nextMed;
          _nextAppointment = nextAppointment;
          _nextAppointmentStatus = nextAppointmentStatus;
          _nextGlucoseTest = 'Before lunch'; // Placeholder
          _nextReminder = smartNextReminder;
          _nextReminderAt = smartNextReminderAt;
          _latestEmergencyAlert = latestEmergency;
          _healthScore = score;
          _healthScoreLoading = false;
          _healthScoreError = scoreError;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _healthScoreLoading = false;
        });
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Low':
        return Colors.blue;
      case 'Normal':
        return Colors.green;
      case 'High':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.grey,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildGreeting(),
                const SizedBox(height: 12),
                _buildEmergencyBanner(),
                const SizedBox(height: 20),
                _buildLatestGlucoseCard(),
                const SizedBox(height: 20),
                _buildTodaySummary(),
                const SizedBox(height: 20),
                _buildQuickActions(),
                const SizedBox(height: 20),
                _buildMiniWeeklyGraph(),
                const SizedBox(height: 20),
                _buildUpcomingReminder(),
                const SizedBox(height: 20),
                _buildHealthScore(),
                const SizedBox(height: 20),
                _buildDoctorConsultSection(),
                const SizedBox(height: 20),
                _buildMessagesSection(),
                const SizedBox(height: 20),
                _buildDiabetesEssentialsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.teal,
          child: Text(
            _userInitials,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _userName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Dia Plus',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RemindersPage()),
          ),
        ),
      ],
    );
  }

  Widget _buildGreeting() {
    return Text(
      '${_getGreeting()}, $_userName',
      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildEmergencyBanner() {
    final alert = _latestEmergencyAlert;
    if (alert == null) {
      return const SizedBox.shrink();
    }

    final color = alert.isCriticalLow
        ? Colors.orange.shade700
        : Colors.red.shade700;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.emergency, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Emergency Alert',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${alert.glucoseValue.toStringAsFixed(0)} mg/dL • ${alert.alertType.label}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  alert.message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          Column(
            children: [
              TextButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => EmergencyAlertDetailsPage(
                        alert: alert,
                        onAcknowledge: (current) async {
                          await _emergencyAlertService.markAlertAcknowledged(
                            current.id,
                          );
                        },
                        onNotifyDoctor: (current) async {
                          await _emergencyAlertService.notifyDoctorSimulation(
                            current,
                          );
                        },
                        onNotifyEmergencyContact: (current) async {
                          await _emergencyAlertService
                              .notifyEmergencyContactSimulation(current);
                        },
                      ),
                    ),
                  );
                  await _loadData();
                },
                child: const Text('View'),
              ),
              FilledButton(
                onPressed: () async {
                  await _emergencyAlertService.markAlertAcknowledged(alert.id);
                  if (!mounted) {
                    return;
                  }
                  setState(() {
                    _latestEmergencyAlert = null;
                  });
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size(68, 30),
                  backgroundColor: color,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                child: const Text('Ack'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _belongsToUser(EmergencyAlert alert, String userId) {
    final fromAlertId = alert.id.startsWith('${userId}_');
    final fromReadingId = (alert.readingId ?? '').startsWith('${userId}_');
    return fromAlertId || fromReadingId;
  }

  Widget _buildLatestGlucoseCard() {
    final reading = _latestReading;
    if (reading == null) {
      return _buildEmptyGlucoseCard();
    }
    final status = reading.getStatus();
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.water_drop, color: color, size: 40),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Latest Glucose',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      reading.glucoseLevel.toInt().toString(),
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('mg/dL', style: TextStyle(fontSize: 16, color: color)),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            reading.mealTime,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyGlucoseCard() {
    return InkWell(
      onTap: () => _navigateToAddReading(),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade400, Colors.teal.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.teal.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.add_circle_outline, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Add Your First Reading',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Start monitoring your blood glucose',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaySummary() {
    final avg = _todayReadings.isEmpty
        ? 0.0
        : _todayReadings.map((r) => r.glucoseLevel).reduce((a, b) => a + b) /
              _todayReadings.length;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Summary",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Average',
                  _todayReadings.isEmpty ? '--' : '${avg.round()} mg/dL',
                  Icons.analytics_outlined,
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Readings',
                  '${_todayReadings.length}',
                  Icons.water_drop_outlined,
                  Colors.teal,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Medicine',
                  '$_medicinesTakenToday/$_medicinesTotalToday',
                  Icons.medication_outlined,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                'Add Reading',
                Icons.add_circle_outline,
                Colors.teal,
                _navigateToAddReading,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionButton(
                'Log Meal',
                Icons.restaurant_menu,
                Colors.orange,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LogMealPage()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                'Log Activity',
                Icons.fitness_center,
                Colors.green,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LogActivityPage()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionButton(
                'Take Medicine',
                Icons.medication,
                Colors.purple,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TakeMedicinePage()),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: Colors.grey.withValues(alpha: 0.2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniWeeklyGraph() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart, color: Colors.teal.shade600),
              const SizedBox(width: 8),
              const Text(
                'Last 7 Days',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: _weekReadings.isEmpty
                ? Center(
                    child: Text(
                      'No readings yet',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : _buildWeekChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekChart() {
    final days = List.generate(7, (i) {
      final d = DateTime.now().subtract(Duration(days: 6 - i));
      return DateFormat('EEE').format(d);
    });
    final dayReadings = List.generate(7, (i) {
      final target = DateTime.now().subtract(Duration(days: 6 - i));
      final dayList = _weekReadings.where((r) {
        return r.date.year == target.year &&
            r.date.month == target.month &&
            r.date.day == target.day;
      }).toList();
      if (dayList.isEmpty) return 0.0;
      return dayList.map((r) => r.glucoseLevel).reduce((a, b) => a + b) /
          dayList.length;
    });
    final maxVal = dayReadings.fold<double>(
      0,
      (prev, v) => v > prev ? v : prev,
    );
    final maxY = (maxVal > 0 ? (maxVal * 1.2).clamp(100.0, 400.0) : 200.0)
        .toDouble();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barGroups: dayReadings.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: (e.value > 0 ? e.value : 0.01).toDouble(),
                color: e.value >= 70 && e.value <= 140
                    ? Colors.green
                    : e.value < 70
                    ? Colors.blue
                    : Colors.orange,
                width: 20,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
              ),
            ],
            showingTooltipIndicators: [0],
          );
        }).toList(),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: TextStyle(color: Colors.grey[600], fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i >= 0 && i < days.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      days[i],
                      style: TextStyle(color: Colors.grey[600], fontSize: 10),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: Colors.grey.withValues(alpha: 0.2), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
      ),
      duration: const Duration(milliseconds: 300),
    );
  }

  Widget _buildUpcomingReminder() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, color: Colors.amber.shade700),
              const SizedBox(width: 8),
              const Text(
                'Upcoming',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RemindersPage()),
                ),
                child: const Text('Manage'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          NextReminderWidget(
            reminder: _nextReminder,
            nextTrigger: _nextReminderAt,
            title: 'Smart Reminder',
          ),
          const SizedBox(height: 16),
          if (_nextMedicineTime != null)
            _buildReminderRow(
              Icons.medication,
              'Next medicine',
              _nextMedicineTime!,
              Colors.purple,
            ),
          if (_nextGlucoseTest != null) ...[
            const SizedBox(height: 12),
            _buildReminderRow(
              Icons.water_drop,
              'Next glucose test',
              _nextGlucoseTest!,
              Colors.teal,
            ),
          ],
          if (_nextAppointment != null) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const PatientAppointmentsPage(),
                  ),
                );
              },
              child: _buildReminderRow(
                Icons.event,
                'My appointments',
                _nextAppointment!,
                _nextAppointmentStatus == AppointmentStatus.accepted
                    ? Colors.green
                    : _nextAppointmentStatus == AppointmentStatus.rejected
                    ? Colors.grey
                    : Colors.blue,
              ),
            ),
          ],
          if (_nextMedicineTime == null &&
              _nextGlucoseTest == null &&
              _nextAppointment == null)
            Text(
              'No upcoming reminders',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
        ],
      ),
    );
  }

  Widget _buildReminderRow(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHealthScore() {
    return HealthScoreCard(
      healthScore: _healthScore,
      isLoading: _healthScoreLoading,
      errorMessage: _healthScoreError,
      onTap: _healthScore == null
          ? null
          : () {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HealthScoreDetailsPage(
                    userId: user.uid,
                    initialScore: _healthScore,
                    initialPeriod: HealthScorePeriod.last7Days,
                  ),
                ),
              );
            },
      onViewDetails: _healthScore == null
          ? null
          : () {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HealthScoreDetailsPage(
                    userId: user.uid,
                    initialScore: _healthScore,
                    initialPeriod: HealthScorePeriod.last7Days,
                  ),
                ),
              );
            },
    );
  }

  Widget _buildDoctorConsultSection() {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DoctorConsultationPage()),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                Icons.medical_services,
                color: Colors.blue.shade600,
                size: 40,
              ),
            ),
            const SizedBox(width: 20),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Consult with a Doctor',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Get expert advice from specialized doctors',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesSection() {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ConversationListPage()),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(Icons.chat, color: Colors.orange.shade600, size: 40),
            ),
            const SizedBox(width: 20),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Messages',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Chat with your doctor',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDiabetesEssentialsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.book, color: Colors.purple, size: 28),
              SizedBox(width: 10),
              Text(
                'Diabetes Essentials',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildEssentialItem(
            'Understanding Diabetes',
            Icons.info_outline,
            Colors.orange,
          ),
          const SizedBox(height: 10),
          _buildEssentialItem(
            'Diet & Nutrition',
            Icons.restaurant_menu,
            Colors.green,
          ),
          const SizedBox(height: 10),
          _buildEssentialItem(
            'Exercise Tips',
            Icons.fitness_center,
            Colors.red,
          ),
          const SizedBox(height: 10),
          _buildEssentialItem(
            'Medication Guide',
            Icons.medication,
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildEssentialItem(String title, IconData icon, Color color) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DiabetesEssentialsPage()),
      ),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }

  void _navigateToAddReading() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddReadingPage()),
    );
    _loadData();
  }
}
