import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Category icons utility matching web design
/// Maps program categories to appropriate Material icons
class CategoryIcons {
  static const Map<String, IconData> _categoryIcons = {
    // Food - coffee cup/restaurant
    'food': Icons.restaurant_outlined,
    'food assistance': Icons.restaurant_outlined,

    // Health - heartbeat/medical
    'health': Icons.monitor_heart_outlined,
    'healthcare': Icons.monitor_heart_outlined,
    'medical': Icons.local_hospital_outlined,

    // Recreation - ticket/activity
    'recreation': Icons.confirmation_number_outlined,
    'activities': Icons.confirmation_number_outlined,
    'entertainment': Icons.confirmation_number_outlined,

    // Community / Community Services - users/people
    'community': Icons.people_outline,
    'community services': Icons.people_outline,
    'social services': Icons.people_outline,

    // Education - graduation cap
    'education': Icons.school_outlined,
    'learning': Icons.school_outlined,
    'training': Icons.school_outlined,

    // Finance / Financial Assistance - dollar sign
    'finance': Icons.attach_money,
    'financial': Icons.attach_money,
    'financial assistance': Icons.attach_money,
    'money': Icons.attach_money,

    // Transportation - car
    'transportation': Icons.directions_car_outlined,
    'transit': Icons.directions_bus_outlined,

    // Technology - laptop
    'technology': Icons.laptop_outlined,
    'tech': Icons.laptop_outlined,
    'internet': Icons.wifi_outlined,

    // Legal - scale/gavel
    'legal': Icons.balance_outlined,
    'legal aid': Icons.balance_outlined,

    // Pet Resources - pets
    'pet resources': Icons.pets_outlined,
    'pets': Icons.pets_outlined,
    'animal': Icons.pets_outlined,

    // Equipment - tool/wrench
    'equipment': Icons.build_outlined,
    'tools': Icons.build_outlined,

    // Library Resources - book
    'library resources': Icons.menu_book_outlined,
    'library': Icons.menu_book_outlined,
    'books': Icons.menu_book_outlined,

    // Utilities - lightning/power
    'utilities': Icons.bolt_outlined,
    'energy': Icons.bolt_outlined,
    'power': Icons.bolt_outlined,

    // Childcare Assistance - family/baby
    'childcare': Icons.child_care_outlined,
    'childcare assistance': Icons.child_care_outlined,
    'child care': Icons.child_care_outlined,

    // Clothing Assistance - shirt
    'clothing': Icons.checkroom_outlined,
    'clothing assistance': Icons.checkroom_outlined,

    // Housing
    'housing': Icons.home_outlined,
    'shelter': Icons.night_shelter_outlined,
    'rent': Icons.home_outlined,

    // Employment
    'employment': Icons.work_outline,
    'jobs': Icons.work_outline,
    'career': Icons.work_outline,
  };

  /// Get icon for a category
  static IconData getIcon(String? category) {
    if (category == null || category.isEmpty) {
      return Icons.info_outline;
    }

    final normalized = category.toLowerCase().trim();
    return _categoryIcons[normalized] ?? Icons.info_outline;
  }

  /// Get category color based on category name
  static Color getCategoryColor(String? category) {
    if (category == null || category.isEmpty) {
      return AppColors.primary;
    }

    final normalized = category.toLowerCase().trim();

    // Category color mapping (matching web design)
    switch (normalized) {
      case 'food':
      case 'food assistance':
        return const Color(0xFFFF6F00); // Orange
      case 'health':
      case 'healthcare':
      case 'medical':
        return const Color(0xFFEF4444); // Red
      case 'recreation':
      case 'activities':
      case 'entertainment':
        return const Color(0xFF8B5CF6); // Purple
      case 'community':
      case 'community services':
      case 'social services':
        return const Color(0xFF10B981); // Green
      case 'education':
      case 'learning':
      case 'training':
        return const Color(0xFF3B82F6); // Blue
      case 'finance':
      case 'financial':
      case 'financial assistance':
        return const Color(0xFF22C55E); // Green
      case 'transportation':
      case 'transit':
        return const Color(0xFF0EA5E9); // Sky blue
      case 'technology':
      case 'tech':
      case 'internet':
        return const Color(0xFF6366F1); // Indigo
      case 'legal':
      case 'legal aid':
        return const Color(0xFF64748B); // Slate
      case 'housing':
      case 'shelter':
        return const Color(0xFFF59E0B); // Amber
      case 'employment':
      case 'jobs':
      case 'career':
        return const Color(0xFF0891B2); // Cyan
      default:
        return AppColors.primary; // Teal
    }
  }

  /// Build a category icon widget with background
  static Widget buildCategoryIcon(
    String? category, {
    double size = 24,
    double iconSize = 16,
    Color? backgroundColor,
    Color? iconColor,
  }) {
    final catColor = getCategoryColor(category);
    final bgColor = backgroundColor ?? catColor.withValues(alpha: 0.1);
    final fgColor = iconColor ?? catColor;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(size / 4),
      ),
      child: Icon(
        getIcon(category),
        size: iconSize,
        color: fgColor,
      ),
    );
  }

  /// Build a large category header icon (for detail views)
  static Widget buildHeaderIcon(
    String? category, {
    double size = 80,
    double iconSize = 40,
  }) {
    final catColor = getCategoryColor(category);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            catColor,
            catColor.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(size / 4),
        boxShadow: [
          BoxShadow(
            color: catColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        getIcon(category),
        size: iconSize,
        color: Colors.white,
      ),
    );
  }
}
