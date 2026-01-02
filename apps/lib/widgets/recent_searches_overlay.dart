import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../config/theme.dart';

class RecentSearchesOverlay extends StatefulWidget {
  final LayerLink layerLink;
  final VoidCallback onDismiss;
  final Function(String) onSearchSelected;
  final double width;

  const RecentSearchesOverlay({
    super.key,
    required this.layerLink,
    required this.onDismiss,
    required this.onSearchSelected,
    required this.width,
  });

  @override
  State<RecentSearchesOverlay> createState() => _RecentSearchesOverlayState();
}

class _RecentSearchesOverlayState extends State<RecentSearchesOverlay> {
  final ApiService _apiService = ApiService();
  List<String> _searches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSearches();
  }

  Future<void> _loadSearches() async {
    final searches = await _apiService.getRecentSearches();
    if (mounted) {
      setState(() {
        _searches = searches;
        _isLoading = false;
      });
    }
  }

  Future<void> _clearSearches() async {
    await _apiService.clearRecentSearches();
    if (mounted) {
      setState(() {
        _searches = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading || _searches.isEmpty) {
      return const SizedBox.shrink();
    }

    return CompositedTransformFollower(
      link: widget.layerLink,
      targetAnchor: Alignment.bottomLeft,
      followerAnchor: Alignment.topLeft,
      offset: const Offset(0, 4),
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        color: isDark ? AppColors.darkCard : Colors.white,
        child: Container(
          width: widget.width,
          constraints: const BoxConstraints(maxHeight: 250),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.history,
                      size: 16,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Recent Searches',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _clearSearches,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Clear', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _searches.length,
                  itemBuilder: (context, index) {
                    final search = _searches[index];
                    return Semantics(
                      button: true,
                      label: 'Search for $search',
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          widget.onSearchSelected(search);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search,
                                size: 18,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  search,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                              Icon(
                                Icons.north_west,
                                size: 14,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
