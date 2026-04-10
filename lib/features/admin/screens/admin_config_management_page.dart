import 'package:dia_plus/models/app_config_item.dart';
import 'package:dia_plus/services/admin_config_service.dart';
import 'package:dia_plus/ui/responsive.dart';
import 'package:flutter/material.dart';

/// Reusable CRUD screen for managing any app_config collection.
///
/// Pass the Firestore sub-collection key (e.g. `meal_categories`) and a
/// user-friendly title. Admin can add, edit, toggle active, reorder, and delete.
class AdminConfigManagementPage extends StatefulWidget {
  const AdminConfigManagementPage({
    super.key,
    required this.collection,
    required this.title,
    this.showDescription = true,
    this.showColorField = false,
    this.showIconField = false,
    this.showSectionField = false,
    this.sectionLabel = 'Section',
    this.sectionOptions = const [],
  });

  final String collection;
  final String title;
  final bool showDescription;
  final bool showColorField;
  final bool showIconField;
  final bool showSectionField;
  final String sectionLabel;
  final List<String> sectionOptions;

  @override
  State<AdminConfigManagementPage> createState() =>
      _AdminConfigManagementPageState();
}

class _AdminConfigManagementPageState extends State<AdminConfigManagementPage> {
  final _service = AdminConfigService();

  // ── Add / Edit dialog ────────────────────────────────────────────────

