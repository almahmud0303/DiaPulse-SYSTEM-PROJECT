import 'package:dia_plus/features/patient/screens/edit_reading_page.dart';
import 'package:dia_plus/core/theme/app_theme.dart';
import 'package:dia_plus/models/glucose_reading.dart';
import 'package:dia_plus/services/glucose_reading_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Page displaying glucose readings for the patient. Search, edit, delete.
class ReadingsPage extends StatefulWidget {
  const ReadingsPage({super.key});

  @override
  State<ReadingsPage> createState() => _ReadingsPageState();
}

class _ReadingsPageState extends State<ReadingsPage> {
  final GlucoseReadingService _readingService = GlucoseReadingService();
  final TextEditingController _searchController = TextEditingController();
  String? _userId;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;
    _searchController.addListener(
      () => setState(
        () => _searchQuery = _searchController.text.trim().toLowerCase(),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<GlucoseReading> _filterReadings(List<GlucoseReading> readings) {
    if (_searchQuery.isEmpty) return readings;
    return readings.where((r) {
      final matchValue = r.glucoseLevel.toInt().toString();
      final matchMeal = r.mealTime.toLowerCase();
      final matchNotes = (r.notes).toLowerCase();
      final matchDate = DateFormat('yyyy-MM-dd').format(r.date);
      return matchValue.contains(_searchQuery) ||
          matchMeal.contains(_searchQuery) ||
          matchNotes.contains(_searchQuery) ||
          matchDate.contains(_searchQuery);
    }).toList();
  }

  Color _getReadingColor(double level) {
    if (level < 70) return AppTheme.secondaryLavender;
    if (level <= 140) return AppTheme.primaryMint;
    if (level <= 200) return AppTheme.accentPeach;
    return AppTheme.softError;
  }

  String _getReadingStatus(double level) {
    if (level < 70) return 'Low';
    if (level <= 140) return 'Normal';
    if (level <= 200) return 'High';
    return 'Very High';
  }

  IconData _getMealIcon(String mealTime) {
    switch (mealTime) {
      case 'Fasting':
        return Icons.wb_sunny_outlined;
      case 'Before meal':
        return Icons.restaurant_outlined;
      case 'After meal':
        return Icons.restaurant;
      case 'Bedtime':
        return Icons.nightlight_round;
      case 'Post Breakfast':
        return Icons.free_breakfast;
      case 'Pre Lunch':
        return Icons.lunch_dining_outlined;
      case 'Post Lunch':
        return Icons.restaurant;
      case 'Pre Dinner':
        return Icons.dinner_dining_outlined;
      case 'Post Dinner':
        return Icons.restaurant_menu;
      case 'Random':
        return Icons.shuffle;
      default:
        return Icons.access_time;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Please log in to view readings',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: StreamBuilder<List<GlucoseReading>>(
                stream: _readingService.getUserReadingsStream(_userId!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading readings',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            snapshot.error.toString(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  final readings = snapshot.data ?? [];
                  final filtered = _filterReadings(readings);

                  if (readings.isEmpty) {
                    return _buildEmptyState();
                  }
                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No readings match "$_searchQuery"',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  }

                  return _buildReadingsList(filtered);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryMint, AppTheme.secondaryLavender],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.analytics,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Readings',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track your glucose levels',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            style: TextStyle(color: AppTheme.textPrimaryColor(context)),
            decoration: InputDecoration(
              hintText: 'Search by value, type, notes, date...',
              hintStyle: TextStyle(color: AppTheme.textSecondaryColor(context)),
              prefixIcon: Icon(
                Icons.search,
                color: AppTheme.textSecondaryColor(context),
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.88),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.cardTintMintColor(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_chart,
                size: 80,
                color: AppTheme.primaryMint,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Readings Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor(context),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start tracking your glucose levels by adding your first reading',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondaryColor(context),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingsList(List<GlucoseReading> readings) {
    // Group readings by date
    final Map<String, List<GlucoseReading>> groupedReadings = {};
    for (final reading in readings) {
      final dateKey = DateFormat('yyyy-MM-dd').format(reading.date);
      groupedReadings.putIfAbsent(dateKey, () => []).add(reading);
    }

    final sortedDates = groupedReadings.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final dateKey = sortedDates[index];
        final dateReadings = groupedReadings[dateKey]!;
        final date = DateTime.parse(dateKey);

        return _buildDateGroup(date, dateReadings);
      },
    );
  }

  Widget _buildDateGroup(DateTime date, List<GlucoseReading> readings) {
    final isToday =
        DateFormat('yyyy-MM-dd').format(DateTime.now()) ==
        DateFormat('yyyy-MM-dd').format(date);
    final isYesterday =
        DateFormat(
          'yyyy-MM-dd',
        ).format(DateTime.now().subtract(const Duration(days: 1))) ==
        DateFormat('yyyy-MM-dd').format(date);

    String dateLabel;
    if (isToday) {
      dateLabel = 'Today';
    } else if (isYesterday) {
      dateLabel = 'Yesterday';
    } else {
      dateLabel = DateFormat('EEEE, MMMM d').format(date);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          child: Text(
            dateLabel,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor(context),
            ),
          ),
        ),
        ...readings.map((reading) => _buildReadingCard(reading)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildReadingCard(GlucoseReading reading) {
    final color = _getReadingColor(reading.glucoseLevel);
    final status = _getReadingStatus(reading.glucoseLevel);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardTintMintColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0x12000000),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.2),
                    color.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    reading.glucoseLevel.toInt().toString(),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    'mg/dL',
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        _getMealIcon(reading.mealTime),
                        size: 18,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          reading.mealTime,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimaryColor(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 16, color: Colors.grey[500]),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('h:mm a').format(reading.date),
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondaryColor(context),
                        ),
                      ),
                    ],
                  ),
                  if (reading.notes.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      reading.notes,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondaryColor(context),
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: Icon(Icons.edit_outlined),
                  onPressed: () async {
                    final updated = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditReadingPage(reading: reading),
                      ),
                    );
                    if (updated == true && mounted) setState(() {});
                  },
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red[400]),
                  onPressed: () => _confirmDelete(reading),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(GlucoseReading reading) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete reading?'),
        content: Text(
          '${reading.glucoseLevel.toInt()} mg/dL (${reading.mealTime}) will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.softError),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await _readingService.deleteReading(reading.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reading deleted'),
            backgroundColor: AppTheme.primaryMint,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: AppTheme.softError,
          ),
        );
      }
    }
  }
}
