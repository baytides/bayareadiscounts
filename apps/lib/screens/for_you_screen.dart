import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/program.dart';
import '../providers/programs_provider.dart';
import '../providers/user_prefs_provider.dart';
import '../widgets/program_card.dart';
import 'program_detail_screen.dart';

class ForYouScreen extends StatelessWidget {
  const ForYouScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);
    final screenWidth = MediaQuery.of(context).size.width;
    final useDesktopLayout = isDesktop && screenWidth >= 800;

    return Scaffold(
      body: SafeArea(
        top: !useDesktopLayout,
        child: Consumer2<ProgramsProvider, UserPrefsProvider>(
          builder: (context, programsProvider, userPrefsProvider, child) {
            if (programsProvider.isLoading && programsProvider.programs.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (programsProvider.error != null && programsProvider.programs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: AppColors.danger),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load programs',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      programsProvider.error!,
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => programsProvider.loadData(forceRefresh: true),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            // Get personalized programs based on user preferences
            final personalizedPrograms = _getPersonalizedPrograms(
              programsProvider,
              userPrefsProvider,
            );

            // Get recommended programs (top picks based on preferences)
            final recommendedPrograms = _getRecommendedPrograms(
              programsProvider,
              userPrefsProvider,
            );

            return RefreshIndicator(
              onRefresh: () => programsProvider.loadData(forceRefresh: true),
              child: CustomScrollView(
                slivers: [
                  // Header
                  if (!useDesktopLayout)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                'assets/images/favicons/web-app-manifest-512x512.png',
                                width: 48,
                                height: 48,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'For You',
                                    style: theme.textTheme.titleLarge,
                                  ),
                                  Text(
                                    'Personalized recommendations',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // User preferences summary
                  if (userPrefsProvider.hasPreferences)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildPreferencesSummary(
                          context,
                          userPrefsProvider,
                          programsProvider,
                          isDark,
                        ),
                      ),
                    ),

                  // No preferences message
                  if (!userPrefsProvider.hasPreferences)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : AppColors.lightCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.person_add_outlined,
                                size: 48,
                                color: AppColors.primary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Set up your profile',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tell us about yourself to see personalized recommendations.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: () {
                                  userPrefsProvider.reopenOnboarding();
                                },
                                icon: const Icon(Icons.edit),
                                label: const Text('Set up profile'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Recommended section (if has preferences)
                  if (userPrefsProvider.hasPreferences && recommendedPrograms.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                        child: Row(
                          children: [
                            Icon(Icons.star, color: AppColors.accent, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Top Picks for You',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 340,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: recommendedPrograms.length,
                          itemBuilder: (context, index) {
                            final program = recommendedPrograms[index];
                            return Container(
                              width: 300,
                              margin: EdgeInsets.only(right: index < recommendedPrograms.length - 1 ? 16 : 0),
                              child: ProgramCard(
                                program: program,
                                isFavorite: programsProvider.isFavorite(program.id),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => ProgramDetailScreen(program: program),
                                    ),
                                  );
                                },
                                onFavoriteToggle: () {
                                  programsProvider.toggleFavorite(program.id);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],

                  // All matching programs section
                  if (userPrefsProvider.hasPreferences) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                        child: Row(
                          children: [
                            Text(
                              'All Matching Programs',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${personalizedPrograms.length}',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Programs grid
                  if (personalizedPrograms.isEmpty && userPrefsProvider.hasPreferences)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No matching programs',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try updating your profile preferences',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (userPrefsProvider.hasPreferences)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverLayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.crossAxisExtent;
                          int crossAxisCount;
                          if (width >= 1200) {
                            crossAxisCount = 4;
                          } else if (width >= 900) {
                            crossAxisCount = 3;
                          } else if (width >= 600) {
                            crossAxisCount = 2;
                          } else {
                            crossAxisCount = 1;
                          }

                          const cardHeight = 340.0;
                          final cardWidth = (width - (crossAxisCount - 1) * 16) / crossAxisCount;
                          final aspectRatio = cardWidth / cardHeight;

                          return SliverGrid(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: aspectRatio,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final program = personalizedPrograms[index];
                                return ProgramCard(
                                  program: program,
                                  isFavorite: programsProvider.isFavorite(program.id),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => ProgramDetailScreen(program: program),
                                      ),
                                    );
                                  },
                                  onFavoriteToggle: () {
                                    programsProvider.toggleFavorite(program.id);
                                  },
                                );
                              },
                              childCount: personalizedPrograms.length,
                            ),
                          );
                        },
                      ),
                    ),

                  // Bottom padding
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 16),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPreferencesSummary(
    BuildContext context,
    UserPrefsProvider userPrefsProvider,
    ProgramsProvider programsProvider,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final groups = userPrefsProvider.selectedGroups;
    final countyId = userPrefsProvider.selectedCounty;

    // Get group names
    final groupNames = groups
        .map((id) => programsProvider.groups.where((g) => g.id == id).firstOrNull?.name)
        .whereType<String>()
        .toList();

    // Get county name
    final countyName = countyId != null
        ? programsProvider.areas.where((a) => a.id == countyId).firstOrNull?.name
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.person, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Showing programs for '),
                  if (groupNames.isNotEmpty)
                    TextSpan(
                      text: groupNames.join(', '),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  if (groupNames.isNotEmpty && countyName != null)
                    const TextSpan(text: ' in '),
                  if (countyName != null)
                    TextSpan(
                      text: countyName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  if (groupNames.isEmpty && countyName == null)
                    const TextSpan(text: 'you'),
                ],
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              userPrefsProvider.reopenOnboarding();
            },
            icon: const Icon(Icons.edit, size: 18),
            tooltip: 'Edit preferences',
            style: IconButton.styleFrom(
              foregroundColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  List<Program> _getPersonalizedPrograms(
    ProgramsProvider programsProvider,
    UserPrefsProvider userPrefsProvider,
  ) {
    final groups = userPrefsProvider.selectedGroups;
    final countyId = userPrefsProvider.selectedCounty;

    var programs = programsProvider.programs;

    // Filter by groups if any selected
    if (groups.isNotEmpty) {
      programs = programs.where((p) => groups.any((g) => p.groups.contains(g))).toList();
    }

    // Filter by county if selected
    if (countyId != null) {
      final county = programsProvider.areas.where((a) => a.id == countyId).firstOrNull;
      if (county != null) {
        // Include programs in the county OR programs that are statewide/nationwide/Bay Area
        programs = programs.where((p) {
          return p.areas.contains(county.name) ||
                 p.areas.contains('Bay Area') ||
                 p.areas.contains('Statewide') ||
                 p.areas.contains('Nationwide');
        }).toList();
      }
    }

    // Sort by recently verified
    programs.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));

    return programs;
  }

  List<Program> _getRecommendedPrograms(
    ProgramsProvider programsProvider,
    UserPrefsProvider userPrefsProvider,
  ) {
    final personalized = _getPersonalizedPrograms(programsProvider, userPrefsProvider);

    // Take top 5 most recently verified as recommendations
    return personalized.take(5).toList();
  }
}
