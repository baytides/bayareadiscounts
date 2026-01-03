import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/program.dart';
import '../config/theme.dart';
import '../utils/category_icons.dart';
import '../services/export_service.dart';

/// Program card widget matching web design
/// Clean, minimal card with category badge and essential info
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

class _ProgramCardState extends State<ProgramCard> {
  bool _isHovered = false;

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
    final isDesktop = Platform.isMacOS || Platform.isWindows || Platform.isLinux;

    Widget card = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _isHovered ? 0.12 : 0.08),
              blurRadius: _isHovered ? 16 : 8,
              offset: Offset(0, _isHovered ? 4 : 2),
            ),
          ],
        ),
        child: Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Category badge + Location
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category badge
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            CategoryIcons.buildCategoryBadge(
                              widget.program.category,
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                      // Location
                      Text(
                        widget.program.locationText,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    widget.program.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                      color: _isHovered
                          ? (isDark ? AppColors.primary200 : AppColors.primary)
                          : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Expanded(
                    child: Text(
                      widget.program.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                        height: 1.5,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Footer: Groups + Actions
                  Container(
                    padding: const EdgeInsets.only(top: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Groups/eligibility tags
                        if (widget.program.groups.isNotEmpty)
                          Expanded(
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: widget.program.groups.take(2).map((g) =>
                                _buildGroupTag(context, g, isDark)
                              ).toList(),
                            ),
                          ),
                        const SizedBox(width: 8),
                        // Save button
                        if (widget.onFavoriteToggle != null)
                          Semantics(
                            button: true,
                            label: widget.isFavorite
                                ? 'Remove from saved programs'
                                : 'Save program',
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  widget.onFavoriteToggle!();
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Tooltip(
                                  message: widget.isFavorite
                                      ? 'Remove from saved'
                                      : 'Save program',
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: widget.isFavorite
                                          ? AppColors.dangerLight
                                          : (isDark
                                              ? AppColors.darkNeutral100
                                              : AppColors.lightNeutral100),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Icon(
                                      widget.isFavorite
                                          ? Icons.bookmark
                                          : Icons.bookmark_border,
                                      size: 20,
                                      color: widget.isFavorite
                                          ? AppColors.danger
                                          : (isDark
                                              ? AppColors.darkTextSecondary
                                              : AppColors.lightTextSecondary),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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

  Widget _buildGroupTag(BuildContext context, String group, bool isDark) {
    // Format the group text
    String displayText = group
        .replaceAll('-', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkNeutral100
            : AppColors.lightNeutral100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextMuted,
        ),
      ),
    );
  }
}
