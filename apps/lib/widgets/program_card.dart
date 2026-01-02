import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/program.dart';
import '../config/theme.dart';
import '../utils/category_icons.dart';
import '../services/export_service.dart';

class ProgramCard extends StatefulWidget {
  final Program program;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;

  const ProgramCard({
    super.key,
    required this.program,
    this.isFavorite = false,
    this.onTap,
    this.onFavoriteToggle,
  });

  @override
  State<ProgramCard> createState() => _ProgramCardState();
}

class _ProgramCardState extends State<ProgramCard> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showContextMenu(BuildContext context, Offset position) {
    final isDesktop = Platform.isMacOS || Platform.isWindows || Platform.isLinux;
    if (!isDesktop) return;

    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      items: [
        const PopupMenuItem(
          value: 'open',
          child: ListTile(
            leading: Icon(Icons.open_in_new, size: 20),
            title: Text('Open'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        PopupMenuItem(
          value: 'save',
          child: ListTile(
            leading: Icon(
              widget.isFavorite ? Icons.bookmark_remove : Icons.bookmark_add,
              size: 20,
            ),
            title: Text(widget.isFavorite ? 'Remove from Saved' : 'Save'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'copy',
          child: ListTile(
            leading: Icon(Icons.copy, size: 20),
            title: Text('Copy Info'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        if (widget.program.website.isNotEmpty)
          const PopupMenuItem(
            value: 'website',
            child: ListTile(
              leading: Icon(Icons.language, size: 20),
              title: Text('Open Website'),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
      ],
    ).then((value) {
      if (value == null) return;

      switch (value) {
        case 'open':
          widget.onTap?.call();
          break;
        case 'save':
          widget.onFavoriteToggle?.call();
          break;
        case 'copy':
          _copyToClipboard();
          break;
        case 'website':
          _openWebsite();
          break;
      }
    });
  }

  Future<void> _copyToClipboard() async {
    await ExportService.copyToClipboard(widget.program);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Program info copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _openWebsite() async {
    if (widget.program.website.isEmpty) return;
    final uri = Uri.parse(widget.program.website);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final catColor = CategoryIcons.getCategoryColor(widget.program.category);
    final isDesktop = Platform.isMacOS || Platform.isWindows || Platform.isLinux;

    // Create gradient colors for header
    final gradientEnd = Color.lerp(catColor, isDark ? const Color(0xFF1e293b) : const Color(0xFF0f172a), 0.4)!;

    Widget card = MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _animationController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _animationController.reverse();
      },
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // Perspective
              ..setTranslationRaw(0.0, _isHovered ? -12.0 : 0.0, 0.0)
              ..scaleByDouble(_scaleAnimation.value, _scaleAnimation.value, 1.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  // Base ambient shadow - always visible for depth
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
                    blurRadius: _isHovered ? 48 : 20,
                    spreadRadius: _isHovered ? 0 : -4,
                    offset: Offset(0, _isHovered ? 24 : 8),
                  ),
                  // Category color glow on hover
                  if (_isHovered)
                    BoxShadow(
                      color: catColor.withValues(alpha: 0.35),
                      blurRadius: 36,
                      spreadRadius: -6,
                      offset: const Offset(0, 12),
                    ),
                ],
              ),
              child: Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: _isHovered
                        ? catColor.withValues(alpha: 0.6)
                        : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    width: _isHovered ? 2 : 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: widget.onTap,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                // Gradient header with category visual
                Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [catColor, gradientEnd],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Background pattern/icon
                      Positioned(
                        right: -20,
                        top: -20,
                        child: Icon(
                          CategoryIcons.getIcon(widget.program.category),
                          size: 120,
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      // Category badge
                      Positioned(
                        left: 12,
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.program.category.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      // Save button - 48x48 minimum touch target for accessibility
                      if (widget.onFavoriteToggle != null)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Semantics(
                            button: true,
                            label: widget.isFavorite ? 'Remove from saved programs' : 'Save program',
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  widget.onFavoriteToggle!();
                                },
                                borderRadius: BorderRadius.circular(24),
                                child: Tooltip(
                                  message: widget.isFavorite ? 'Remove from saved' : 'Save program',
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.95),
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      widget.isFavorite ? Icons.bookmark : Icons.bookmark_border,
                                      size: 24,
                                      color: widget.isFavorite
                                          ? AppColors.danger
                                          : const Color(0xFF6b7280),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Card body
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          widget.program.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),

                        // Location
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.program.locationText,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Description
                        Expanded(
                          child: Text(
                            widget.program.description,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              height: 1.5,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Eligibility tags
                        if (widget.program.eligibility.isNotEmpty)
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: widget.program.eligibility.take(3).map((e) =>
                              _buildEligibilityTag(context, e)
                            ).toList(),
                          ),

                        const SizedBox(height: 12),

                        // Footer with divider
                        Container(
                          padding: const EdgeInsets.only(top: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Area tag
                              if (widget.program.areas.isNotEmpty)
                                Text(
                                  widget.program.areas.first,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                  ),
                                ),
                              const Spacer(),
                              // View details link
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'View Details',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        ),
      );
    },
  ),
);

    // Wrap with GestureDetector for right-click context menu on desktop
    if (isDesktop) {
      card = GestureDetector(
        onSecondaryTapUp: (details) {
          _showContextMenu(context, details.globalPosition);
        },
        child: card,
      );
    }

    return card;
  }

  Widget _buildEligibilityTag(BuildContext context, String eligibility) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Format the eligibility text
    String displayText = eligibility
        .replaceAll('-', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
        .join(' ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF374151) : const Color(0xFFf3f4f6),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: isDark ? const Color(0xFF9ca3af) : const Color(0xFF6b7280),
        ),
      ),
    );
  }
}
