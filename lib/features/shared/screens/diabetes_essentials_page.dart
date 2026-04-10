import 'package:dia_plus/models/app_config_item.dart';
import 'package:dia_plus/services/config_service.dart';
import 'package:flutter/material.dart';

class DiabetesEssentialsPage extends StatefulWidget {
  const DiabetesEssentialsPage({super.key});

  @override
  State<DiabetesEssentialsPage> createState() => _DiabetesEssentialsPageState();
}

class _DiabetesEssentialsPageState extends State<DiabetesEssentialsPage> {
  final ConfigService _configService = ConfigService();
  String? _selectedSection;

  static const List<String> _sectionOrder = [
    'Understanding Diabetes',
    'Diet and Nutrition',
    'Exercise Tips',
    'Medication Guide',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Diabetes Essentials'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade400, Colors.purple.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.book, color: Colors.white, size: 48),
                SizedBox(height: 15),
                Text(
                  'Learn About Diabetes',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Everything you need to know to manage your diabetes effectively',
                  style: TextStyle(fontSize: 14, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          StreamBuilder<List<AppConfigItem>>(
            stream: _configService.getDiabetesEssentials(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snap.hasError) {
                return Text(
                  'Could not load diabetes essentials: ${snap.error}',
                  style: const TextStyle(color: Colors.red),
                );
              }

              final items = snap.data ?? const <AppConfigItem>[];
              if (items.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    'No diabetes essentials configured yet. Please contact admin.',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                );
              }

              final grouped = <String, List<AppConfigItem>>{
                for (final s in _sectionOrder) s: <AppConfigItem>[],
                'Other': <AppConfigItem>[],
              };
              for (final item in items) {
                final section = _resolveSection(item.section);
                grouped[section]!.add(item);
              }

              final availableSections = grouped.entries
                  .where((entry) => entry.value.isNotEmpty)
                  .map((entry) => entry.key)
                  .toList();

              if (availableSections.isNotEmpty &&
                  (_selectedSection == null ||
                      !availableSections.contains(_selectedSection))) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  setState(() => _selectedSection = availableSections.first);
                });
              }

              final activeSection = _selectedSection;
              final visibleItems = activeSection == null
                  ? const <AppConfigItem>[]
                  : grouped[activeSection] ?? const <AppConfigItem>[];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availableSections.map((section) {
                      final selected = section == activeSection;
                      return ChoiceChip(
                        label: Text(section),
                        selected: selected,
                        onSelected: (_) =>
                            setState(() => _selectedSection = section),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  if (activeSection != null) _buildSectionHeader(activeSection),
                  const SizedBox(height: 12),
                  if (visibleItems.isEmpty)
                    Text(
                      'No content in this section yet.',
                      style: TextStyle(color: Colors.grey.shade700),
                    )
                  else
                    ...visibleItems.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildContentCard(
                          item.name,
                          item.description ?? '',
                          _iconForSection(activeSection ?? 'Other'),
                          _parseColor(item.color, Colors.purple),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String section) {
    return Row(
      children: [
        Icon(_iconForSection(section), color: Colors.purple.shade600, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            section,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  IconData _iconForSection(String section) {
    final s = section.toLowerCase().trim();
    if (s.contains('understanding')) return Icons.school_outlined;
    if (s.contains('diet') || s.contains('nutrition'))
      return Icons.restaurant_menu;
    if (s.contains('exercise')) return Icons.fitness_center;
    if (s.contains('medication')) return Icons.medication_outlined;
    return Icons.info_outline;
  }

  String _resolveSection(String? rawSection) {
    final value = (rawSection ?? '').trim().toLowerCase();
    if (value.isEmpty) return 'Other';
    if (value.contains('understanding')) return 'Understanding Diabetes';
    if (value.contains('diet') || value.contains('nutrition'))
      return 'Diet and Nutrition';
    if (value.contains('exercise')) return 'Exercise Tips';
    if (value.contains('medication')) return 'Medication Guide';
    return 'Other';
  }

  static Color _parseColor(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    final cleaned = hex.replaceFirst('#', '');
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return fallback;
    return Color(cleaned.length == 6 ? (0xFF000000 | value) : value);
  }

  Widget _buildContentCard(
    String title,
    String content,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
