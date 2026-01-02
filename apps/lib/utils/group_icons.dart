import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Group icons utility matching web design
/// Maps program group icon names to appropriate Material icons
class GroupIcons {
  static const Map<String, IconData> _groupIcons = {
    // Students / Education
    'GraduationCap': Icons.school_outlined,

    // Seniors / Health
    'Heart': Icons.favorite_outline,

    // Families / Community
    'Users': Icons.people_outline,

    // Workers / Employment
    'Briefcase': Icons.work_outline,

    // Housing
    'Home': Icons.home_outlined,

    // Veterans / Military
    'Shield': Icons.shield_outlined,

    // Children / Childcare
    'Baby': Icons.child_care_outlined,

    // Disability / Accessibility
    'Accessibility': Icons.accessible_outlined,

    // Environment / Sustainability
    'Leaf': Icons.eco_outlined,

    // Financial / Income-Eligible
    'DollarSign': Icons.attach_money,
  };

  /// Get icon for a group based on its icon name from the API
  static IconData getIcon(String? iconName) {
    if (iconName == null || iconName.isEmpty) {
      return Icons.group_outlined;
    }
    return _groupIcons[iconName] ?? Icons.group_outlined;
  }

  /// Get group color based on icon name
  static Color getGroupColor(String? iconName) {
    if (iconName == null || iconName.isEmpty) {
      return AppColors.primary;
    }

    switch (iconName) {
      case 'GraduationCap':
        return const Color(0xFF3B82F6); // Blue - Education
      case 'Heart':
        return const Color(0xFFEF4444); // Red - Seniors/Health
      case 'Users':
        return const Color(0xFF10B981); // Green - Families
      case 'Briefcase':
        return const Color(0xFF6366F1); // Indigo - Workers
      case 'Home':
        return const Color(0xFFF59E0B); // Amber - Housing
      case 'Shield':
        return const Color(0xFF64748B); // Slate - Veterans
      case 'Baby':
        return const Color(0xFFEC4899); // Pink - Children
      case 'Accessibility':
        return const Color(0xFF8B5CF6); // Purple - Disability
      case 'Leaf':
        return const Color(0xFF22C55E); // Green - Environment
      case 'DollarSign':
        return const Color(0xFF0EA5E9); // Sky - Financial
      default:
        return AppColors.primary;
    }
  }

  /// Build a group icon widget with background
  static Widget buildGroupIcon(
    String? iconName, {
    double size = 32,
    double iconSize = 18,
    Color? backgroundColor,
    Color? iconColor,
  }) {
    final groupColor = getGroupColor(iconName);
    final bgColor = backgroundColor ?? groupColor.withValues(alpha: 0.15);
    final fgColor = iconColor ?? groupColor;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(size / 3),
      ),
      child: Icon(
        getIcon(iconName),
        size: iconSize,
        color: fgColor,
      ),
    );
  }
}
