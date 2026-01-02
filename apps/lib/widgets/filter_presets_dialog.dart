import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/program.dart';
import '../providers/programs_provider.dart';
import '../services/api_service.dart';
import '../config/theme.dart';

class FilterPresetsDialog extends StatefulWidget {
  const FilterPresetsDialog({super.key});

  @override
  State<FilterPresetsDialog> createState() => _FilterPresetsDialogState();
}

class _FilterPresetsDialogState extends State<FilterPresetsDialog> {
  final ApiService _apiService = ApiService();
  List<FilterPreset> _presets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPresets();
  }

  Future<void> _loadPresets() async {
    final presets = await _apiService.getFilterPresets();
    if (mounted) {
      setState(() {
        _presets = presets;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveCurrentFilters() async {
    final provider = context.read<ProgramsProvider>();
    if (!provider.filterState.hasFilters) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No filters to save')),
      );
      return;
    }

    final name = await _showNameDialog();
    if (name == null || name.isEmpty) return;

    final preset = await _apiService.saveFilterPreset(name, provider.filterState);
    if (preset != null) {
      await _loadPresets();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved "$name" filter preset')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save preset (max 10 reached)')),
        );
      }
    }
  }

  Future<String?> _showNameDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Filter Preset'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Preset Name',
            hintText: 'e.g., "Food programs for seniors"',
          ),
          textCapitalization: TextCapitalization.sentences,
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePreset(FilterPreset preset) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Preset'),
        content: Text('Delete "${preset.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _apiService.deleteFilterPreset(preset.id);
      await _loadPresets();
    }
  }

  void _applyPreset(FilterPreset preset) {
    HapticFeedback.lightImpact();
    context.read<ProgramsProvider>().applyFilterPreset(preset);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Applied "${preset.name}" filters')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<ProgramsProvider>();

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.bookmark_border),
          const SizedBox(width: 8),
          const Text('Filter Presets'),
          const Spacer(),
          if (provider.filterState.hasFilters)
            TextButton.icon(
              onPressed: _saveCurrentFilters,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Save Current'),
            ),
        ],
      ),
      content: SizedBox(
        width: 400,
        height: 300,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _presets.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bookmarks_outlined,
                          size: 48,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No saved presets',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Apply filters and save them for quick access',
                          style: theme.textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _presets.length,
                    itemBuilder: (context, index) {
                      final preset = _presets[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(preset.name),
                          subtitle: Text(
                            _getPresetSummary(preset),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20),
                                onPressed: () => _deletePreset(preset),
                                tooltip: 'Delete',
                              ),
                              const SizedBox(width: 8),
                              FilledButton(
                                onPressed: () => _applyPreset(preset),
                                child: const Text('Apply'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  String _getPresetSummary(FilterPreset preset) {
    final parts = <String>[];

    if (preset.filters.categories.isNotEmpty) {
      parts.add('${preset.filters.categories.length} categories');
    }
    if (preset.filters.groups.isNotEmpty) {
      parts.add('${preset.filters.groups.length} groups');
    }
    if (preset.filters.areas.isNotEmpty) {
      parts.add('${preset.filters.areas.length} areas');
    }
    if (preset.filters.searchQuery.isNotEmpty) {
      parts.add('search: "${preset.filters.searchQuery}"');
    }

    return parts.isEmpty ? 'No filters' : parts.join(', ');
  }
}