  Future<void> _showItemDialog({AppConfigItem? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final orderCtrl = TextEditingController(
      text: (existing?.order ?? 0).toString(),
    );
    final colorCtrl = TextEditingController(text: existing?.color ?? '');
    final iconCtrl = TextEditingController(text: existing?.icon ?? '');
    final customSectionCtrl = TextEditingController();

    final existingSection = existing?.section;
    String? selectedSection;
    if (widget.showSectionField) {
      if (existingSection != null &&
          widget.sectionOptions.any(
            (option) =>
                option.toLowerCase().trim() ==
                existingSection.toLowerCase().trim(),
          )) {
        selectedSection = existingSection;
      } else if (existingSection != null && existingSection.isNotEmpty) {
        selectedSection = '__custom__';
        customSectionCtrl.text = existingSection;
      } else {
        selectedSection = widget.sectionOptions.isNotEmpty
            ? widget.sectionOptions.first
            : '__custom__';
      }
    }
    bool isActive = existing?.isActive ?? true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Add item' : 'Edit item'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Name *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (widget.showDescription) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: orderCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Sort order',
                      border: OutlineInputBorder(),
                      helperText: 'Lower number = shown first',
                    ),
                  ),
                  if (widget.showColorField) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: colorCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Color (hex, e.g. #FF5722)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                  if (widget.showIconField) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: iconCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Icon name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                  if (widget.showSectionField) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedSection,
                      decoration: InputDecoration(
                        labelText: widget.sectionLabel,
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        ...widget.sectionOptions.map(
                          (section) => DropdownMenuItem<String>(
                            value: section,
                            child: Text(section),
                          ),
                        ),
                        const DropdownMenuItem<String>(
                          value: '__custom__',
                          child: Text('Custom'),
                        ),
                      ],
                      onChanged: (value) =>
                          setDialogState(() => selectedSection = value),
                    ),
                    if (selectedSection == '__custom__') ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: customSectionCtrl,
                        decoration: InputDecoration(
                          labelText:
                              'Custom ${widget.sectionLabel.toLowerCase()}',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: isActive,
                    title: const Text('Active'),
                    subtitle: Text(
                      isActive ? 'Visible to users' : 'Hidden from users',
                    ),
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) => setDialogState(() => isActive = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(existing == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );

    if (ok != true) return;

    final name = nameCtrl.text.trim();
    if (name.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name is required.')));
      return;
    }

    final order = int.tryParse(orderCtrl.text.trim()) ?? 0;
    final selectedIsCustom = selectedSection == '__custom__';
    final resolvedSection = !widget.showSectionField
        ? null
        : (selectedIsCustom
              ? customSectionCtrl.text.trim()
              : (selectedSection ?? '').trim());

    if (widget.showSectionField &&
        (resolvedSection == null || resolvedSection.isEmpty)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.sectionLabel} is required.')),
      );
      return;
    }

    final sectionValue = (resolvedSection == null || resolvedSection.isEmpty)
        ? null
        : resolvedSection;
    final metadata = <String, dynamic>{...?existing?.metadata};
    if (sectionValue != null) {
      metadata['section'] = sectionValue;
    } else {
      metadata.remove('section');
    }
    final finalMetadata = metadata.isEmpty ? null : metadata;

    try {
      if (existing == null) {
        // Create
        await _service.addItem(
          widget.collection,
          AppConfigItem(
            id: '',
            name: name,
            description: descCtrl.text.trim().isEmpty
                ? null
                : descCtrl.text.trim(),
            color: colorCtrl.text.trim().isEmpty ? null : colorCtrl.text.trim(),
            icon: iconCtrl.text.trim().isEmpty ? null : iconCtrl.text.trim(),
            order: order,
            isActive: isActive,
            metadata: finalMetadata,
          ),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Item added.')));
      } else {
        // Update
        await _service.updateItem(widget.collection, existing.id, {
          'name': name,
          'description': descCtrl.text.trim().isEmpty
              ? null
              : descCtrl.text.trim(),
          'color': colorCtrl.text.trim().isEmpty ? null : colorCtrl.text.trim(),
          'icon': iconCtrl.text.trim().isEmpty ? null : iconCtrl.text.trim(),
          'order': order,
          'isActive': isActive,
          'metadata': finalMetadata,
        });
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Item updated.')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ── Delete confirmation ──────────────────────────────────────────────

  Future<void> _confirmDelete(AppConfigItem item) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete item?'),
        content: Text(
          'Are you sure you want to permanently delete "${item.name}"?\n\n'
          'Consider deactivating instead if this value is already in use.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (yes != true) return;

    try {
      await _service.deleteItem(
        widget.collection,
        item.id,
        itemName: item.name,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Item deleted.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed: () => _showItemDialog(),
            icon: const Icon(Icons.add),
            tooltip: 'Add item',
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveCenter(
          child: Padding(
            padding: Responsive.pagePadding(context),
            child: StreamBuilder<List<AppConfigItem>>(
              stream: _service.watchAll(widget.collection),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Failed: ${snap.error}'));
                }
                final items = snap.data ?? const <AppConfigItem>[];
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No items yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () => _showItemDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('Add first item'),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _ItemCard(
                    item: items[i],
                    onEdit: () => _showItemDialog(existing: items[i]),
                    onToggleActive: () => _service.toggleActive(
                      widget.collection,
                      items[i].id,
                      !items[i].isActive,
                    ),
                    onDelete: () => _confirmDelete(items[i]),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showItemDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }
}

// ── Item card widget ─────────────────────────────────────────────────────

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.item,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
  });

  final AppConfigItem item;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: item.isActive ? 1 : 0,
      color: item.isActive ? null : Colors.grey.shade100,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: item.isActive
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.grey.shade300,
          child: Text(
            '${item.order}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: item.isActive
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Colors.grey.shade600,
            ),
          ),
        ),
        title: Text(
          item.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: item.isActive ? null : TextDecoration.lineThrough,
            color: item.isActive ? null : Colors.grey,
          ),
        ),
        subtitle: item.description != null && item.description!.isNotEmpty
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.section != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Section: ${item.section}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ],
              )
            : (item.section != null
                  ? Text(
                      'Section: ${item.section}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    )
                  : null),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Chip(
              label: Text(
                item.isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  fontSize: 12,
                  color: item.isActive ? Colors.green : Colors.grey,
                ),
              ),
              backgroundColor: item.isActive
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.1),
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
            PopupMenuButton<String>(
              onSelected: (v) {
                switch (v) {
                  case 'edit':
                    onEdit();
                  case 'toggle':
                    onToggleActive();
                  case 'delete':
                    onDelete();
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(item.isActive ? 'Deactivate' : 'Activate'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
